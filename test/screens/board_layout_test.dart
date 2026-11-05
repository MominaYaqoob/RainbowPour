import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:rainbow_pour/screens/game/board_layout.dart';

void main() {
  test('counts 1 to 25 keep the original bottle positions', () {
    const areas = [Size(360, 740), Size(411, 890)];
    for (final area in areas) {
      for (var n = 1; n <= 25; n++) {
        final next = layoutBoard(
          bottles: n,
          maxWidth: area.width,
          maxHeight: area.height,
        );
        final old = _legacy(n, area.width, area.height);
        expect(next.rows, old.rows, reason: 'rows for $n');
        expect(next.w, old.w, reason: 'width for $n');
        expect(next.h, old.h, reason: 'height for $n');
        expect(next.tops.length, n);
        expect(next.tops, old.tops, reason: 'tops for $n on $area');
        expect(next.shelves, old.shelves, reason: 'shelves for $n on $area');
      }
    }

    // Locked sample: 4 bottles, one row, 360 x 740.
    final sample = layoutBoard(bottles: 4, maxWidth: 360, maxHeight: 740);
    expect(sample.w, 54);
    expect(sample.h, 177);
    expect(sample.rows, 1);
    expect(sample.tops.first, const Offset(51, 281.5));
    expect(sample.tops.last.dx, 51 + 3 * (54 + 14));
  });

  test('every count from 1 to 31 fits both phone areas', () {
    const areas = [Size(360, 740), Size(411, 890)];
    for (final area in areas) {
      for (var n = 1; n <= 31; n++) {
        final lay = layoutBoard(
          bottles: n,
          maxWidth: area.width,
          maxHeight: area.height,
        );
        expect(lay.rows, _expectedRows(n), reason: 'rows for $n');
        expect(lay.w, greaterThanOrEqualTo(24));
        expect(lay.tops, hasLength(n));
        expect(lay.h, closeTo(lay.w * 118 / 36, 0.001));
        // room above the first bottle for the pour lift
        expect(lay.tops.first.dy, greaterThanOrEqualTo(lay.w * 0.7));
        final boxes = <Rect>[];
        for (final top in lay.tops) {
          final box = Rect.fromLTWH(top.dx, top.dy, lay.w, lay.h);
          expect(box.left, greaterThanOrEqualTo(-0.01));
          expect(box.top, greaterThanOrEqualTo(-0.01));
          expect(box.right, lessThanOrEqualTo(area.width + 0.01));
          expect(box.bottom, lessThanOrEqualTo(area.height + 0.01));
          for (final other in boxes) {
            expect(box.overlaps(other), isFalse, reason: 'overlap at $n');
          }
          boxes.add(box);
        }
      }
    }
  });
}

int _expectedRows(int n) {
  if (n <= 4) return 1;
  if (n <= 12) return 2;
  if (n <= 18) return 3;
  if (n <= 25) return 4;
  return 5;
}

/// The game screen's layout before the daily challenge rows were added.
BoardLayout _legacy(int n, double maxWidth, double maxHeight) {
  final rows = n <= 4 ? 1 : (n <= 12 ? 2 : (n <= 18 ? 3 : 4));
  final perRow = (n / rows).ceil();
  final gap = perRow > 5 ? 10.0 : 14.0;
  const shelf = 16.0;
  final rowGap = rows > 2 ? 14.0 : 24.0;
  final byWidth = (maxWidth - 48 - gap * (perRow - 1)) / perRow;
  final byHeight =
      ((maxHeight - rowGap * (rows - 1) - shelf * rows - 40) / rows) * 36 / 118;
  final maxW = (maxWidth * (rows == 1 ? 0.15 : 0.115)).clamp(30.0, 56.0);
  final w = math.max(24.0, math.min(math.min(byWidth, byHeight), maxW));
  final h = w * 118 / 36;
  final blockH = rows * (h + shelf) + rowGap * (rows - 1);
  final top0 = math.max(w * 0.7, (maxHeight - blockH) / 2);
  final tops = <Offset>[];
  final shelves = <Rect>[];
  for (var r = 0; r < rows; r++) {
    final start = r * perRow;
    final end = math.min(n, start + perRow);
    final k = end - start;
    if (k <= 0) break;
    final rowW = w * k + gap * (k - 1);
    final x0 = (maxWidth - rowW) / 2;
    final rowTop = top0 + r * (h + shelf + rowGap);
    for (var j = 0; j < k; j++) {
      tops.add(Offset(x0 + j * (w + gap), rowTop + 8));
    }
    shelves.add(Rect.fromLTWH(x0 - 12, rowTop + h + 7, rowW + 24, 9));
  }
  return BoardLayout(
    w: w,
    h: h,
    width: maxWidth,
    tops: tops,
    shelves: shelves,
    rows: rows,
  );
}
