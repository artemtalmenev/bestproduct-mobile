/// Базовый URL бэкенда.
/// Эмулятор Android: 10.0.2.2:3000; устройство/прод: IP или хост.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://158.160.193.252:3000',
);

/// Для эмулятора Android используйте: http://10.0.2.2:3000
/// Для продакшена: http://158.160.193.252:3000 (или ваш домен)
