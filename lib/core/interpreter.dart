import 'package:flutter/painting.dart' show Color;

import '../features/stage/turtle_state.dart';
import 'ast.dart';
import 'expr.dart';

/// Thrown internally when the user presses Stop.
class StoppedSignal implements Exception {}

/// Walks the statement tree. It is async so the UI can repaint between steps
/// and so we can highlight the block that is currently running.
class Interpreter {
  Interpreter({
    required this.turtle,
    required this.delayMs,
    this.onHighlight,
    this.onPrint,
    this.maxSteps = 50000,
  });

  final TurtleState turtle;
  final int Function() delayMs;
  final void Function(String? blockId)? onHighlight;
  final void Function(String text)? onPrint;
  final int maxSteps;

  final Map<String, double> vars = {};
  int _steps = 0;
  bool _stopped = false;

  void stop() => _stopped = true;

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

  double _eval(String src) => ExprParser.parse(src).eval(vars);

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
        turtle.move(_eval(m.distance));
      case TurnStmt t:
        turtle.turn(_eval(t.degrees));
      case PenStmt p:
        turtle.setPen(p.down);
      case ColorStmt c:
        turtle.setColor(Color(c.colorValue));
      case SetVarStmt v:
        final name = v.name.trim();
        if (name.isEmpty) {
          throw LangError('A "set" block needs a variable name');
        }
        vars[name] = _eval(v.value);
      case PrintStmt p:
        onPrint?.call(_fmt(_eval(p.value)));
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
