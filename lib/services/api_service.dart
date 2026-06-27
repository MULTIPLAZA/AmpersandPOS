import 'dart:convert';
import 'dart:io';

import '../config.dart';

class ApiService {
  static final ApiService instance = ApiService._();

  ApiService._();

  /// Executes a stored procedure call against the APISQL endpoint.
  ///
  /// [sp] is the raw SQL/SP string to send (e.g. "EXEC SPListarProductos ...").
  ///
  /// Returns a [List<dynamic>] where each element is a recordset
  /// (a list of row maps). Access the first row of the first recordset
  /// as `response[0][0]`.
  ///
  /// Throws an [Exception] if:
  /// - The server returns an error row (`Error == -1`)
  /// - A network or TLS error occurs
  /// - The response cannot be parsed as JSON
  Future<List<dynamic>> post(String sp) async {
    final HttpClient client = HttpClient()
      // Accept self-signed / untrusted certificates (internal server)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true
      ..connectionTimeout = const Duration(seconds: 15);

    HttpClientRequest request;
    try {
      request = await client.postUrl(Uri.parse(kApiUrl));
    } catch (e) {
      client.close();
      throw Exception('No se pudo conectar con el servidor: $e');
    }

    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json',
    );
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $kApiBearer',
    );

    final String body = jsonEncode({'sp': sp});
    request.add(utf8.encode(body));

    HttpClientResponse response;
    try {
      response = await request.close().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          client.close();
          throw Exception('Tiempo de espera agotado al conectar con el servidor');
        },
      );
    } catch (e) {
      client.close();
      if (e is Exception) rethrow;
      throw Exception('Error de red: $e');
    }

    final String responseBody = await utf8.decodeStream(response);
    client.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error HTTP ${response.statusCode}: $responseBody',
      );
    }

    dynamic parsed;
    try {
      parsed = jsonDecode(responseBody);
    } catch (e) {
      throw Exception('Respuesta inválida del servidor (no es JSON): $e');
    }

    // Normalize to List<dynamic>
    final List<dynamic> result = parsed is List ? parsed : [parsed];

    // Check for application-level error in first row of first recordset
    if (result.isNotEmpty) {
      final dynamic firstRecordset = result[0];
      if (firstRecordset is List && firstRecordset.isNotEmpty) {
        final dynamic firstRow = firstRecordset[0];
        if (firstRow is Map && firstRow.containsKey('Error')) {
          final dynamic errorCode = firstRow['Error'];
          if (errorCode == -1 ||
              errorCode == '-1' ||
              (errorCode is String && errorCode.trim() == '-1')) {
            final String mensaje =
                (firstRow['Mensaje'] as String?) ?? 'Error en servidor';
            throw Exception(mensaje);
          }
        }
      }
    }

    return result;
  }
}
