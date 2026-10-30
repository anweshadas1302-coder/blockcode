import 'package:blockcode/core/ast.dart';
import 'package:blockcode/core/codegen.dart';
import 'package:blockcode/core/expr.dart';
import 'package:blockcode/core/interpreter.dart';
import 'package:blockcode/features/stage/turtle_state.dart';
import 'package:flutter_test/flutter_test.dart';

Interpreter makeInterp(TurtleState t, {List<String>? out}) =>
    Interpreter(turtle: t, delayMs: () => 0, onPrint: out?.add);

void main() {
  group('expressions', () {
    test('operator precedence', () {
      expect(ExprParser.parse('2 + 3 * 4').eval({}), 14);
      expect(ExprParser.parse('(2 + 3) * 4').eval({}), 20);
      expect(ExprParser.parse('-3 + 5').eval({}), 2);
    });

    test('variables and comparisons', () {
      expect(ExprParser.parse('x * 2').eval({'x': 4}), 8);
      expect(ExprParser.parse('x < 5').eval({'x': 4}), 1);
      expect(ExprParser.parse('x == 5').eval({'x': 4}), 0);
    });

    test('errors are LangErrors', () {
      expect(() => ExprParser.parse('2 +').eval({}), throwsA(isA<LangError>()));
      expect(() => ExprParser.parse('y').eval({}), throwsA(isA<LangError>()));
      expect(
        () => ExprParser.parse('1 / 0').eval({}),
        throwsA(isA<LangError>()),
      );
    });
  });

  group('interpreter', () {
    test('square returns the turtle to the start', () async {
      final t = TurtleState();
      await makeInterp(t).run([
        RepeatStmt('4', [MoveStmt('100'), TurnStmt('90')]),
      ]);
      expect(t.segments.length, 4);
      expect(t.x, closeTo(0, 1e-9));
      expect(t.y, closeTo(0, 1e-9));
    });

    test('variables update inside loops', () async {
      final t = TurtleState();
      final interp = makeInterp(t);
      await interp.run([
        SetVarStmt('x', '1'),
        RepeatStmt('4', [SetVarStmt('x', 'x * 2')]),
      ]);
      expect(interp.vars['x'], 16);
    });

    test('if / else picks the right branch', () async {
      final out = <String>[];
      await makeInterp(TurtleState(), out: out).run([
        SetVarStmt('x', '3'),
        IfStmt('x > 5', [PrintStmt('1')], [PrintStmt('2')]),
      ]);
      expect(out, ['2']);
    });

    test('infinite loop is stopped with a friendly error', () async {
      final interp = makeInterp(TurtleState());
      expect(interp.run([WhileStmt('1 > 0')]), throwsA(isA<LangError>()));
    });

    test('pen up draws nothing', () async {
      final t = TurtleState();
      await makeInterp(t).run([PenStmt(false), MoveStmt('50')]);
      expect(t.segments, isEmpty);
      expect(t.y, closeTo(-50, 1e-9));
    });
  });

  group('serialization & codegen', () {
    test('json round trip keeps nesting', () {
      final original = RepeatStmt('3', [
        IfStmt('1', [MoveStmt('10')], []),
      ]);
      final copy = Stmt.fromJson(original.toJson()) as RepeatStmt;
      expect(copy.times, '3');
      expect((copy.body.first as IfStmt).thenBody.length, 1);
    });

    test('python output contains a for loop', () {
      final code = toPython([
        RepeatStmt('4', [MoveStmt('100')]),
      ]);
      expect(code, contains('for _ in range(int(4)):'));
      expect(code, contains('t.forward(100)'));
    });
  });
}
