/// Board rendering: custom-painted backgammon board with tap handling,
/// plus dice and doubling-cube widgets.
library;

import 'package:flutter/material.dart';
import '../rules/backgammon_engine.dart';
import '../theme/game_themes.dart';

/// Geometry helper shared by painter and hit-testing.
class BoardGeometry {
  final Size size;
  late final double frame = size.width * 0.035;
  late final double barW = size.width * 0.075;
  late final double quadW = (size.width - frame * 2 - barW) / 2;
  late final double pointW = quadW / 6;
  late final double boardH = size.height - frame * 2;
  late final double pointH = boardH * 0.40;
  late final double checkerR = pointW * 0.44;

  BoardGeometry(this.size);

  /// Point number 1..24 -> rect of the triangular spike.
  Rect pointRect(int point) {
    final top = point >= 13;
    // quadrant column 0..5 within its half
    int col;
    bool leftHalf;
    if (point >= 19) {
      col = point - 19;
      leftHalf = false;
    } else if (point >= 13) {
      col = point - 13;
      leftHalf = true;
    } else if (point >= 7) {
      col = 12 - point;
      leftHalf = true;
    } else {
      col = 6 - point;
      leftHalf = false;
    }
    final quadX = frame + (leftHalf ? 0 : quadW + barW);
    final x = quadX + col * pointW;
    final y = top ? frame : size.height - frame - pointH;
    return Rect.fromLTWH(x, y, pointW, pointH);
  }

  /// Center of the checker stack at [point] for stack position [stackIndex].
  Offset checkerCenter(int point, int stackIndex) {
    final r = pointRect(point);
    final top = point >= 13;
    final maxStack = (pointH / (checkerR * 2)).floor().clamp(1, 5);
    final i = stackIndex.clamp(0, maxStack - 1);
    final y = top
        ? r.top + checkerR + i * checkerR * 2
        : r.bottom - checkerR - i * checkerR * 2;
    return Offset(r.center.dx, y);
  }

  Rect barRect() => Rect.fromLTWH(
      frame + quadW, frame, barW, boardH);

  /// Tap -> point number (1..24), 25 = bar, 0 = bear-off tray, -1 = none.
  int hitTest(Offset p) {
    if (p.dx < frame || p.dx > size.width - frame) {
      // right frame = bear-off tray
      if (p.dx >= size.width - frame) return 0;
      return -1;
    }
    if (p.dx >= frame + quadW && p.dx <= frame + quadW + barW) return 25;
    for (int pt = 1; pt <= 24; pt++) {
      final r = pointRect(pt);
      final tapZone = Rect.fromLTWH(
          r.left, pt >= 13 ? frame : size.height - frame - pointH,
          pointW, pointH + checkerR);
      if (tapZone.contains(p)) return pt;
    }
    return -1;
  }
}

class BoardWidget extends StatelessWidget {
  final Position pos;
  final GameTheme theme;
  final int? selectedPoint;
  final List<BgMove> hintMoves;
  final int cubeValue;
  final Checker? cubeOwner;
  final void Function(int point) onTapPoint;

  const BoardWidget({
    super.key,
    required this.pos,
    required this.theme,
    required this.selectedPoint,
    required this.hintMoves,
    required this.cubeValue,
    required this.cubeOwner,
    required this.onTapPoint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxWidth * 0.72);
      return GestureDetector(
        onTapDown: (d) {
          final g = BoardGeometry(size);
          final local = d.localPosition;
          final hit = g.hitTest(local);
          if (hit >= 0) onTapPoint(hit);
        },
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: CustomPaint(
            painter: _BoardPainter(
              pos: pos,
              theme: theme,
              selectedPoint: selectedPoint,
              hintMoves: hintMoves,
              cubeValue: cubeValue,
              cubeOwner: cubeOwner,
            ),
          ),
        ),
      );
    });
  }
}

class _BoardPainter extends CustomPainter {
  final Position pos;
  final GameTheme theme;
  final int? selectedPoint;
  final List<BgMove> hintMoves;
  final int cubeValue;
  final Checker? cubeOwner;

