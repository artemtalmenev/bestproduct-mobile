import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import '../models/task.dart';

/// HTTP-клиент к бэкенду с поддержкой cookie (сессия после логина).
class ApiClient {
  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? kApiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    _initCookieJar();
  }

  late final Dio _dio;
  bool _cookieJarInitialized = false;

  Future<void> _initCookieJar() async {
    if (_cookieJarInitialized) return;
    // dio_cookie_manager не поддерживает Web — в браузере cookie обрабатываются автоматически
    if (kIsWeb) {
      _cookieJarInitialized = true;
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final jar = PersistCookieJar(storage: FileStorage('${dir.path}/.cookies'));
      _dio.interceptors.add(CookieManager(jar));
    } catch (_) {
      _dio.interceptors.add(CookieManager(CookieJar()));
    }
    _cookieJarInitialized = true;
  }

  Dio get dio => _dio;

  Future<void> ensureCookieJar() => _initCookieJar();

  // ——— Health ———
  Future<Map<String, dynamic>> health() async {
    final r = await _dio.get<Map<String, dynamic>>('/api/health');
    return r.data ?? {};
  }

  // ——— Auth ———
  Future<void> login(String email, String password) async {
    await ensureCookieJar();
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    if (r.data?['ok'] != true) throw ApiException('LOGIN_FAILED', r.statusCode);
  }

  Future<Map<String, dynamic>> register(String email, String password) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );
    final data = r.data ?? {};
    if (r.statusCode != 200) {
      throw ApiException(data['error'] as String? ?? 'REGISTER_FAILED', r.statusCode);
    }
    return data;
  }

  Future<void> logout() async {
    await _dio.post('/api/auth/logout');
  }

  // ——— Tasks ———
  Future<List<Task>> getTasks({int? month, int? year}) async {
    await ensureCookieJar();
    final q = <String, dynamic>{};
    if (month != null) q['month'] = month;
    if (year != null) q['year'] = year;
    final r = await _dio.get<Map<String, dynamic>>(
      '/api/tasks',
      queryParameters: q.isEmpty ? null : q,
    );
    final list = r.data?['tasks'] as List<dynamic>? ?? [];
    return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask({
    required String title,
    String? description,
    String? dueAt,
  }) async {
    await ensureCookieJar();
    final data = <String, dynamic>{'title': title};
    if (description != null) data['description'] = description;
    if (dueAt != null) data['dueAt'] = dueAt;
    final r = await _dio.post<Map<String, dynamic>>('/api/tasks', data: data);
    if (r.data == null) throw ApiException('INVALID_RESPONSE', r.statusCode);
    return Task.fromJson(r.data!);
  }

  Future<Task> updateTask(
    String id, {
    String? title,
    String? description,
    String? dueAt,
    String? status,
  }) async {
    await ensureCookieJar();
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (dueAt != null) data['dueAt'] = dueAt;
    if (status != null) data['status'] = status;
    final r = await _dio.patch<Map<String, dynamic>>('/api/tasks/$id', data: data);
    if (r.data == null) throw ApiException('INVALID_RESPONSE', r.statusCode);
    return Task.fromJson(r.data!);
  }

  Future<void> deleteTask(String id) async {
    await ensureCookieJar();
    await _dio.delete('/api/tasks/$id');
  }

  // ——— AI Requests ———
  Future<List<Map<String, dynamic>>> getRequests() async {
    await ensureCookieJar();
    final r = await _dio.get<Map<String, dynamic>>('/api/requests');
    final list = r.data?['requests'] as List<dynamic>? ?? [];
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Отправить запрос к AI. Ответ приходит асинхронно (response может быть null).
  Future<Map<String, dynamic>> createRequest(String text) async {
    await ensureCookieJar();
    final r = await _dio.post<Map<String, dynamic>>('/api/requests', data: {'text': text.trim()});
    if (r.data == null) throw ApiException('INVALID_RESPONSE', r.statusCode);
    return r.data!;
  }
}

class ApiException implements Exception {
  ApiException(this.code, [this.statusCode]);
  final String code;
  final int? statusCode;
  @override
  String toString() => 'ApiException($code, $statusCode)';
}
