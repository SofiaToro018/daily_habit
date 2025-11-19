import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

/// Excepciones personalizadas para errores de API
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (código: $statusCode)';
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message);
}

class TimeoutException extends ApiException {
  TimeoutException() : super('La solicitud tardó demasiado tiempo');
}

/// Cliente HTTP para comunicación con la API
///
/// Gestiona todas las peticiones HTTP con manejo de errores,
/// timeouts y headers apropiados.
class ApiClient {
  final http.Client _client;
  final String baseUrl;

  ApiClient({http.Client? client, this.baseUrl = ApiConfig.baseUrl})
    : _client = client ?? http.Client();

  /// Headers comunes para todas las peticiones
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Realiza una petición GET
  Future<dynamic> get(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Sin conexión a Internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión con el servidor');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException();
      }
      throw ApiException('Error inesperado: $e');
    }
  }

  /// Realiza una petición POST
  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = Map<String, String>.from(_headers);

      if (idempotencyKey != null) {
        headers['Idempotency-Key'] = idempotencyKey;
      }

      final response = await _client
          .post(uri, headers: headers, body: json.encode(body))
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Sin conexión a Internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión con el servidor');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException();
      }
      throw ApiException('Error inesperado: $e');
    }
  }

  /// Realiza una petición PUT
  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? idempotencyKey,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = Map<String, String>.from(_headers);

      if (idempotencyKey != null) {
        headers['Idempotency-Key'] = idempotencyKey;
      }

      final response = await _client
          .put(uri, headers: headers, body: json.encode(body))
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Sin conexión a Internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión con el servidor');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException();
      }
      throw ApiException('Error inesperado: $e');
    }
  }

  /// Realiza una petición DELETE
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .delete(uri, headers: _headers)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('Sin conexión a Internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión con el servidor');
    } on Exception catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw TimeoutException();
      }
      throw ApiException('Error inesperado: $e');
    }
  }

  /// Maneja la respuesta HTTP y lanza excepciones apropiadas
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    // Manejo de errores HTTP
    String errorMessage = 'Error del servidor';

    try {
      final errorBody = json.decode(response.body);
      errorMessage = errorBody['message'] ?? errorBody['error'] ?? errorMessage;
    } catch (_) {
      // Si no se puede parsear el error, usar mensaje por defecto
    }

    switch (response.statusCode) {
      case 400:
        throw ApiException('Solicitud inválida: $errorMessage', 400);
      case 401:
        throw ApiException('No autorizado', 401);
      case 403:
        throw ApiException('Acceso prohibido', 403);
      case 404:
        throw ApiException('Recurso no encontrado', 404);
      case 409:
        throw ApiException('Conflicto: $errorMessage', 409);
      case 500:
        throw ApiException('Error interno del servidor', 500);
      case 502:
        throw ApiException('Bad Gateway', 502);
      case 503:
        throw ApiException('Servicio no disponible', 503);
      default:
        throw ApiException(
          'Error HTTP ${response.statusCode}: $errorMessage',
          response.statusCode,
        );
    }
  }

  /// Cierra el cliente HTTP
  void close() {
    _client.close();
  }
}