  _BoardPainter({
    required this.pos,
    required this.theme,
    required this.selectedPoint,
    required this.hintMoves,
    required this.cubeValue,
    required this.cubeOwner,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final g = BoardGeometry(size);
    // Frame
    final framePaint = Paint()..color = theme.frame;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(14)),
        framePaint);
    // Felt
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(g.frame, g.frame, size.width - g.frame * 2,
                size.height - g.frame * 2),
            const Radius.circular(6)),
        Paint()..color = theme.felt);

    // Points (spikes)
    for (int pt = 1; pt <= 24; pt++) {
      final r = g.pointRect(pt);
      final top = pt >= 13;
      final color = (pt % 2 == 1) ? theme.pointA : theme.pointB;
      final path = Path()
        ..moveTo(r.left, top ? r.top : r.bottom)
        ..lineTo(r.right, top ? r.top : r.bottom)
        ..lineTo(r.center.dx, top ? r.bottom : r.top)
        ..close();
      bool highlight = selectedPoint == pt;
      canvas.drawPath(
          path,
          Paint()
            ..color =
                highlight ? theme.accent.withValues(alpha: 0.85) : color);
      if (hintMoves.any((m) => m.to == pt)) {
        canvas.drawPath(
            path, Paint()..color = theme.accent.withValues(alpha: 0.45));
      }
    }

    // Bar
    final bar = g.barRect();
    canvas.drawRRect(
        RRect.fromRectAndRadius(bar, const Radius.circular(6)),
        Paint()..color = theme.frame.withValues(alpha: 0.85));

    // Checkers on points
    for (int pt = 1; pt <= 24; pt++) {
      final v = pos.points[pt - 1];
      if (v == 0) continue;
      final isWhite = v > 0;
      final count = v.abs();
      final maxStack = (g.pointH / (g.checkerR * 2)).floor().clamp(1, 5);
      final drawn = count.clamp(1, maxStack);
      for (int i = 0; i < drawn; i++) {
        _drawChecker(canvas, g.checkerCenter(pt, i), g.checkerR, isWhite);
      }
      if (count > maxStack) {
        _drawCountBadge(canvas, g.checkerCenter(pt, maxStack - 1),
            g.checkerR, count, isWhite);
      }
    }

    // Bar checkers
    _drawBarStack(canvas, g, pos.barWhite, true);
    _drawBarStack(canvas, g, pos.barBlack, false);
    // Bear-off badges on the right frame
    _drawOffBadge(canvas, size, g, true);
    _drawOffBadge(canvas, size, g, false);

    // Doubling cube on the bar
    _drawCube(canvas, g);

    // Selected bar highlight
    if (selectedPoint == 25) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(bar.inflate(3), const Radius.circular(8)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = theme.accent);
    }
  }

  void _drawChecker(Canvas canvas, Offset c, double r, bool isWhite) {
    final base = isWhite ? theme.checkerLight : theme.checkerDark;
    canvas.drawCircle(c, r, Paint()..color = base);
    canvas.drawCircle(
        c,
        r * 0.72,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..color = isWhite
              ? theme.checkerDark.withValues(alpha: 0.55)
              : theme.checkerLight.withValues(alpha: 0.55));
    canvas.drawCircle(
        c + Offset(-r * 0.25, -r * 0.25),
        r * 0.18,
        Paint()
          ..color = Colors.white.withValues(alpha: isWhite ? 0.5 : 0.22));
  }

  void _drawCountBadge(
      Canvas canvas, Offset c, double r, int count, bool isWhite) {
    final tp = TextPainter(
      text: TextSpan(
          text: '$count',
          style: TextStyle(
              color: isWhite ? Colors.black : Colors.white,
              fontSize: r * 0.9,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawBarStack(
      Canvas canvas, BoardGeometry g, int count, bool isWhite) {
    if (count <= 0) return;
    final bar = g.barRect();
    final y = isWhite ? bar.top + g.checkerR * 1.1 : bar.bottom - g.checkerR * 1.1;
    // draw up to 3 stacked on the bar center
    for (int i = 0; i < count.clamp(1, 3); i++) {
      final yy = isWhite ? y + i * g.checkerR * 0.9 : y - i * g.checkerR * 0.9;
      _drawChecker(canvas, Offset(bar.center.dx, yy), g.checkerR * 0.92, isWhite);
    }
    if (count > 3) {
      _drawCountBadge(
          canvas, Offset(bar.center.dx, isWhite ? y + 2 * g.checkerR * 0.9 : y - 2 * g.checkerR * 0.9),
          g.checkerR * 0.92, count, isWhite);
    }
  }

  void _drawOffBadge(
      Canvas canvas, Size size, BoardGeometry g, bool isWhite) {
    final count = isWhite ? pos.offWhite : pos.offBlack;
    if (count == 0) return;
    final y = isWhite
        ? size.height - g.frame / 2
        : g.frame / 2;
    final tp = TextPainter(
      text: TextSpan(
          text: '⬤ $count off',
          style: TextStyle(
              color: theme.accent,
              fontSize: 13,
              fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
        canvas, Offset(size.width - g.frame - tp.width - 4, y - tp.height / 2));
  }

  void _drawCube(Canvas canvas, BoardGeometry g) {
    final bar = g.barRect();
    final c = bar.center;
    final s = g.barW * 0.72;
    final rect = Rect.fromCenter(center: c, width: s, height: s);
    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = theme.accent);
    // rotate indicator for owner
    if (cubeOwner != null) {
      canvas.drawCircle(
          c + Offset(0, cubeOwner == Checker.white ? -s * 0.32 : s * 0.32),
          s * 0.08,
          Paint()..color = theme.frame);
    }
    final tp = TextPainter(
      text: TextSpan(
          text: '$cubeValue',
          style: TextStyle(
              color: theme.frame,
              fontSize: s * 0.52,
              fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}

/// Simple dice row.
class DiceRow extends StatelessWidget {
  final List<int> dice;
  final Color pipColor;
  final Color faceColor;
  const DiceRow(
      {super.key,
      required this.dice,
      required this.pipColor,
      required this.faceColor});

  @override
  Widget build(BuildContext context) {
    if (dice.isEmpty) {
      return const SizedBox(
          height: 44, child: Center(child: Text('Tap ROLL to begin your turn')));
    }
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dice
            .map((d) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _Die(value: d, pipColor: pipColor, faceColor: faceColor),
                ))
            .toList(),
      ),
    );
  }
}

class _Die extends StatelessWidget {
  final int value;
  final Color pipColor;
  final Color faceColor;
  const _Die(
      {required this.value, required this.pipColor, required this.faceColor});

  @override
  Widget build(BuildContext context) {
    const spots = {
      1: [4],
      2: [0, 8],
      3: [0, 4, 8],
      4: [0, 2, 6, 8],
      5: [0, 2, 4, 6, 8],
      6: [0, 2, 3, 5, 6, 8],
    };
    final on = spots[value] ?? [4];
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: faceColor,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
      ),
      child: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(6),
        children: List.generate(
            9,
            (i) => Center(
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on.contains(i) ? pipColor : Colors.transparent,
                    ),
                  ),
                )),
      ),
    );
  }
}
