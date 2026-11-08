import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;

import '../features/stage/turtle_state.dart';
import '../game/robot_world.dart';
import 'ast.dart';
import 'expr.dart';

/// Thrown internally when the user presses Stop.
class StoppedSignal implements Exception {}

/// Walks the statement tree. It is async so the UI can repaint between steps
/// and so we can highlight the block that is currently running.
///
/// Pass a [turtle] for Sandbox drawing, or a [robot] for Quest levels.
/// With a robot, conditions can read the sensors: wall, lava, goal.
class Interpreter {
  Interpreter({
    this.turtle,
    this.robot,
    required this.delayMs,
    this.onHighlight,
    this.onPrint,
    this.maxSteps = 50000,
  });

  final TurtleState? turtle;
  final RobotWorld? robot;
  final int Function() delayMs;
  final void Function(String? blockId)? onHighlight;
  final void Function(String text)? onPrint;
  final int maxSteps;

  final Map<String, double> vars = {};
  int _steps = 0;
  bool _stopped = false;

  void stop() => _stopped = true;

  TurtleState _turtle() =>
      turtle ?? (throw LangError('Drawing blocks only work in the Sandbox'));
  RobotWorld _robot() =>
      robot ?? (throw LangError('Bot blocks only work in Quest levels'));

  /// How long a move animation lasts (never longer than the step delay).
  int _animMs() => math.max(30, math.min(delayMs(), 180));

  Future<void> run(List<Stmt> program) async {
    _steps = 0;
    _stopped = false;
    vars.clear();
    try {
      await _block(program);
    } finally {
      onHighlight?.call(null);
    }
  }

  void _guard() {
    if (_stopped) throw StoppedSignal();
    if (++_steps > maxSteps) {
      throw LangError(
        'Stopped after $maxSteps steps - is there an infinite loop?',
      );
    }
  }

  double _eval(String src) {
    final r = robot;
    if (r != null) {
      vars['wall'] = r.wallAhead ? 1.0 : 0.0;
      vars['lava'] = r.lavaAhead ? 1.0 : 0.0;
      vars['goal'] = r.atExit ? 1.0 : 0.0;
    }
    return ExprParser.parse(src).eval(vars);
  }

  Future<void> _block(List<Stmt> stmts) async {
    for (final s in stmts) {
      await _exec(s);
    }
  }

  Future<void> _exec(Stmt s) async {
    _guard();
    onHighlight?.call(s.id);

    final d = delayMs();
    if (d > 0) {
      await Future<void>.delayed(Duration(milliseconds: d));
    } else if (_steps % 100 == 0) {
      await Future<void>.delayed(Duration.zero); // let the UI breathe
    }
    if (_stopped) throw StoppedSignal();

    switch (s) {
      case MoveStmt m:
        _turtle().move(_eval(m.distance));
      case TurnStmt t:
        _turtle().turn(_eval(t.degrees));
      case PenStmt p:
        _turtle().setPen(p.down);
      case ColorStmt c:
        _turtle().setColor(Color(c.colorValue));
      case SetVarStmt v:
        final name = v.name.trim();
        if (name.isEmpty)
          throw LangError('A "set" block needs a variable name');
        vars[name] = _eval(v.value);
      case PrintStmt p:
        onPrint?.call(_fmt(_eval(p.value)));
      case StepStmt():
        _robot().step(_animMs());
      case TurnDirStmt t:
        _robot().turn(t.right, _animMs());
      case RepeatStmt r:
        final n = _eval(r.times).floor();
        for (var i = 0; i < n; i++) {
          _guard();
          await _block(r.body);
        }
      case WhileStmt w:
        while (_eval(w.cond) != 0) {
          _guard();
          await _block(w.body);
        }
      case IfStmt i:
        await _block(_eval(i.cond) != 0 ? i.thenBody : i.elseBody);
    }
  }

  String _fmt(double v) {
    if (v.isFinite && v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
}
