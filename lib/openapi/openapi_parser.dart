import 'dart:convert';
import 'package:openapi_doc/pdf/pdf_writer.dart';
import 'openapi_exception.dart';

typedef _Json = Map<String, dynamic>;

class _JsonLeaf {
  String name;
  dynamic spec;
  _JsonLeaf(this.name, this.spec);
}

class _SchemaRef {
  String text;
  String schemaName;
  bool isArray = false;
  String? anchor;

  _SchemaRef(this.text, this.schemaName, {this.anchor, this.isArray = false});
  _SchemaRef.undefined() : text = 'undefined', schemaName = 'undefined';

  bool get isUndefined => text == 'undefined';

  @override
  String toString() {
    return '{ text: "$text", schemaName: "$schemaName", anchor: "$anchor" }';
  }
}

class OpenApiParser {

  final PdfWriter doc;
  final int firstHeaderLevel;

  late _Json _spec; // open api spec being processed
  late String? _topHeader;

  // when multiple API specs parsed into the same doc - merge all schemas into one section
  final bool mergeSchemasInOneSection;
  final _Json _schemas = {};

  OpenApiParser({
    required this.doc,
    this.firstHeaderLevel = 0,
    this.mergeSchemasInOneSection = false
  });

  void writeToDoc({required String apiJson, String? header}) {

    _spec = jsonDecode(apiJson);

    String? openapiVer = _spec['openapi'];
    
    if (openapiVer == null) {
      throw OpenApiException('Invalid OpenAPI specification.');
    }
    
    if (openapiVer.startsWith('1') || openapiVer.startsWith('2')) {
      throw OpenApiException('Invalid OpenAPI version: $openapiVer, required 3.0.0+.');
    }

    _topHeader = header;
    doc.topRightText = header;

    if (header != null) {
      doc.addHeader(firstHeaderLevel, header);
    }

    _Json paths = _spec['paths'];

    if (paths.isNotEmpty) {
      print('Endpoints:');
      for (final path in paths.entries) {
        _writePath(path.key, path.value);
      }
    }

    Map<String, dynamic> schemas = _spec['components']['schemas'];

    if (schemas.entries.isNotEmpty) {

      if (mergeSchemasInOneSection) {
        _saveSchemasToParseLater(schemas);
      } else {
        doc.addHeader(firstHeaderLevel + 1, 'Schemas');
        _writeSchemas(schemas);
      }
    }
    
    doc.flush();
  }

  void finalizeDoc() {

    doc.topRightText = 'Schemas';

    if (mergeSchemasInOneSection && _schemas.isNotEmpty) {
      doc.addHeader(firstHeaderLevel, 'Schemas');
      _writeSchemas(_schemas);
    }
    doc.flush();
  }

  void _writePath(String path, _Json pathSpec) {
    for (final method in pathSpec.entries) {
      String endpoint = '${method.key.toUpperCase()} $path';
      print(endpoint);
      doc.addHeader(firstHeaderLevel + 1, endpoint);
      _writeMethod(method.value);
    }
  }

  void _writeMethod(_Json methodSpec) {
    if (methodSpec['parameters'] != null && methodSpec['parameters'].length > 0) {
      
      doc.addSubHeader('Request Parameters:');

      // NOTE: for some reason there are duplicated parameters - remove duplicates

      List<dynamic> uniqParams = methodSpec['parameters'];

      for (_Json param in uniqParams) {
        _writeParameter(param);
      }
    }

    if (methodSpec['requestBody'] != null) {
      doc.addSubHeader('Request Body:');
      _writeBody(methodSpec['requestBody']);
    }

    _Json? responses = methodSpec['responses'];

    if (responses != null) {
      for (final resp in responses.entries) {
        doc.addSubHeader('Response ${resp.key}:');
        _writeBody(resp.value);
      }
    }
  }

  void _writeBody(_Json bodySpec) {

    if (bodySpec['description'] != null && bodySpec['description'] != '') {
      doc.addComment(bodySpec['description']);
    }

    _Json? contentSpec = bodySpec['content'];
    bool emptyBody = true;

    if (contentSpec != null) {
      _JsonLeaf? content = _getFirstOf(contentSpec, ['application/json', 'multipart/form-data']);

      if (content != null) {
        _Json? schemaRef = content.spec['schema'];
        if (schemaRef != null) {
          final schema = _parseSchemaRef(schemaRef);
          _Json? schemaSpec = _spec['components']?['schemas']?[schema.schemaName];
          if (schemaSpec != null) {
            _writeSchema(schemaSpec, name: schema.text);
          } else {
            doc.addPara('Schema: ${schema.text} (no definition).');
          }
          emptyBody = false;
        }
      }
    }
    if (emptyBody) {
      doc.addPara('Empty body.');
    }
  }

