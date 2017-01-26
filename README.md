## A CLI utility for generating i18n translation files (.yml and .json) from a single remote/local source

### Input source formats
- Remote Google Spreadsheet published as .tsv source
- Local .XLSX file

### Output locale definition formats
- YAML (.yml)
- JSON (.json)

### Installation

- As global utility

  `npm install i18n-gen -g`

- Used in NPM project

  `npm install i18n-gen --save-dev`

### Usage

* Command example

  `i18n-gen -p './out' -s https://docs.google.com/spreadsheets/d/1NO-w7UKhIwWCT4VymBnH7xk6VCUKECqB5XNrwt49rUA/pub?output=tsv`

  The following files will be generated (defaults to YAML format if not specified):

  `./out/en.i18n.yml`

  `./out/zh.i18n.yml`

* JSON option

  `i18n-gen -p './out' -f 'json', -s https://docs.google.com/spreadsheets/d/1NO-w7UKhIwWCT4VymBnH7xk6VCUKECqB5XNrwt49rUA/pub?output=tsv`

  Expected output:

  `./out/en.json`

  `./out/zh.json`

### NPM script examples
  ```
  ...
  "scripts": {
    "test:remote": "i18n-gen -p './out' -s https://docs.google.com/spreadsheets/d/1NO-w7UKhIwWCT4VymBnH7xk6VCUKECqB5XNrwt49rUA/pub?output=tsv",
    "test:local": "i18n-gen -p './out' -s ./test/data-source/i18n-gen-sample-source.xlsx",
    "test:local:json": "i18n-gen -p './out' -f 'json' -s ./test/data-source/i18n-gen-sample-source.xlsx",
    "test:remote:json": "i18n-gen -p './out' -f 'json' -s https://docs.google.com/spreadsheets/d/1NO-w7UKhIwWCT4VymBnH7xk6VCUKECqB5XNrwt49rUA/pub?output=tsv",
  }
  ...
  ```
