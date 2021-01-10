import 'package:flutter/material.dart';

abstract class ApiEvents {}

class FetchingApiKey extends ApiEvents {}

class NoApiKey extends ApiEvents {}

class RetrievedApiKey extends ApiEvents {
  final String apiToken;
  RetrievedApiKey({@required this.apiToken});
}

class ApiKeyError extends ApiEvents {
   final Error apiError;
   ApiKeyError({@required this.apiError})
}