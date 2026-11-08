import 'package:flutter/foundation.dart';

import '../core/expr.dart';
import 'level.dart';

/// The state of the bot on one level: position, heading, gems, and the
/// timestamps the painter uses to animate moves.
class RobotWorld extends ChangeNotifier {
  RobotWorld(this.level) {
    reset();
  }

  final Level level;
  static const _dx = [0, 1, 0, -1];
  static const _dy = [-1, 0, 1, 0];

  final Stopwatch clock = Stopwatch()..start();

  int x = 0, y = 0, prevX = 0, prevY = 0;
  double facing = 0, prevFacing = 0; // degrees, grows when turning right
  int moveStartMs = -100000, moveDurMs = 150, shakeAtMs = -100000;
  bool dead = false;
  final Set<(int, int)> gems = {};
  final List<({int x, int y, int atMs})> bursts = [];

  int get rows => level.rows;
  int get cols => level.cols;
  int get dir => (((facing / 90).round() % 4) + 4) % 4;
  int get gemsLeft => gems.length;

  String tile(int tx, int ty) {
    if (tx < 0 || ty < 0 || tx >= cols || ty >= rows) return '#';
    return level.map[ty][tx];
  }

  // Sensors the program can read in conditions.
  bool get wallAhead => tile(x + _dx[dir], y + _dy[dir]) == '#';
  bool get lavaAhead => tile(x + _dx[dir], y + _dy[dir]) == 'L';
  bool get atExit => tile(x, y) == 'E';

  void reset() {
    gems.clear();
    bursts.clear();
    dead = false;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final ch = level.map[r][c];
        if (ch == 'S') {
          x = c;
          y = r;
        }
        if (ch == 'G') gems.add((c, r));
      }
    }
    prevX = x;
    prevY = y;
    facing = level.startDir * 90.0;
    prevFacing = facing;
    moveStartMs = -100000;
    shakeAtMs = -100000;
    notifyListeners();
  }

  void step(int durMs) {
    final nx = x + _dx[dir];
    final ny = y + _dy[dir];
    final t = tile(nx, ny);
    final now = clock.elapsedMilliseconds;
    if (t == '#') {
      shakeAtMs = now;
      notifyListeners();
      throw LangError('Bonk! The bot hit a wall.');
    }
    prevX = x;
    prevY = y;
    prevFacing = facing;
    x = nx;
    y = ny;
    moveStartMs = now;
    moveDurMs = durMs < 1 ? 1 : durMs;
    if (gems.remove((nx, ny))) {
      bursts.add((x: nx, y: ny, atMs: now));
    }
    if (t == 'L') {
      dead = true;
      notifyListeners();
      throw LangError('The bot fell into lava!');
    }
    notifyListeners();
  }

  void turn(bool right, int durMs) {
    prevX = x;
    prevY = y;
    prevFacing = facing;
    facing += right ? 90 : -90;
    moveStartMs = clock.elapsedMilliseconds;
    moveDurMs = durMs < 1 ? 1 : durMs;
    notifyListeners();
  }
}
