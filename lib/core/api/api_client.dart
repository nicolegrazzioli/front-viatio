import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../globals.dart';

/// cliente HTTP unificado para a comunicação com o servidor back-end
/// gerencia de forma centralizada os cabeçalhos de autenticação e trata erros de rede/conexão para o modo offline
class ApiClient {
  // define a URL base do servidor buscando de variáveis de ambiente ou usando o padrão localhost
  static String get _effectiveBaseUrl {
    const envUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8081');
    return envUrl.trim().isEmpty ? 'http://localhost:8081' : envUrl;
  }

  // guarda a data e hora do último erro exibido para evitar múltiplos popups repetidos (debounce)
  static DateTime? _lastErrorTime;
  // callback executado globalmente caso a sessão expire (erro 401/403)
  static VoidCallback? onUnauthorized;

  /// exibe um SnackBar (notificação flutuante) de erro na tela de forma controlada (máximo uma a cada 5 segundos)
  static void _showGlobalError(String message) {
    if (_lastErrorTime != null && DateTime.now().difference(_lastErrorTime!).inSeconds < 5) {
      return; 
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
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// constrói os cabeçalhos das requisições HTTP, incluindo o token JWT de autenticação se disponível
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// executa uma requisição HTTP capturando erros de conexão (SocketException) e erros do servidor (500+ ou 401/403)
  static Future<http.Response> _executeRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      // erro interno no servidor
      if (response.statusCode >= 500) {
        _showGlobalError("Servidor indisponível no momento. Operando offline");
        throw Exception("Server Error ${response.statusCode}");
      }
      // sessão expirada ou sem permissão
      if (response.statusCode == 401 || response.statusCode == 403) {
        _showGlobalError("Sessão expirada ou acesso negado");
        onUnauthorized?.call();
        throw Exception("Unauthorized ${response.statusCode}");
      }
      return response;
    } on SocketException catch (_) {
      // dispositivo sem internet (rede inacessível)
      _showGlobalError("Sem conexão. Operando em modo offline");
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// envia requisição HTTP do tipo GET
  static Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.get(Uri.parse('$_effectiveBaseUrl$endpoint'), headers: headers));
  }

  /// envia requisição HTTP do tipo POST (criação de recurso)
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.post(
      Uri.parse('$_effectiveBaseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  /// envia requisição HTTP do tipo PUT (atualização completa)
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.put(
      Uri.parse('$_effectiveBaseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  /// envia requisição HTTP do tipo DELETE (remoção de recurso)
  static Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return _executeRequest(() => http.delete(Uri.parse('$_effectiveBaseUrl$endpoint'), headers: headers));
  }
}
