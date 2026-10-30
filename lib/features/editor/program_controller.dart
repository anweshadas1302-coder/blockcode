import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/ast.dart';
import '../../core/expr.dart';
import '../../core/interpreter.dart';
import '../stage/turtle_state.dart';

/// Single source of truth for the editor: the program tree, run state,
/// console output and the turtle. (Swap for Riverpod/Bloc later if you like.)
class ProgramController extends ChangeNotifier {
  final List<Stmt> program = [];
  final TurtleState turtle = TurtleState();
  final List<String> console = [];

  String? highlightId;
  bool running = false;
  double speed = 0.6; // 0..1

  Interpreter? _interp;

  int get delayMs => ((1 - speed) * 400).round();

  void touch() => notifyListeners();

  void setSpeed(double v) {
    speed = v;
    notifyListeners();
  }

  // ---------- editing ----------

  void insert(Stmt s, List<Stmt> target, int index) {
    if (running) return;
    target.insert(index.clamp(0, target.length), s);
    notifyListeners();
  }

  void remove(Stmt s) {
    if (running) return;
    _findParent(program, s)?.remove(s);
    notifyListeners();
  }

  /// Move an existing block into [target] at [index] (refuses to drop a block
  /// inside itself, which would create a cycle).
  void moveStmt(Stmt s, List<Stmt> target, int index) {
    if (running) return;
    if (_subtreeHasList(s, target)) return;
    final oldList = _findParent(program, s);
    if (oldList == null) return;
    final oldIndex = oldList.indexOf(s);
    oldList.removeAt(oldIndex);
    var i = index;
    if (identical(oldList, target) && oldIndex < index) i--;
    target.insert(i.clamp(0, target.length), s);
    notifyListeners();
  }

  void clearAll() {
    if (running) return;
    program.clear();
    notifyListeners();
  }

  List<Stmt>? _findParent(List<Stmt> list, Stmt s) {
    if (list.contains(s)) return list;
    for (final c in list) {
      for (final l in c.children) {
        final r = _findParent(l, s);
        if (r != null) return r;
      }
    }
    return null;
  }

  bool _subtreeHasList(Stmt s, List<Stmt> target) {
    for (final l in s.children) {
      if (identical(l, target)) return true;
      for (final c in l) {
        if (_subtreeHasList(c, target)) return true;
      }
    }
    return false;
  }

  // ---------- running ----------

  Future<void> run() async {
    if (running) return;
    running = true;
    console.clear();
    turtle.reset();
    notifyListeners();

    final watch = Stopwatch()..start();
    final interp = Interpreter(
      turtle: turtle,
      delayMs: () => delayMs,
      onHighlight: (id) {
        highlightId = id;
        notifyListeners();
      },
      onPrint: (text) {
        console.add(text);
        notifyListeners();
      },
    );
    _interp = interp;

    try {
      await interp.run(program);
      console.add('Finished in ${watch.elapsedMilliseconds} ms');
    } on StoppedSignal {
      console.add('Stopped');
    } on LangError catch (e) {
      console.add('Error: ${e.message}');
    } finally {
      running = false;
      highlightId = null;
      _interp = null;
      notifyListeners();
    }
  }

  void stop() => _interp?.stop();

  void clearStage() {
    if (running) return;
    turtle.reset();
    console.clear();
    notifyListeners();
  }

  // ---------- examples ----------

  static final Map<String, List<Stmt> Function()> examples = {
    'Square': () => [
      RepeatStmt('4', [MoveStmt('100'), TurnStmt('90')]),
    ],
    'Star': () => [
      ColorStmt(0xFFE53935),
      RepeatStmt('5', [MoveStmt('120'), TurnStmt('144')]),
    ],
    'Spiral': () => [
      SetVarStmt('size', '3'),
      RepeatStmt('40', [
        MoveStmt('size'),
        TurnStmt('91'),
        SetVarStmt('size', 'size + 3'),
      ]),
    ],
    'Flower': () => [
      ColorStmt(0xFF8E24AA),
      RepeatStmt('36', [
        RepeatStmt('4', [MoveStmt('60'), TurnStmt('90')]),
        TurnStmt('10'),
      ]),
    ],
    'Countdown': () => [
      SetVarStmt('n', '5'),
      WhileStmt('n > 0', [PrintStmt('n'), SetVarStmt('n', 'n - 1')]),
      PrintStmt('0'),
    ],
  };

  void loadExample(String name) {
    if (running) return;
    program
      ..clear()
      ..addAll(examples[name]!());
    turtle.reset();
    console.clear();
    notifyListeners();
  }

  // ---------- persistence ----------

  static const _key = 'blockcode.program';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(program.map((s) => s.toJson()).toList()),
    );
  }

  Future<bool> load() async {
    if (running) return false;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return false;
    final loaded = (jsonDecode(raw) as List)
        .map((e) => Stmt.fromJson(e as Map<String, dynamic>))
        .toList();
    program
      ..clear()
      ..addAll(loaded);
    notifyListeners();
    return true;
  }
}
