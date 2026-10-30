import 'ast.dart';

/// Turns the block tree into runnable Python (turtle module).
String toPython(List<Stmt> program) {
  final out = StringBuffer()
    ..writeln('import turtle')
    ..writeln()
    ..writeln('t = turtle.Turtle()')
    ..writeln('t.left(90)  # BlockCode turtle starts facing up')
    ..writeln();

  void emit(List<Stmt> list, int depth) {
    final pad = '    ' * depth;
    if (list.isEmpty) {
      out.writeln('${pad}pass');
      return;
    }
    for (final s in list) {
      switch (s) {
        case MoveStmt m:
          out.writeln('${pad}t.forward(${m.distance})');
        case TurnStmt t:
          out.writeln('${pad}t.right(${t.degrees})');
        case PenStmt p:
          out.writeln(p.down ? '${pad}t.pendown()' : '${pad}t.penup()');
        case ColorStmt c:
          final hex = (c.colorValue & 0xFFFFFF)
              .toRadixString(16)
              .padLeft(6, '0');
          out.writeln('${pad}t.color("#$hex")');
        case SetVarStmt v:
          out.writeln('$pad${v.name.trim()} = ${v.value}');
        case PrintStmt p:
          out.writeln('${pad}print(${p.value})');
        case RepeatStmt r:
          out.writeln('${pad}for _ in range(int(${r.times})):');
          emit(r.body, depth + 1);
        case WhileStmt w:
          out.writeln('${pad}while ${w.cond}:');
          emit(w.body, depth + 1);
        case IfStmt i:
          out.writeln('${pad}if ${i.cond}:');
          emit(i.thenBody, depth + 1);
          if (i.elseBody.isNotEmpty) {
            out.writeln('${pad}else:');
            emit(i.elseBody, depth + 1);
          }
      }
    }
  }

  emit(program, 0);
  out
    ..writeln()
    ..writeln('turtle.done()');
  return out.toString();
}
