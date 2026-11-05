import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'turtle_state.dart';

class StagePainter extends CustomPainter {
  StagePainter(this.turtle) : super(repaint: turtle);
  final TurtleState turtle;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);

    // Light grid
    final grid = Paint()
      ..color = Colors.black12
      ..strokeWidth = 1;
    for (double i = 0; i <= size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), grid);
      canvas.drawLine(Offset(0, i), Offset(size.width, i), grid);
    }

    // Center cross-hair (the turtle's starting point)
    final axis = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      axis,
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      axis,
    );

    // How far from the center does the drawing reach? Zoom out to fit it.
    var reach = math.max(turtle.x.abs(), turtle.y.abs());
    for (final s in turtle.segments) {
      reach = math.max(reach, math.max(s.to.dx.abs(), s.to.dy.abs()));
    }
    final usable = size.width / 2 - 28;
    final scale = reach > usable ? usable / reach : 1.0;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);

    for (final s in turtle.segments) {
      canvas.drawLine(
        s.from,
        s.to,
        Paint()
          ..color = s.color
          ..strokeWidth = 3 / scale
          ..strokeCap = StrokeCap.round,
      );
    }

    // Start dot
    canvas.drawCircle(Offset.zero, 4 / scale, Paint()..color = Colors.black38);

    // The turtle: a triangle pointing along its heading, constant on-screen size
    canvas.translate(turtle.x, turtle.y);
    canvas.scale(1 / scale);
    canvas.rotate(turtle.angle * math.pi / 180);
    final body = Path()
      ..moveTo(0, -14)
      ..lineTo(10, 10)
      ..lineTo(-10, 10)
      ..close();
    canvas.drawPath(body, Paint()..color = Colors.green.shade600);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white,
    );
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
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 320,
                height: 320,
                child: CustomPaint(painter: StagePainter(turtle)),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 8,
            child: ListenableBuilder(
              listenable: turtle,
              builder: (context, _) => Text(
                'position (${turtle.x.round()}, ${(-turtle.y).round()})   '
                'heading ${turtle.angle.round()}°',
                style: const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
