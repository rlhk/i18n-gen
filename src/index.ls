``#!/usr/bin/env node``

{ reject, each, keys, map, elem-index, find-index, join, is-type, compact, concat } = require('prelude-ls')
if process.argv.length > 2
  src-tsv = process.argv.2

msg = (m) -> console.log "i18n-gen: #{m}"

i18nTSVHandler = (source-text) ->

  # Assuming first line is 'header' and starts with '#'
  [ header, ...lines ] = source-text.split '\r\n'
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
                    line = "#{indent-n-key}: #{line-items[locales[lang]]}"
              |> join '\n'
    output-file = "#{lang}.i18n.yml"
    msg "\t -> #{output-file}"
    fs .writeFileSync output-file, yaml-lines, { flag: 'w'}

  msg "Generating .json files ..."
  prefix-keys = []
  locales |> keys |> each (lang)->
    json-lines = lines
              |> map (line)->
                  json-line = ''
                  line-items = line.split '\t'
                  # find 1st non-empty column of the line.
                  # which is the key-index of the corresponding yaml line
                  key-index = line-items |> find-index -> it != ''
                  compacted-items = compact(line-items)
                  if key-index == 0 # top level key
                    prefix-keys := [] # reset prefix-keys array
                  if compacted-items.length == 1 # line with only one prefix-key
                    prefix-keys[key-index] = compacted-items[0] # replace prefix-keys
                  if compacted-items.length > 1 # line containing bottom level key and lang value
                    this-key = compacted-items[0]
                    this-value = line-items[locales[lang]].replace(/\"/gi,'\\\"') # escape double quote '"'
                    json-line := "  \"#{( concat [ prefix-keys, [ this-key ] ] |> join '.' )}\" : \"#{this-value}\""
                  return json-line
              |> reject -> it == '' # remove empty lines
              |> join ',\n'
    json-content = "{\n#{json-lines}\n}"
    output-file = "#{lang}.json"
    msg "\t -> #{output-file}"
    fs .writeFileSync output-file, json-content, { flag: 'w'}

console.log "processing: #{src-tsv}"
fs = require 'fs'

fs.readFile do
  src-tsv
  'utf-8'
  (err, data) ->
    i18nTSVHandler(data)