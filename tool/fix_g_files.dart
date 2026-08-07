import 'dart:io';

void main() {
  final originalMap = {
    // DeviceSchema ID
    '3491430514663294464': '3491430514663294648',
    '3491430514663294648': '3491430514663294648',
    // deviceIdentifier Index ID
    '8570335694319597568': '8570335694319598033',
    '8570335694319598033': '8570335694319598033',
    // HistoricValueSchema ID
    '3448619404271591936': '3448619404271591874',
    '3448619404271591874': '3448619404271591874',
    // PredictionSchema ID
    '2351554733480628736': '2351554733480628633',
    '2351554733480628633': '2351554733480628633',
    // AppSettingsSchema ID
    '-5633561779022347264': '-5633561779022347008',
    '-5633561779022347008': '-5633561779022347008',
    // AppRfModelSchema ID
    '-4323257707417377792': '-4323257707417377830',
    '-4323257707417377830': '-4323257707417377830',
    // modelId Index ID
    '-1910745378942518272': '-1910745378942518156',
    '-1910745378942518156': '-1910745378942518156',
  };

  final files = [
    'lib/core/models/device.g.dart',
    'lib/core/models/app_settings.g.dart',
    'lib/core/models/app_rf_model.g.dart',
  ];

  for (final filePath in files) {
    final file = File(filePath);
    if (!file.existsSync()) {
      print('File not found: $filePath');
      continue;
    }

    var content = file.readAsStringSync();
    var changed = false;

    // 1. Convert collection schemas: const XSchema = CollectionSchema(name: ..., id: ...
    final collectionRegex = RegExp(
      r"const\s+(\w+Schema)\s*=\s*CollectionSchema\(\s*name:\s*(r?'.*?')\s*,\s*id:\s*(-?\d+)\s*,",
      multiLine: true,
    );
    if (collectionRegex.hasMatch(content)) {
      content = content.replaceAllMapped(collectionRegex, (match) {
        final schemaName = match[1];
        final nameLiteral = match[2];
        final idStr = match[3]!;
        final originalId = originalMap[idStr] ?? idStr;
        print('Updating collection schema: $schemaName (ID: $originalId) in $filePath');
        changed = true;
        return 'final $schemaName = CollectionSchema(\n  name: $nameLiteral,\n  id: int.parse(\'$originalId\'),';
      });
    }

    // 2. Convert embedded schemas: const XSchema = Schema(name: ..., id: ...
    final embeddedRegex = RegExp(
      r"const\s+(\w+Schema)\s*=\s*Schema\(\s*name:\s*(r?'.*?')\s*,\s*id:\s*(-?\d+)\s*,",
      multiLine: true,
    );
    if (embeddedRegex.hasMatch(content)) {
      content = content.replaceAllMapped(embeddedRegex, (match) {
        final schemaName = match[1];
        final nameLiteral = match[2];
        final idStr = match[3]!;
        final originalId = originalMap[idStr] ?? idStr;
        print('Updating embedded schema: $schemaName (ID: $originalId) in $filePath');
        changed = true;
        return 'final $schemaName = Schema(\n  name: $nameLiteral,\n  id: int.parse(\'$originalId\'),';
      });
    }

    // 3. Convert IndexSchema definitions: r'indexName': IndexSchema(id: ...
    final indexRegex = RegExp(
      r"r\s*('.*?')\s*:\s*IndexSchema\(\s*id:\s*(-?\d+)\s*,",
      multiLine: true,
    );
    if (indexRegex.hasMatch(content)) {
      content = content.replaceAllMapped(indexRegex, (match) {
        final indexName = match[1];
        final idStr = match[2]!;
        final originalId = originalMap[idStr] ?? idStr;
        print('Updating index schema for index $indexName (ID: $originalId) in $filePath');
        changed = true;
        return 'r$indexName: IndexSchema(\n      id: int.parse(\'$originalId\'),';
      });
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Saved updates to $filePath\n');
    } else {
      print('No schema/index ID replacements needed in $filePath\n');
    }
  }
}
