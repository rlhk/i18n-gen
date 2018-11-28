#!/usr/bin/env node
var ref$, reject, each, keys, map, elemIndex, findIndex, join, isType, compact, concat, range, name, version, fs, download, mkdirp, xlsxToJson, Excel, msg, readSpreadsheet, composeYamlLine, dataToI18n, genI18nFromSrc, argv, destFolder, format, slice$ = [].slice;
ref$ = require('prelude-ls'), reject = ref$.reject, each = ref$.each, keys = ref$.keys, map = ref$.map, elemIndex = ref$.elemIndex, findIndex = ref$.findIndex, join = ref$.join, isType = ref$.isType, compact = ref$.compact, concat = ref$.concat;
range = require('lodash').range;
ref$ = require('../package'), name = ref$.name, version = ref$.version;
fs = require('fs');
download = require('download');
mkdirp = require('mkdirp');
xlsxToJson = require('node-excel-to-json');
Excel = require('exceljs');
msg = function(m){
  return console.log(name + " (" + version + "): " + m);
};
readSpreadsheet = function(filePath){
  var wb;
  wb = new Excel.Workbook();
  return wb.xlsx.readFile(filePath).then(function(){
    var ws, rowCount, colCount, result;
    ws = wb.getWorksheet(1);
    rowCount = ws.actualRowCount;
    colCount = ws.actualColumnCount;
    return result = range(1, rowCount + 1).map(function(i){
      return ws.getRow(i)._cells.splice(0, colCount).map(function(c){
        return c.value;
      });
    });
  })['catch'](function(reason){
    return reason;
  });
};
composeYamlLine = function(lineItems, valCol){
  var keyIndex, indentNKey, value, line;
  keyIndex = findIndex(function(it){
    return it !== null && it !== undefined && it !== '';
  })(
  lineItems);
  if (!isType('Undefined', keyIndex)) {
    indentNKey = repeatString$('  ', keyIndex) + "" + lineItems[keyIndex];
    value = lineItems[valCol];
    if (/^[\{\[]/.test(value)) {
      value = "'" + value + "'";
    }
    return line = (indentNKey + ":") + (value ? " " + value : '');
  }
};
dataToI18n = function(dataRows, destFolder, format){
  var header, rows, locales, headerItems, prefixKeys;
  header = dataRows[0], rows = slice$.call(dataRows, 1);
  locales = {};
  headerItems = header;
  each(function(it){
    if (it !== null && it !== undefined && it !== '' && it !== '#' && it !== 'remark') {
      return locales[it] = elemIndex(it, headerItems);
    }
  })(
  headerItems);
  switch (false) {
  case format !== 'yaml' && format !== 'yml':
    msg("Generating " + format + " files ...");
    return each(function(lang){
      var yamlRows, outFilePath;
      yamlRows = join('\n')(
      map(function(line){
        return composeYamlLine(line, locales[lang]);
      })(
      rows));
      outFilePath = destFolder + "/" + lang + ".i18n.yml";
      msg("\t -> " + outFilePath);
      return fs.writeFileSync(outFilePath, yamlRows, {
        flag: 'w'
      });
    })(
    keys(
    locales));
  case format !== 'json':
    msg("Generating " + format + " files ...");
    prefixKeys = [];
    return each(function(lang){
      var jsonRows, jsonContent, outFilePath;
      jsonRows = join(',\n')(
      reject(function(it){
        return it === '';
      })(
      map(function(line){
        var jsonLine, lineItems, keyIndex, compactedItems, thisKey, thisValue;
        jsonLine = '';
        lineItems = line;
        keyIndex = findIndex(function(it){
          return it !== null && it !== undefined && it !== '';
        })(
        lineItems);
        compactedItems = compact(lineItems);
        if (keyIndex === 0) {
          prefixKeys = [];
        }
        if (compactedItems.length === 1) {
          prefixKeys[keyIndex] = compactedItems[0];
        }
        if (compactedItems.length > 0) {
          thisKey = compactedItems[0];
          thisValue = lineItems[locales[lang]].replace(/\"/gi, '\\"');
          if (compactedItems.length > 1) {
            jsonLine = "  \"" + join('.')(
            concat([prefixKeys, [thisKey]])) + "\" : \"" + thisValue + "\"";
          }
          if (compactedItems.length === 1) {
            jsonLine = "  \"" + join('.')(
            prefixKeys) + "\" : \"" + thisValue + "\"";
          }
        }
        return jsonLine;
      })(
      rows)));
      jsonContent = "{\n" + jsonRows + "\n}";
      outFilePath = destFolder + "/" + lang + ".json";
      msg("\t -> " + outFilePath);
      return fs.writeFileSync(outFilePath, jsonContent, {
        flag: 'w'
      });
    })(
    keys(
    locales));
  default:
    return msg("Unsupported format!");
  }
};
genI18nFromSrc = function(src, destFolder, format){
  src = src || '';
  destFolder = destFolder || '.';
  if (!src.trim()) {
    msg("No data source specified");
    return;
  }
  return mkdirp(destFolder.trim(), function(err){
    if (err) {
      return msg("Error creating destination folder: " + destFolder);
    } else {
      msg("Created destination folder: " + destFolder);
      if (/^http/.test(src.toLowerCase())) {
        msg("Using remote i18n source (assuming valid .TSV): " + src);
        return download(src).then(function(rawData){
          var dataTable;
          dataTable = rawData.toString().split('\r\n').map(function(line){
            return line.split('\t');
          });
          return dataToI18n(dataTable, destFolder, format);
        });
      } else {
        msg("Using local i18n source (assuming valid .XLSX): " + src);
        return readSpreadsheet(src).then(function(result){
          return dataToI18n(result, destFolder, format);
        })['catch'](function(reason){
          return console.log(reason);
        });
      }
    }
  });
};
argv = require('minimist')(process.argv.slice(2));
msg(JSON.stringify(argv));
destFolder = argv.p || '.';
format = argv.f || 'yml';
genI18nFromSrc(argv.s, destFolder, format);
function repeatString$(str, n){
  for (var r = ''; n > 0; (n >>= 1) && (str += str)) if (n & 1) r += str;
  return r;
}
//# sourceMappingURL=data:application/json;base64,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QUFiO0lBQVg7O1dBOEJBLElBQXlCLHFCQUFBOzs7QUFFN0IsY0FBa0IsQ0FBQSxDQUFBLENBQUUsUUFBQSxDQUFBLEdBQUEsRUFBQSxVQUFBLEVBQUEsTUFBQTtFQUNsQixHQUFJLENBQUEsQ0FBQSxDQUFFLEdBQUksQ0FBQSxFQUFBLENBQUc7RUFDYixVQUFZLENBQUEsQ0FBQSxDQUFFLFVBQVksQ0FBQSxFQUFBLENBQUc7RUFDN0IsSUFBRyxDQUFJLEdBQUcsQ0FBQyxJQUFSLENBQVksQ0FBZjtJQUNFLElBQThCLDBCQUFBO0lBQzlCLE1BQUE7O1NBQ0YsT0FDRSxVQUFXLENBQUMsS0FBSSxHQUNoQixRQUFBLENBQUEsR0FBQTtJQUNFLElBQUksR0FBSjthQUNFLElBQUkscUNBQUEsQ0FBQSxDQUFBLENBQXNDLFVBQTFDO0tBQ0Y7TUFDRSxJQUFJLDhCQUFBLENBQUEsQ0FBQSxDQUErQixVQUFuQztNQUNBLElBQUcsT0FBTyxDQUFDLElBQVgsQ0FBZ0IsR0FBRyxDQUFDLFdBQXBCLENBQWlDLENBQWpCLENBQWhCO1FBQ0UsSUFBSSxrREFBQSxDQUFBLENBQUEsQ0FBbUQsR0FBdkQ7ZUFDQSxTQUFTLEdBQUEsQ0FDUCxDQUFDLEtBQUssUUFBQSxDQUFBLE9BQUE7O1VBR0osU0FBVyxDQUFBLENBQUEsQ0FBRSxPQUFRLENBQUMsU0FBUyxDQUFDLENBQUEsTUFBTSxNQUFELENBQ2pCLENBQUMsSUFBSSxRQUFBLENBQUEsSUFBQTttQkFBVSxJQUFJLENBQUMsTUFBTSxJQUFEO1dBQXBCO2lCQUN6QixXQUFhLFdBQVksWUFBYSxNQUF6QjtTQUxUO09BTVY7UUFDRSxJQUFJLGtEQUFBLENBQUEsQ0FBQSxDQUFtRCxHQUF2RDtlQUNBLGdCQUFpQixHQUFBLENBQ2YsQ0FBQyxLQUFLLFFBQUEsQ0FBQSxNQUFBO2lCQUFZLFdBQWEsUUFBUSxZQUFhLE1BQXJCO1NBQXpCLENBQ04sQ0FBQyxPQUFELEVBQU8sUUFBQSxDQUFBLE1BQUE7aUJBQVksT0FBTyxDQUFDLElBQUksTUFBQTtTQUF4Qjs7O0dBbkJmOztBQXFCSixJQUFLLENBQUEsQ0FBQSxDQUFFLFFBQVEsVUFBRCxFQUFhLE9BQU8sQ0FBQyxJQUFJLENBQUMsTUFBTSxDQUFELENBQW5CO0FBQzFCLElBQUksSUFBSSxDQUFDLFVBQVUsSUFBQSxDQUFmO0FBQ0osVUFBWSxDQUFBLENBQUEsQ0FBRSxJQUFJLENBQUMsQ0FBRSxDQUFBLEVBQUEsQ0FBRztBQUN4QixNQUFPLENBQUEsQ0FBQSxDQUFFLElBQUksQ0FBQyxDQUFFLENBQUEsRUFBQSxDQUFHO0FBQ25CLGVBQWtCLElBQUksQ0FBQyxHQUFHLFlBQWEsTUFBckIiLCJzb3VyY2VzQ29udGVudCI6W251bGxdfQ==
