import 'dart:core';

class OpenApiException implements Exception {
  String cause;
  OpenApiException(this.cause);

  @override
  String toString() => cause;
}
