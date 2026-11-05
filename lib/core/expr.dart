/// Error shown to the user (bad expression, infinite loop, ...).
class LangError implements Exception {
  LangError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Expression tree. Booleans are numbers: 1 = true, 0 = false.
sealed class Expr {
  double eval(Map<String, double> vars);
}

class NumLit extends Expr {
  NumLit(this.value);
  final double value;
  @override
  double eval(Map<String, double> vars) => value;
}

class VarRef extends Expr {
  VarRef(this.name);
  final String name;
  @override
  double eval(Map<String, double> vars) =>
      vars[name] ??
      (throw LangError(
        'Variable "$name" has no value yet - use a "set" block first',
      ));
}

class BinOp extends Expr {
  BinOp(this.op, this.left, this.right);
  final String op;
  final Expr left, right;

  @override
  double eval(Map<String, double> vars) {
    final a = left.eval(vars);
    final b = right.eval(vars);
    return switch (op) {
      '+' => a + b,
      '-' => a - b,
      '*' => a * b,
      '/' => b == 0 ? throw LangError('Division by zero') : a / b,
      '%' => b == 0 ? throw LangError('Division by zero') : a % b,
      '<' => a < b ? 1.0 : 0.0,
      '>' => a > b ? 1.0 : 0.0,
      '<=' => a <= b ? 1.0 : 0.0,
      '>=' => a >= b ? 1.0 : 0.0,
      '==' => a == b ? 1.0 : 0.0,
      '!=' => a != b ? 1.0 : 0.0,
      _ => throw LangError('Unknown operator "$op"'),
    };
  }
}

/// Recursive-descent parser.
///
/// comparison := additive (("<="|">="|"=="|"!="|"<"|">") additive)?
/// additive   := term (("+"|"-") term)*
/// term       := unary (("*"|"/"|"%") unary)*
/// unary      := "-" unary | primary
/// primary    := number | identifier | "(" comparison ")"
class ExprParser {
  ExprParser._(this._src);
  final String _src;
  int _p = 0;

  static Expr parse(String source) {
    final parser = ExprParser._(source);
    final expr = parser._comparison();
    parser._ws();
    if (parser._p < source.length) {
      throw LangError('Unexpected "${source[parser._p]}" in "$source"');
    }
    return expr;
  }

  void _ws() {
    while (_p < _src.length && _src[_p] == ' ') {
      _p++;
    }
  }

  bool _match(String token) {
    _ws();
    if (_src.startsWith(token, _p)) {
      _p += token.length;
      return true;
    }
    return false;
  }

  Expr _comparison() {
    final left = _additive();
    for (final op in const ['<=', '>=', '==', '!=', '<', '>']) {
      if (_match(op)) return BinOp(op, left, _additive());
    }
    return left;
  }

  Expr _additive() {
    var left = _term();
    while (true) {
      if (_match('+')) {
        left = BinOp('+', left, _term());
      } else if (_match('-')) {
        left = BinOp('-', left, _term());
      } else {
        return left;
      }
    }
  }

  Expr _term() {
    var left = _unary();
    while (true) {
      if (_match('*')) {
        left = BinOp('*', left, _unary());
      } else if (_match('/')) {
        left = BinOp('/', left, _unary());
      } else if (_match('%')) {
        left = BinOp('%', left, _unary());
      } else {
        return left;
      }
    }
  }

  Expr _unary() {
    if (_match('-')) return BinOp('-', NumLit(0), _unary());
    return _primary();
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  bool _isAlpha(String c) {
    final u = c.codeUnitAt(0);
    return (u >= 65 && u <= 90) || (u >= 97 && u <= 122) || u == 95;
  }

  Expr _primary() {
    _ws();
    if (_p >= _src.length) {
      throw LangError('Expression ended too early: "$_src"');
    }
    if (_match('(')) {
      final inner = _comparison();
      if (!_match(')')) {
        throw LangError('Missing ")" in "$_src"');
      }
      return inner;
    }
    final start = _p;
    final c = _src[_p];
    if (_isDigit(c) || c == '.') {
      while (_p < _src.length && (_isDigit(_src[_p]) || _src[_p] == '.')) {
        _p++;
      }
      final text = _src.substring(start, _p);
      final value = double.tryParse(text);
      if (value == null) throw LangError('"$text" is not a number');
      return NumLit(value);
    }
    if (_isAlpha(c)) {
      while (_p < _src.length && (_isAlpha(_src[_p]) || _isDigit(_src[_p]))) {
        _p++;
      }
      return VarRef(_src.substring(start, _p));
    }
    throw LangError('Unexpected "$c" in "$_src"');
  }
}
