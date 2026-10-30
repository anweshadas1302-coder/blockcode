import 'dart:math' as math;

import 'package:flutter/material.dart';

class Segment {
  const Segment(this.from, this.to, this.color);
  final Offset from;
  final Offset to;
  final Color color;
}

/// The "world" the program draws on. Heading 0 = up, turning is clockwise.
/// Origin (0,0) is the center of the stage.
class TurtleState extends ChangeNotifier {
  static const _defaultColor = Color(0xFF2196F3);

  double x = 0, y = 0, angle = 0;
  bool penDown = true;
  Color color = _defaultColor;
  final List<Segment> segments = [];

  void reset() {
    x = 0;
    y = 0;
    angle = 0;
    penDown = true;
    color = _defaultColor;
    segments.clear();
    notifyListeners();
  }

  void move(double distance) {
    final r = angle * math.pi / 180;
    final nx = x + distance * math.sin(r);
    final ny = y - distance * math.cos(r); // screen y points down
    if (penDown) segments.add(Segment(Offset(x, y), Offset(nx, ny), color));
    x = nx;
    y = ny;
    notifyListeners();
  }

  void turn(double degrees) {
    angle = (angle + degrees) % 360;
    notifyListeners();
  }

  void setPen(bool down) {
    penDown = down;
    notifyListeners();
  }

  void setColor(Color c) {
    color = c;
    notifyListeners();
  }
}
