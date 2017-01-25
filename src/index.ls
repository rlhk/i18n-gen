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
excel-sample-file = './test/data-source/i18n-gen-sample-source.xlsx'
# xlsx-to-json do
#   excel-sample-file
#   (err, output) ->
#     if err
#       console.log err
#     else
#       console.log output
wb = new Excel.Workbook!
wb.xlsx.read-file excel-sample-file
  .then ->
    ws = wb.get-worksheet(1)
    result = range(1, ws.actualRowCount + 1)
      .map((i) -> ws.getRow(i)._cells.splice(0, ws.actualColumnCount).map((c) -> c.value))

    console.log result

compose-yaml-line = (line-items, val-col) ->
  # find 1st non-empty column of the line.
  # which is the key-index of the corresponding yaml line
  key-index = line-items |> find-index -> it != ''
  unless is-type 'Undefined', key-index
    indent-n-key = "#{'  ' * key-index}#{line-items[key-index]}"
    # value = line-items[locales[lang]].replace(/\"/gi,'\\\"')
    value = line-items[val-col]
    if /^[\{\[]/.test(value) # handles value starting with special yaml character
      value = "'#{value}'" # add single quote
    line = "#{indent-n-key}:" + (if value then " #{value}" else '')

data-to-i18n = (raw-rows, dest-folder, format) ->
  [ header, ...rows ] = raw-rows
  locales = {} # e.g. {'en':3, 'zh':4}
  header-items = header
  header-items |> each ->
    if (it not in [ '' '#' 'remark'])
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
                    key-index = line-items |> find-index -> it != ''
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
          msg "Using remote i18n source: #{src}"
          download src
            .then (data) ->
              # assuming data is valid .tsv format
              # transform to array of array
              raw-data-table = data.to-string!split('\r\n')
                                  .map (line) -> line.split('\t')
              data-to-i18n raw-data-table, dest-folder, format
        else
          msg "Using local i18n source: #{src}"

argv = require('minimist')(process.argv.slice(2))
# msg JSON.stringify argv
dest-folder = argv.p || '.'
format = argv.f || 'yml' # 'yml' (default) or 'json'
gen-i18n-from-src argv.s, dest-folder, format