  void _saveSchemasToParseLater(_Json schemas) {
    for (final schema in schemas.entries) {
      if (!_schemas.containsKey(schema.key)) {
        _schemas[schema.key] = schema.value;
      } else {
        print('!Duplicated schema: ${schema.key}');
      }
    }
  }
  
  void _writeSchemas(_Json schemas) {
    print('Schemas:');
    for (final schema in schemas.entries) {
      print(schema.key);
      doc.addHeader(firstHeaderLevel + 2, schema.key, anchor: _schemaAnchor(schema.key));
      _writeSchema(schema.value);
    }
  }

  void _writeSchema(_Json schemaSpec, {String? name}) {

    doc.addSchemaType(name ?? schemaSpec['type']);

    if (schemaSpec['properties'] != null) {
      doc.addPara('{');

      _Json properties = schemaSpec['properties'];
      List<dynamic>? required = schemaSpec['required'];

      for (final prop in properties.entries) {
        final typeRef = _parseSchemaRef(prop.value);

        _writeVariable(
          name: prop.key, 
          typeRef: typeRef,
          description: prop.value['description'],
          required: required?.contains(prop.key)
        );
      }
      doc.addPara('}');
    }
    else if (schemaSpec['enum'] != null) {
      doc.addPara('Values:');
      List<String> values = (schemaSpec['enum'] as List<dynamic>).map((v) => v as String).toList();
      doc.addEnumValues(values);
    }
  }

  String _schemaNameByRef(String ref) {
    String refPath = '#/components/schemas/';
    int start = ref.indexOf(refPath);
    if (start >= 0) {
      return ref.substring(ref.indexOf(refPath) + refPath.length);
    }
    return ref;
  }

  bool _schemaDefinitionExists(String name) {
    return _spec['components']?['schemas']?[name] != null;
  }

  String _schemaAnchor(String schemaName) {
    return mergeSchemasInOneSection ? 'schemas: $schemaName' : '$_topHeader: $schemaName';
  }

  _SchemaRef _parseSchemaRef(_Json schemaRef) {
    if (schemaRef['type'] != null) {
      if (schemaRef['type'] == 'array' && schemaRef['items'] != null) {
        final typeRef = _parseSchemaRef(schemaRef['items']);
        return _SchemaRef('Array<${typeRef.text}>', typeRef.schemaName, anchor: typeRef.anchor, isArray: true);
      } else {
        return _SchemaRef(schemaRef['type'], schemaRef['type']);
      }
    } else if (schemaRef['\$ref'] != null) {
      final schemaName = _schemaNameByRef(schemaRef['\$ref']);
      final anchor = _schemaDefinitionExists(schemaName) ? _schemaAnchor(schemaName) : null;
      return _SchemaRef(schemaName, schemaName, anchor: anchor);
    }
    return _SchemaRef.undefined();
  }

  void _writeParameter(_Json paramSpec) {
    if (paramSpec['name'] != null && paramSpec['name'] != '') {  

      _SchemaRef? typeRef;

      if (paramSpec['schema'] != null) {
        typeRef = _parseSchemaRef(paramSpec['schema']);
      }

      if (typeRef == null || typeRef.isUndefined) {
        final leaf = _getFirstOf(paramSpec, ['anyOf', 'allOf', 'oneOf']);
        // TODO: parse entire array of possible schemas
        if (leaf?.spec[0] != null) {
          typeRef = _parseSchemaRef(leaf?.spec[0]!);
        }
      }
      
      _writeVariable(
        name: paramSpec['name'],
        typeRef: typeRef,
        description: paramSpec['description'],
        required: paramSpec['required']
      );
    }
  }

  _JsonLeaf? _getFirstOf(_Json spec, List<String> children) {
    for (final child in children) {
      if (spec[child] != null) {
        return _JsonLeaf(child, spec[child]);
      }
    }
    return null;
  }

  void _writeVariable({required String name, _SchemaRef? typeRef, String? description, bool? required}) {
    doc.addVariable(
      name: '$name${(required ?? true) ? '':'?'}', 
      type: typeRef?.text,
      description: description, 
      typeAnchor: typeRef?.anchor);
  }
}
