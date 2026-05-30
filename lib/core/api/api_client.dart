import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';

class ApiClient {
  static String get _effectiveBaseUrl {
    const envUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
    return envUrl.trim().isEmpty ? 'http://localhost:8081' : envUrl;
  }

  static DateTime? _lastErrorTime;
  static VoidCallback? onUnauthorized;

  static void _showGlobalError(String message) {
    if (_lastErrorTime != null && DateTime.now().difference(_lastErrorTime!).inSeconds < 5) {
      return; // Evita spam de SnackBars se houverem muitos requests caindo juntos
    }
    _lastErrorTime = DateTime.now();

    final context = scaffoldMessengerKey.currentContext;
    if (context != null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> _executeRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      if (response.statusCode >= 500) {
        _showGlobalError("Servidor indisponível no momento. Operando offline.");
        throw Exception("Server Error ${response.statusCode}");
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        _showGlobalError("Sessão expirada ou acesso negado.");
        onUnauthorized?.call();
        throw Exception("Unauthorized ${response.statusCode}");
      }
      return response;
    } on SocketException catch (_) {
      _showGlobalError("Sem conexão. Operando em modo offline.");
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.get(Uri.parse('$_effectiveBaseUrl$endpoint'), headers: headers));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.post(
      Uri.parse('$_effectiveBaseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.put(
      Uri.parse('$_effectiveBaseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.delete(Uri.parse('$_effectiveBaseUrl$endpoint'), headers: headers));
  }
}
