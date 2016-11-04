## A command line utility to generate i18n translation files from .tsv source to .yml and/or .json format

Google spreadsheet is probably the simplest way for small team to maintain i18n translation definitions.

## Usage

  `npm install i18n-gen -g`
  
  `i18n-gen -p './out' -s https://docs.google.com/spreadsheets/d/1NO-w7UKhIwWCT4VymBnH7xk6VCUKECqB5XNrwt49rUA/pub?output=tsv`

  Then you should have the following files generated:
  `./out/en.i18n.yml`
  `./out/zh.i18n.yml`
  `./out/en.json`
  `./out/zh.json`
