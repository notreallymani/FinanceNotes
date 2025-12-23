import 'package:flutter/foundation.dart';

class Env {
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: kReleaseMode ? 'prod' : 'dev',
  );

  static const String devBase = String.fromEnvironment(
    'API_BASE_URL_DEV',
    defaultValue: 'http://10.118.84.136:5001',
  );

  static const String prodBase = String.fromEnvironment(
    'API_BASE_URL_PROD',
    defaultValue: 'https://api.example.com',
  );

  static String get apiBaseUrl => env == 'prod' ? prodBase : devBase;

  static const String watiBaseDev = String.fromEnvironment(
    'WATI_BASE_URL_DEV',
    defaultValue: 'https://live-mt-server.wati.io/1025114/api/v1',
  );

  static const String watiBaseProd = String.fromEnvironment(
    'WATI_BASE_URL_PROD',
    defaultValue: 'https://live-mt-server.wati.io/1025114/api/v1',
  );

  static const String watiTokenDev = String.fromEnvironment(
    'WATI_API_TOKEN_DEV',
    defaultValue: '',
  );

  static const String watiTokenProd = String.fromEnvironment(
    'WATI_API_TOKEN_PROD',
    defaultValue: '',
  );

  static String get watiBaseUrl => env == 'prod' ? watiBaseProd : watiBaseDev;
  static String get watiToken => env == 'prod' ? watiTokenProd : watiTokenDev;
  static const bool useWati = bool.fromEnvironment('USE_WATI', defaultValue: false);
}

