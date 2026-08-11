// Draws the launcher icon and writes every density Android needs.
//
// The mark is checked in as generated PNGs so a normal build needs no tooling,
// but it is generated rather than hand-drawn so the geometry stays consistent
// across densities and anyone can change it in one place:
//
//   dart run tool/generate_icons.dart
//
// The design: a dot-matrix rendering of the Essential Key's pill silhouette,
// with the press position picked out in red. Dot-matrix and monochrome-plus-one-
// accent is the visual language of the phones this runs on; the shape is the
// hardware key itself, so the icon says what the app is about at 48dp.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Foreground art occupies the middle 72dp of the 108dp adaptive icon canvas;
/// anything outside can be cropped by the launcher's mask.
const double _safeZoneRatio = 72 / 108;

final _accent = ColorRgb8(0xD7, 0x19, 0x21);
final _ink = ColorRgb8(0xFB, 0xFB, 0xF9);
final _background = ColorRgb8(0x0A, 0x0A, 0x0A);

/// Android's five launcher-icon densities, as multiples of mdpi.
const Map<String, double> _densities = {
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

/// The key as a 3x7 dot grid, with the outer dots of the first and last rows
/// dropped so it reads as a pill. One dot at the centre is the press, drawn in
/// the accent colour — a whole accent row reads as a strike-through instead.
const int _gridWidth = 3;
const int _gridHeight = 7;
const int _pressRow = 3;
const int _pressColumn = 1;

void main() {
  final res = Directory('android/app/src/main/res');
  if (!res.existsSync()) {
    stderr.writeln('Run this from the repository root.');
    exit(1);
  }

  for (final entry in _densities.entries) {
    final density = entry.value;

    // Adaptive foreground: 108dp canvas, transparent outside the art.
    final foregroundSize = (108 * density).round();
    _write(
      res,
      'mipmap-${entry.key}/ic_launcher_foreground.png',
      _drawMark(foregroundSize, opaque: false),
    );

    // Legacy icon: 48dp canvas, own background, for launchers that ignore v26.
    final legacySize = (48 * density).round();
    _write(
      res,
      'mipmap-${entry.key}/ic_launcher.png',
      _drawMark(legacySize, opaque: true),
    );
  }

  // Store listing and README art.
  _writeTo('docs/icon-512.png', _drawMark(512, opaque: true));

  stdout.writeln('Wrote launcher icons for ${_densities.length} densities.');
}

void _write(Directory res, String relativePath, Image image) =>
    _writeTo('${res.path}/$relativePath', image);

void _writeTo(String path, Image image) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(encodePng(image));
  stdout.writeln('  $path');
}

Image _drawMark(int size, {required bool opaque}) {
  final image = Image(width: size, height: size, numChannels: 4);
  fill(image, color: opaque ? _background : ColorRgba8(0, 0, 0, 0));

  // Lay the grid out inside the safe zone so a circular or squircle mask cannot
  // clip it, then size the dots from the cell so spacing scales with the canvas.
  final safe = size * (opaque ? 0.72 : _safeZoneRatio);
  final cell = safe / _gridHeight;
  final radius = cell * 0.32;

  final gridPixelWidth = cell * _gridWidth;
  final gridPixelHeight = cell * _gridHeight;
  final left = (size - gridPixelWidth) / 2;
  final top = (size - gridPixelHeight) / 2;

  for (var row = 0; row < _gridHeight; row++) {
    for (var column = 0; column < _gridWidth; column++) {
      // Round the pill: drop the outer dots on the first and last rows.
      final isCap = row == 0 || row == _gridHeight - 1;
      if (isCap && column != 1) continue;

      final cx = left + cell * (column + 0.5);
      final cy = top + cell * (row + 0.5);

      fillCircle(
        image,
        x: cx.round(),
        y: cy.round(),
        radius: math.max(1, radius.round()),
        color: row == _pressRow && column == _pressColumn ? _accent : _ink,
        antialias: true,
      );
    }
  }

  return image;
}
