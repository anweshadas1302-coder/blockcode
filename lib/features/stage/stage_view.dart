import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'turtle_state.dart';

class StagePainter extends CustomPainter {
  StagePainter(this.turtle) : super(repaint: turtle);
  final TurtleState turtle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    final grid = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (double i = 0; i <= size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), grid);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), grid);
    }

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    for (final s in turtle.segments) {
      canvas.drawLine(
        s.from,
        s.to,
        Paint()
          ..color = s.color
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }

    // the turtle itself: a little triangle pointing along its heading
    canvas.translate(turtle.x, turtle.y);
    canvas.rotate(turtle.angle * math.pi / 180);
    final body = Path()
      ..moveTo(0, -12)
      ..lineTo(8, 8)
      ..lineTo(-8, 8)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.green.shade600);
    canvas.restore();
  }

  @override
  bool shouldRepaint(StagePainter old) => true;
}

class StageView extends StatelessWidget {
  const StageView({super.key, required this.turtle});
  final TurtleState turtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 320,
          height: 320,
          child: CustomPaint(painter: StagePainter(turtle)),
        ),
      ),
    );
  }
}
