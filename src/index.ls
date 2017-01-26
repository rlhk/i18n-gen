``#!/usr/bin/env node``

{ reject, each, keys, map, elem-index, find-index, join, is-type, compact, concat } = require 'prelude-ls'
{ range } = require 'lodash'
{ name, version } = require '../package'
fs = require 'fs'
download = require 'download'
mkdirp = require 'mkdirp'
xlsx-to-json = require 'node-excel-to-json'
Excel = require 'exceljs'

msg = (m) -> console.log "#{name} (#{version}): #{m}"
# excel-sample-file = './test/data-source/i18n-gen-sample-source.xlsx'

read-spreadsheet = (file-path) ->
  wb = new Excel.Workbook!
  wb.xlsx.read-file file-path
    .then ->
      ws = wb.get-worksheet(1)
      row-count = ws.actual-row-count
      col-count = ws.actual-column-count
      # console.log "actualRowCount / actualColumnCount: #{row-count} / #{col-count}"
      result = range(1, row-count + 1)
        .map((i) -> ws.get-row(i)._cells.splice(0, col-count).map((c) -> c.value))
      # console.log result
    .catch (reason) -> reason

compose-yaml-line = (line-items, val-col) ->
  # console.log "line-items: #{JSON.stringify(line-items)}"
  # find 1st non-empty column of the line.
  # which is the key-index of the corresponding yaml line
  key-index = line-items |> find-index -> it not in [ null, undefined, '' ]
  unless is-type 'Undefined', key-index
    indent-n-key = "#{'  ' * key-index}#{line-items[key-index]}"
    # value = line-items[locales[lang]].replace(/\"/gi,'\\\"')
    value = line-items[val-col]
    if /^[\{\[]/.test(value) # handles value starting with special yaml character
      value = "'#{value}'" # add single quote
    line = "#{indent-n-key}:" + (if value then " #{value}" else '')

data-to-i18n = (data-rows, dest-folder, format) ->
  # console.log data-rows
  [ header, ...rows ] = data-rows
  locales = {} # e.g. {'en':3, 'zh':4}
  # header-items = header.split '\t'
  header-items = header
  header-items |> each ->
    if (it not in [ null, undefined, '' '#' 'remark'])
      locales[it] = elem-index it, header-items

  switch
  case format in ['yaml', 'yml']
    msg "Generating #{format} files ..."
    locales |> keys |> each (lang) ->
      yaml-rows = rows
                |> map (line) ->
                    compose-yaml-line line, locales[lang]
                |> join '\n'
      out-file-path = "#{dest-folder}/#{lang}.i18n.yml"
      msg "\t -> #{out-file-path}"
      fs .write-file-sync out-file-path, yaml-rows, { flag: 'w'}

  case format in ['json']
    msg "Generating #{format} files ..."
    prefix-keys = []
    locales |> keys |> each (lang) ->
      json-rows = rows
                |> map (line) ->
                    json-line = ''
                    line-items = line
                    # find 1st non-empty column of the line.
                    # which is the key-index of the corresponding yaml line
                    key-index = line-items |> find-index -> it not in [ null, undefined, '' ]
                    compacted-items = compact(line-items)
                    if key-index == 0 # top level key
                      prefix-keys := [] # reset prefix-keys array
                    if compacted-items.length == 1 # line with only one prefix-key
                      prefix-keys[key-index] = compacted-items[0] # replace prefix-keys
                    if compacted-items.length > 1 # line containing leave level key and lang value
                      this-key = compacted-items[0]
                      this-value = line-items[locales[lang]].replace(/\"/gi,'\\\"') # escape double quote '"'
                      json-line := "  \"#{( concat [ prefix-keys, [ this-key ] ] |> join '.' )}\" : \"#{this-value}\""
                    return json-line
                |> reject -> it == '' # remove empty rows
                |> join ',\n'
      json-content = "{\n#{json-rows}\n}"
      out-file-path = "#{dest-folder}/#{lang}.json"
      msg "\t -> #{out-file-path}"
      fs .write-file-sync out-file-path, json-content, { flag: 'w'}

  default
    msg "Unsupported format!"

gen-i18n-from-src = (src, dest-folder, format) ->
  src = src || ''
  dest-folder = dest-folder || '.'
  if not src.trim!
    msg "No data source specified"
    return
  mkdirp do # ensure dest-folder existence
    dest-folder.trim!
    (err) ->
      if (err)
        msg "Error creating destination folder: #{dest-folder}"
      else
        msg "Created destination folder: #{dest-folder}"
        if /^http/.test src.to-lower-case!
          msg "Using remote i18n source (assuming valid .TSV): #{src}"
          download src
            .then (raw-data) ->
              # assuming raw-data is valid .tsv format
              # transform to array of array
              data-table = raw-data.to-string!split('\r\n')
                                  .map (line) -> line.split('\t')
              data-to-i18n data-table, dest-folder, format
        else
          msg "Using local i18n source (assuming valid .XLSX): #{src}"
          read-spreadsheet src
            .then (result) -> data-to-i18n result, dest-folder, format
            .catch (reason) -> console.log reason

argv = require('minimist')(process.argv.slice(2))
msg JSON.stringify argv
dest-folder = argv.p || '.'
format = argv.f || 'yml' # 'yml' (default) or 'json'
gen-i18n-from-src argv.s, dest-folder, format
