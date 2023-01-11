import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:openapi_doc/openapi.dart';
import 'string_extensions.dart';

void main(List<String> arguments) async {

  final title = 'title';
  final subTitle = 'subtitle';
  final output = 'output';
  final mergeSchemas = 'merge-schemas';
  final help = 'help';

  final argParser = ArgParser()
    ..addOption(output, abbr: 'o', defaultsTo: 'api-spec.pdf', help: 'Output file.')
    ..addOption(title, defaultsTo: 'API Spec', help: 'Document title.')
    ..addOption(subTitle, help: 'Document sub title.')
    ..addFlag(mergeSchemas, defaultsTo: false, help: 'When multiple API files parsed merge all schemas into one section.')
    ..addFlag(help, abbr: 'h', negatable: false, help: 'Show this help page.');

  ArgResults? args;

  try {
    args = argParser.parse(arguments);
  } catch (e) {
    // args parsing error
  }

  if (args == null || args[help] as bool || args.rest.isEmpty) {
    print('DocBaker 0.1.2');
    print('Usage: docbaker <openapi.json> [<api2.json> <api3.json> ...] [<options>]');
    print('Options:');
    print(argParser.usage);
    return;
  }

  final doc = PdfWriter();
  
  doc.addTitlePage(args[title], subTitle: args.wasParsed(subTitle) ? args[subTitle] : null);

  bool mergeSchemasInOne = args[mergeSchemas] as bool;

  final parser = OpenApiParser(
    doc: doc,
    mergeSchemasInOneSection: mergeSchemasInOne
  );

  for (final filepath in args.rest) {
    final header = path.basenameWithoutExtension(filepath).trim().capitalizeFirst();
    try {
      print('File: $filepath');
      parser.writeToDoc(
        apiJson: await File(filepath).readAsString(),
        header: header
      );
    } on OpenApiException catch (e) {
      print(e.toString());
    } catch (e) {
      print('ERROR: JSON parsing: $e');
    }
  }

  parser.finalizeDoc();

  await File(args[output]).writeAsBytes(await doc.exportAsBytes());
}
