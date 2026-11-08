import 'expr.dart';

int _idCounter = 0;
String _newId() => 'b${_idCounter++}';

/// Pen colors a user can cycle through (ARGB ints keep this file Flutter-free).
const penColorValues = <int>[
  0xFF22E5FF,
  0xFFFF3DCB,
  0xFFB6FF3B,
  0xFFFFC53D,
  0xFF9B5CFF,
  0xFFFFFFFF,
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
      'step' => StepStmt(),
      'rturn' => TurnDirStmt(j['r'] as bool),
      'repeat' => RepeatStmt(j['n'] as String, list(j['body'])),
      'while' => WhileStmt(j['c'] as String, list(j['body'])),
      'if' => IfStmt(j['c'] as String, list(j['then']), list(j['else'])),
      _ => throw LangError('Unknown block type "${j['t']}"'),
    };
  }
}

// ---- Sandbox (turtle drawing) blocks ----

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
  ColorStmt([this.colorValue = 0xFF22E5FF]);
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

// ---- Quest (robot) blocks ----

/// Move the bot one tile forward.
class StepStmt extends Stmt {
  StepStmt();
  @override
  Map<String, dynamic> toJson() => {'t': 'step'};
}

/// Turn the bot 90 degrees left or right.
class TurnDirStmt extends Stmt {
  TurnDirStmt([this.right = true]);
  bool right;
  @override
  Map<String, dynamic> toJson() => {'t': 'rturn', 'r': right};
}

// ---- Control flow ----

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

/// How many blocks a program uses (nested ones count too). Used for stars.
int countBlocks(List<Stmt> list) {
  var n = 0;
  for (final s in list) {
    n += 1;
    for (final c in s.children) {
      n += countBlocks(c);
    }
  }
  return n;
}
