/// Сообщения об ошибках авторизации для отображения пользователю.
class AuthErrors {
  AuthErrors._();

  static String loginMessage(String code) {
    switch (code) {
      case 'USER_NOT_FOUND':
        return 'Пользователь не найден';
      case 'EMAIL_NOT_VERIFIED':
        return 'Подтвердите email (проверьте почту)';
      case 'INVALID_CREDENTIALS':
        return 'Неверный пароль';
      case 'INVALID_INPUT':
        return 'Проверьте email и пароль';
      case 'SERVER_MISCONFIGURATION':
        return 'Сервер не настроен (нет AUTH_SECRET)';
      case 'SERVER_ERROR':
        return 'Ошибка сервера. Попробуйте позже.';
      default:
        return code;
    }
  }

  static String registerMessage(String code) {
    switch (code) {
      case 'EMAIL_TAKEN':
        return 'Этот email уже занят';
      case 'INVALID_INPUT':
        return 'Email и пароль (мин. 8 символов)';
      default:
        return code;
    }
  }

  /// Сообщение по HTTP status + опциональному коду из тела (для DioException).
  static String loginFromDio(int? statusCode, String? bodyError) {
    switch ((statusCode, bodyError)) {
      case (404, _):
        return 'Пользователь не найден';
      case (401, _):
        return 'Неверный пароль';
      case (403, _):
        return 'Подтвердите email (проверьте почту)';
      case (503, 'SERVER_MISCONFIGURATION'):
        return 'Сервер не настроен (нет AUTH_SECRET)';
      case (503, _):
        return 'Сервис временно недоступен';
      case (500, _):
        return 'Ошибка сервера. Попробуйте позже.';
      default:
        return 'Ошибка сети';
    }
  }

  static String registerFromDio(int? statusCode, String? bodyError) {
    switch ((statusCode, bodyError)) {
      case (409, _):
        return 'Этот email уже занят';
      case (503, _):
        return 'Сервис временно недоступен';
      case (500, _):
        return 'Ошибка сервера. Попробуйте позже.';
      default:
        return 'Ошибка сети';
    }
  }
}
