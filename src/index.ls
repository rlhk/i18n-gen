``#!/usr/bin/env node``

{ reject, each, keys, map, elem-index, find-index, join, is-type, compact, concat } = require 'prelude-ls'
if process.argv.length > 2
  src-tsv = process.argv.2

version = '0.3.62'
msg = (m) -> console.log "i18n-gen (#{version}): #{m}"
fs = require 'fs'
download = require 'download'
download-status = require 'download-status'
mkdirp = require 'mkdirp'

tsv-to-i18n-yamls = (raw-text, dest-folder) ->
  [ header, ...lines ] = raw-text.toString!split '\r\n'
  locales = {} # e.g. {'en':3, 'zh':4}
  header-items = header.split '\t'
  header-items |> each ->
    if (it not in [ '' '#' 'remark'])
      locales[it] = elem-index it, header-items

  msg "Generating .yml files ..."

  locales |> keys |> each (lang)->
    yaml-lines = lines
              |> map (line)->
                  line-items = line.split '\t'
                  # find 1st non-empty column of the line.
                  # which is the key-index of the corresponding yaml line
                  key-index = line-items |> find-index -> it != ''
                  unless is-type 'Undefined', key-index
                    indent-n-key = "#{'  ' * key-index}#{line-items[key-index]}"
                    value = line-items[locales[lang]].replace(/\"/gi,'\\\"')
                    line = "#{indent-n-key}:" + (if value then " \"#{value}\"" else '')
              |> join '\n'
    output-file = "#{dest-folder}/#{lang}.i18n.yml"
    msg "\t -> #{output-file}"
    fs .writeFileSync output-file, yaml-lines, { flag: 'w'}

  # msg "Generating .json files ..."
  # prefix-keys = []
  # locales |> keys |> each (lang)->
  #   json-lines = lines
  #             |> map (line)->
  #                 json-line = ''
  #                 line-items = line.split '\t'
  #                 # find 1st non-empty column of the line.
  #                 # which is the key-index of the corresponding yaml line
  #                 key-index = line-items |> find-index -> it != ''
  #                 compacted-items = compact(line-items)
  #                 if key-index == 0 # top level key
  #                   prefix-keys := [] # reset prefix-keys array
  #                 if compacted-items.length == 1 # line with only one prefix-key
  #                   prefix-keys[key-index] = compacted-items[0] # replace prefix-keys
  #                 if compacted-items.length > 1 # line containing bottom level key and lang value
  #                   this-key = compacted-items[0]
  #                   this-value = line-items[locales[lang]].replace(/\"/gi,'\\\"') # escape double quote '"'
  #                   json-line := "  \"#{( concat [ prefix-keys, [ this-key ] ] |> join '.' )}\" : \"#{this-value}\""
  #                 return json-line
  #             |> reject -> it == '' # remove empty lines
  #             |> join ',\n'
  #   json-content = "{\n#{json-lines}\n}"
  #   output-file = "#{dest-folder}/#{lang}.json"
  #   msg "\t -> #{output-file}"
  #   fs .write-file-sync output-file, json-content, { flag: 'w'}

gen-i18n-yamls-from-url = (url, dest-folder)->
  url = url || ''
  dest-folder = dest-folder || '.'
  # make sure dest-folder exists
  mkdirp do
    dest-folder
    (err)->
      if (err)
        msg "Error creating destination folder: #{dest-folder}"
      else
        msg "Created destination folder: #{dest-folder}"
        msg "Getting .tsv from: #{url}. Target folder: #{dest-folder}"
        download url
          .then (data)->
            tsv-to-i18n-yamls(data.toString!, dest-folder)

argv = require('minimist')(process.argv.slice(2))
msg JSON.stringify argv
dest-folder = argv.p || '.'
gen-i18n-yamls-from-url argv.s, dest-folder
