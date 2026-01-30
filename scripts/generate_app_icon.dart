// ignore_for_file: avoid_print
// Генерирует assets/icon/app_icon.png 1024x1024 из дизайна логотипа (центрировано, без обрезки).
// Запуск: dart run scripts/generate_app_icon.dart

import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const size = 1024;
  const scale = size / 128.0; // SVG viewBox 0 0 128 128

  final image = img.Image(width: size, height: size);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final black = img.ColorRgba8(17, 17, 17, 255);
  final darkGray = img.ColorRgba8(42, 42, 42, 255);
  final transparent = img.ColorRgba8(0, 0, 0, 0);

  // Прозрачный фон — на Android adaptive icon (чёрный фон) будет виден белый круг
  img.fill(image, color: transparent);

  // 1. Белый круг (фон логотипа)
  final cx = (64.0 * scale).round();
  final cy = (64.0 * scale).round();
  final cr = (60.0 * scale).round();
  img.fillCircle(image, x: cx, y: cy, radius: cr, color: white);

  // 2. Куб — чёрный скруглённый rect (34,52 60x44 rx=10)
  final rx = (34.0 * scale).round();
  final ry = (52.0 * scale).round();
  final rw = (60.0 * scale).round();
  final rh = (44.0 * scale).round();
  final rr = (10.0 * scale).round();
  drawRoundedRect(image, rx, ry, rw, rh, rr, black);

  // 3. Линия по центру куба (64,52 — 64,96)
  final lx = (64.0 * scale).round();
  img.drawLine(
    image,
    x1: lx,
    y1: (52.0 * scale).round(),
    x2: lx,
    y2: (96.0 * scale).round(),
    color: darkGray,
    thickness: (2.0 * scale).round().clamp(1, 10),
  );

  // 4. Галочка (белая, толстая): M48 74 L58 84 L80 62
  final strokeW = (5.0 * scale).round().clamp(2, 24);
  drawThickLine(
    image,
    (48.0 * scale).round(),
    (74.0 * scale).round(),
    (58.0 * scale).round(),
    (84.0 * scale).round(),
    strokeW,
    white,
  );
  drawThickLine(
    image,
    (58.0 * scale).round(),
    (84.0 * scale).round(),
    (80.0 * scale).round(),
    (62.0 * scale).round(),
    strokeW,
    white,
  );

  // 5. AI stem (64,52 — 64,38)
  img.drawLine(
    image,
    x1: lx,
    y1: (52.0 * scale).round(),
    x2: lx,
    y2: (38.0 * scale).round(),
    color: black,
    thickness: (3.0 * scale).round().clamp(1, 10),
  );

  // 6. AI nodes — круги и линии
  final n1x = (64.0 * scale).round();
  final n1y = (32.0 * scale).round();
  final n2x = (52.0 * scale).round();
  final n2y = (38.0 * scale).round();
  final n3x = (76.0 * scale).round();
  final n3y = (38.0 * scale).round();
  final r1 = (5.0 * scale).round();
  final r2 = (3.5 * scale).round();

  img.fillCircle(image, x: n1x, y: n1y, radius: r1, color: black);
  img.fillCircle(image, x: n2x, y: n2y, radius: r2, color: black);
  img.fillCircle(image, x: n3x, y: n3y, radius: r2, color: black);
  img.drawLine(
    image,
    x1: n1x,
    y1: n1y,
    x2: n2x,
    y2: n2y,
    color: black,
    thickness: (2.5 * scale).round().clamp(1, 8),
  );
  img.drawLine(
    image,
    x1: n1x,
    y1: n1y,
    x2: n3x,
    y2: n3y,
    color: black,
    thickness: (2.5 * scale).round().clamp(1, 8),
  );

  final outPath = 'assets/icon/app_icon.png';
  File(outPath).parent.createSync(recursive: true);
  File(outPath).writeAsBytesSync(img.encodePng(image));
  print('Generated $outPath ($size×$size)');
}

void drawRoundedRect(
  img.Image image,
  int x,
  int y,
  int w,
  int h,
  int r,
  img.Color color,
) {
  final right = x + w;
  final bottom = y + h;
  img.fillRect(image, x1: x + r, y1: y, x2: right - r, y2: bottom, color: color);
  img.fillRect(image, x1: x, y1: y + r, x2: right, y2: bottom - r, color: color);
  img.fillCircle(image, x: x + r, y: y + r, radius: r, color: color);
  img.fillCircle(image, x: right - r, y: y + r, radius: r, color: color);
  img.fillCircle(image, x: x + r, y: bottom - r, radius: r, color: color);
  img.fillCircle(image, x: right - r, y: bottom - r, radius: r, color: color);
}

void drawThickLine(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  int thickness,
  img.Color color,
) {
  final half = thickness ~/ 2;
  for (var d = -half; d <= half; d++) {
    final dx = (d * (y2 - y1) / (thickness + 1)).round();
    final dy = (d * (x1 - x2) / (thickness + 1)).round();
    img.drawLine(image, x1: x1 + dx, y1: y1 + dy, x2: x2 + dx, y2: y2 + dy, color: color);
  }
  img.drawLine(image, x1: x1, y1: y1, x2: x2, y2: y2, color: color, thickness: thickness.clamp(1, 50));
}
