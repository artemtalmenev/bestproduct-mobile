# Best Product — мобильное приложение (Flutter)

Клиент к бэкенду Best Product: задачи, календарь, AI-запросы, авторизация по email/паролю (сессия в cookie).

Бэкенд развёрнут отдельно (Next.js). Подключение к API без изменений.

## Требования

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (рекомендуется 3.22+)
- Android SDK (для сборки под Android)

## Запуск

```bash
flutter pub get
flutter run
```

Для выбора устройства: `flutter run -d chrome` (веб) или `flutter run -d <device_id>` (телефон).

## Базовый URL API

По умолчанию приложение обращается к бэкенду: **`http://158.160.193.252:3000`**.

- **Эмулятор Android** (бэкенд на вашем компьютере):
  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
  ```
- **Другой хост/порт:**
  ```bash
  flutter run --dart-define=API_BASE_URL=http://ВАШ_ХОСТ:3000
  ```

## API бэкенда

- `GET /api/health` — проверка работы API
- `POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/logout` — регистрация, вход, выход
- `GET /api/tasks`, `POST /api/tasks`, `PATCH /api/tasks/[id]`, `DELETE /api/tasks/[id]` — задачи
- `GET /api/requests`, `POST /api/requests` — запросы к AI

Авторизация: cookie `session` после входа.

## Структура проекта

- `lib/config/api_config.dart` — базовый URL API
- `lib/services/api_client.dart` — HTTP-клиент (Dio + cookie_jar)
- `lib/screens/` — экраны: логин, регистрация, задачи, календарь, AI, настройки
