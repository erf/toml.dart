// Copyright (c) 2015 Justin Andresen. All rights reserved.
// This software may be modified and distributed under the terms
// of the MIT license. See the LICENSE file for details.

part of toml.decoder;

/// TOML parser definition.
class TomlParserDefinition extends TomlGrammar {
  // -----------------------------------------------------------------
  // Strings values.
  // -----------------------------------------------------------------

  strData(String quotes, {bool literal: false, bool multiLine: false}) =>
      super.strData(quotes, literal: literal, multiLine: multiLine).flatten();

  strParser(String quotes, {Parser esc, bool multiLine: false}) => super
      .strParser(quotes, esc: esc, multiLine: multiLine)
      .pick(2)
      .map((data) => data.join());

  // -----------------------------------------------------------------
  // Escape Sequences.
  // -----------------------------------------------------------------

  escSeq() => super.escSeq().pick(1);

  unicodeEscSeq() => super
      .unicodeEscSeq()
      .pick(1)
      .map((charCode) => String.fromCharCode(int.parse(charCode, radix: 16)));

  compactEscSeq() => super.compactEscSeq().map((String c) {
        if (TomlGrammar.escTable.containsKey(c)) {
          return String.fromCharCode(TomlGrammar.escTable[c]);
        }
        throw InvalidEscapeSequenceError('\\$c');
      });

  multiLineEscSeq() => super.multiLineEscSeq().pick(1);

  whitespaceEscSeq() => super.whitespaceEscSeq().map((_) => '');

  // -----------------------------------------------------------------
  // Integer values.
  // -----------------------------------------------------------------

  integer() => super
      .integer()
      .flatten()
      .map((str) => int.parse(str.replaceAll('_', '')));

  // -----------------------------------------------------------------
  // Float values.
  // -----------------------------------------------------------------

  float() => super
      .float()
      .flatten()
      .map((str) => double.parse(str.replaceAll('_', '')));

  // -----------------------------------------------------------------
  // Boolean values.
  // -----------------------------------------------------------------

  boolean() => super.boolean().map((str) => str == 'true');

  // -----------------------------------------------------------------
  // Datetime values.
  // -----------------------------------------------------------------

  datetime() => super.datetime().flatten().map(DateTime.parse);

  // -----------------------------------------------------------------
  // Arrays.
  // -----------------------------------------------------------------

  arrayOf(v) => super.arrayOf(v).pick(1);

  // -----------------------------------------------------------------
  // Tables.
  // -----------------------------------------------------------------

  table() => super.table().map((List def) => {
        'type': 'table',
        'parent': def[0].sublist(0, def[0].length - 1),
        'name': def[0].last,
        'pairs': def[1]
      });
  tableHeader() => super.tableHeader().pick(1);

  // -----------------------------------------------------------------
  // Array of Tables.
  // -----------------------------------------------------------------

  tableArray() => super.tableArray().map((List def) => {
        'type': 'table-array',
        'parent': def[0].sublist(0, def[0].length - 1),
        'name': def[0].last,
        'pairs': def[1]
      });
  tableArrayHeader() => super.tableArrayHeader().pick(1);

  // -----------------------------------------------------------------
  // Inline Tables.
  // -----------------------------------------------------------------

  inlineTable() => super.inlineTable().pick(1).map((List pairs) {
        var map = {};
        pairs.forEach((Map pair) {
          map[pair['key']] = pair['value'];
        });
        return map;
      });

  // -----------------------------------------------------------------
  // Keys.
  // -----------------------------------------------------------------

  bareKey() => super.bareKey().flatten();

  // -----------------------------------------------------------------
  // Key/value pairs.
  // -----------------------------------------------------------------

  keyValuePair() => super
      .keyValuePair()
      .permute([0, 2]).map((List pair) => {'key': pair[0], 'value': pair[1]});

  // -----------------------------------------------------------------
  // Document.
  // -----------------------------------------------------------------

  document() => super.document().map((List content) {
        var doc = {};

        // Set of names of defined keys and tables.
        var defined = Set();

        // Add a name to the set above.
        void define(String name) {
          if (defined.contains(name)) throw RedefinitionError(name);
          defined.add(name);
        }

        Function addPairsTo(Map table, [String tableName]) => (Map pair) {
              var name =
                  tableName == null ? pair['key'] : '$tableName.${pair['key']}';
              define(name);

              if (table.containsKey(pair['key'])) throw RedefinitionError(name);
              table[pair['key']] = pair['value'];
            };

        // add top level key/value pairs
        content[1].forEach(addPairsTo(doc));

        // Iterate over table definitions.
        content[2].forEach((Map def) {
          // Find parent of the new table.
          var parent = doc;
          var name = [];
          def['parent'].forEach((String key) {
            parent = parent.putIfAbsent(key, () => {});
            if (parent is List) {
              key = '$key[${parent.length - 1}]';
              parent = parent.last;
            }
            name.add(key);
            if (parent is! Map) throw NotATableError(name.join('.'));
          });
          name.add(def['name']);
          name = name.join('.');

          // Create the table.
          var tbl;

          // Array of Tables.
          if (def['type'] == 'table-array') {
            var arr = parent.putIfAbsent(def['name'], () {
              // Define array.
              define(name);
              return [];
            });

            // Overwrite previous table.
            if (arr is Map) throw RedefinitionError(name);

            var i = arr.length;
            arr.add(tbl = {});
            name = '$name[$i]'; // Tables in arrays are qualified by index.
          } else {
            tbl = parent.putIfAbsent(def['name'], () => {});
          }

          // Add key/value pairs.
          define(name);
          def['pairs'].forEach(addPairsTo(tbl, name));
        });

        unmodifiable(toml) {
          if (toml is Map) {
            return UnmodifiableMapView(
                Map.fromIterables(toml.keys, toml.values.map(unmodifiable)));
          }
          if (toml is List) {
            return UnmodifiableListView(toml.map(unmodifiable));
          }

          return toml;
        }

        return unmodifiable(doc);
      });
}

/// TOML parser.
class TomlParser extends GrammarParser {
  TomlParser() : super(TomlParserDefinition());
}
