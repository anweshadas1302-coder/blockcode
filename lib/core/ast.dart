import 'expr.dart';

int _idCounter = 0;
String _newId() => 'b${_idCounter++}';

/// Colors a user can cycle through (ARGB ints keep this file Flutter-free).
const penColorValues = <int>[
  0xFF2196F3,
  0xFFE53935,
  0xFF43A047,
  0xFFFB8C00,
  0xFF8E24AA,
  0xFF212121,
];

/// One block = one statement. Parameters are stored as text and parsed by
/// [ExprParser] when executed, so users can type "size + 3".
sealed class Stmt {
  final String id = _newId();

  /// Nested statement lists (bodies of loops / branches).
  List<List<Stmt>> get children => const [];

  Map<String, dynamic> toJson();

  static Stmt fromJson(Map<String, dynamic> j) {
    List<Stmt> list(dynamic v) => ((v ?? <dynamic>[]) as List)
        .map((e) => Stmt.fromJson(e as Map<String, dynamic>))
        .toList();
    return switch (j['t']) {
      'move' => MoveStmt(j['a'] as String),
      'turn' => TurnStmt(j['a'] as String),
      'pen' => PenStmt(j['down'] as bool),
      'color' => ColorStmt(j['c'] as int),
      'set' => SetVarStmt(j['n'] as String, j['v'] as String),
      'print' => PrintStmt(j['v'] as String),
      'repeat' => RepeatStmt(j['n'] as String, list(j['body'])),
      'while' => WhileStmt(j['c'] as String, list(j['body'])),
      'if' => IfStmt(j['c'] as String, list(j['then']), list(j['else'])),
      _ => throw LangError('Unknown block type "${j['t']}"'),
    };
  }
}

class MoveStmt extends Stmt {
  MoveStmt([this.distance = '50']);
  String distance;
  @override
  Map<String, dynamic> toJson() => {'t': 'move', 'a': distance};
}

class TurnStmt extends Stmt {
  TurnStmt([this.degrees = '90']);
  String degrees;
  @override
  Map<String, dynamic> toJson() => {'t': 'turn', 'a': degrees};
}

class PenStmt extends Stmt {
  PenStmt([this.down = true]);
  bool down;
  @override
  Map<String, dynamic> toJson() => {'t': 'pen', 'down': down};
}

class ColorStmt extends Stmt {
  ColorStmt([this.colorValue = 0xFF2196F3]);
  int colorValue;
  @override
  Map<String, dynamic> toJson() => {'t': 'color', 'c': colorValue};
}

class SetVarStmt extends Stmt {
  SetVarStmt([this.name = 'x', this.value = '0']);
  String name;
  String value;
  @override
  Map<String, dynamic> toJson() => {'t': 'set', 'n': name, 'v': value};
}

class PrintStmt extends Stmt {
  PrintStmt([this.value = '1']);
  String value;
  @override
  Map<String, dynamic> toJson() => {'t': 'print', 'v': value};
}

class RepeatStmt extends Stmt {
  RepeatStmt([this.times = '4', List<Stmt>? body]) : body = body ?? [];
  String times;
  final List<Stmt> body;
  @override
  List<List<Stmt>> get children => [body];
  @override
  Map<String, dynamic> toJson() => {
    't': 'repeat',
    'n': times,
    'body': body.map((s) => s.toJson()).toList(),
  };
}

class WhileStmt extends Stmt {
  WhileStmt([this.cond = 'x < 10', List<Stmt>? body]) : body = body ?? [];
  String cond;
  final List<Stmt> body;
  @override
  List<List<Stmt>> get children => [body];
  @override
  Map<String, dynamic> toJson() => {
    't': 'while',
    'c': cond,
    'body': body.map((s) => s.toJson()).toList(),
  };
}

class IfStmt extends Stmt {
  IfStmt([this.cond = 'x > 0', List<Stmt>? thenBody, List<Stmt>? elseBody])
    : thenBody = thenBody ?? [],
      elseBody = elseBody ?? [];
  String cond;
  final List<Stmt> thenBody;
  final List<Stmt> elseBody;
  @override
  List<List<Stmt>> get children => [thenBody, elseBody];
  @override
  Map<String, dynamic> toJson() => {
    't': 'if',
    'c': cond,
    'then': thenBody.map((s) => s.toJson()).toList(),
    'else': elseBody.map((s) => s.toJson()).toList(),
  };
}
