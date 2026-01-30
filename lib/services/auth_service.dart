import 'api_client.dart';

/// Проверяет, авторизован ли пользователь (есть ли сессия).
/// Делает запрос к защищённому эндпоинту; 200 = авторизован.
Future<bool> checkSession(ApiClient api) async {
  try {
    await api.getTasks();
    return true;
  } on ApiException catch (e) {
    if (e.statusCode == 401) return false;
    rethrow;
  }
}
