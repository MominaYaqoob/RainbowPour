import 'dart:math' as math;
import 'dart:ui';

/// How many shelf rows [bottles] use.
///
/// 1..25 match the original game screen. 26..30 (the daily challenge, up to
/// [challenge layout max]) use 5 rows. 31..35 stay on 5 rows so the extra
/// bottle on a 30-bottle board still has a slot and does not crash.
int boardRows(int bottles) {
  if (bottles <= 4) return 1;
  if (bottles <= 12) return 2;
  if (bottles <= 18) return 3;
  if (bottles <= 25) return 4;
  if (bottles <= 35) return 5;
  return 6;
}

/// Bottle positions for the game board. All coordinates are inside the area
/// whose size is [maxWidth] by [maxHeight], origin at the top-left.
class BoardLayout {
  const BoardLayout({
    required this.w,
    required this.h,
    required this.width,
    required this.tops,
    required this.shelves,
    required this.rows,
  });

  /// Bottle width in px. At least 24.
  final double w;

  /// Bottle height in px.
  final double h;

  /// Width of the area the board was laid out in.
  final double width;

  /// Top-left of every bottle's box.
  final List<Offset> tops;

  final List<Rect> shelves;
  final int rows;

  /// Scale from the 36-wide bottle drawing to the screen.
  double get s => w / 36;
}

/// Rows of bottles on shelves, sized to the free space.
///
/// The first row keeps at least `0.7 * bottle width` above it. That is the
/// room the pour uses to lift a bottle before it travels over its target.
/// Five-row boards use the same reserve; the bottles get shorter so the last
/// shelf still ends inside [maxHeight]. Counts 1..25 stay on the original
/// numbers.
BoardLayout layoutBoard({
  required int bottles,
  required double maxWidth,
  required double maxHeight,
}) {
  final n = bottles;
  final rows = boardRows(n);
  final perRow = (n / rows).ceil();
  final gap = perRow > 5 ? 10.0 : 14.0;
  const shelf = 16.0;
  final rowGap = rows > 2 ? 14.0 : 24.0;
  final byWidth = (maxWidth - 48 - gap * (perRow - 1)) / perRow;
  final byHeight =
      ((maxHeight - rowGap * (rows - 1) - shelf * rows - 40) / rows) * 36 / 118;
  // slim bottles: about 11.5% of the screen width
  final maxW = (maxWidth * (rows == 1 ? 0.15 : 0.115)).clamp(30.0, 56.0);
  final w = math.max(24.0, math.min(math.min(byWidth, byHeight), maxW));
  final h = w * 118 / 36;
  final blockH = rows * (h + shelf) + rowGap * (rows - 1);
  // keep room above the first row for a bottle that pours onto it
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
