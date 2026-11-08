import 'package:flutter/material.dart';

import '../../core/ast.dart';
import '../../ui/block_colors.dart';
import 'palette.dart';
import 'program_controller.dart';

/// A vertical list of blocks with a drop zone before, between and after them.
class BlockList extends StatelessWidget {
  const BlockList({super.key, required this.list, required this.ctrl});
  final List<Stmt> list;
  final ProgramController ctrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < list.length; i++) ...[
          DropSlot(list: list, index: i, ctrl: ctrl),
          BlockView(key: ValueKey(list[i].id), stmt: list[i], ctrl: ctrl),
        ],
        DropSlot(list: list, index: list.length, ctrl: ctrl, big: list.isEmpty),
      ],
    );
  }
}

/// Where a dragged block can land. Grows and glows while a block hovers.
class DropSlot extends StatelessWidget {
  const DropSlot({
    super.key,
    required this.list,
    required this.index,
    required this.ctrl,
    this.big = false,
  });
  final List<Stmt> list;
  final int index;
  final ProgramController ctrl;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DragTarget<Object>(
      onWillAcceptWithDetails: (d) => d.data is PaletteItem || d.data is Stmt,
      onAcceptWithDetails: (d) {
        final data = d.data;
        if (data is PaletteItem) {
          ctrl.insert(data.create(), list, index);
        } else if (data is Stmt) {
          ctrl.moveStmt(data, list, index);
        }
      },
      builder: (context, candidates, rejected) {
        final hot = candidates.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: hot ? 40 : (big ? 40 : 10),
          margin: const EdgeInsets.symmetric(vertical: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hot ? primary.withValues(alpha: 0.25) : null,
            borderRadius: BorderRadius.circular(8),
            border: hot ? Border.all(color: primary, width: 2) : null,
          ),
          child: (big && !hot)
              ? const Text(
                  'drop blocks here',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                )
              : null,
        );
      },
    );
  }
}

typedef _Nested = ({String? label, List<Stmt> list});

class _Spec {
  const _Spec(this.title, this.color, this.header, [this.nested = const []]);
  final String title;
  final Color color;
  final List<Widget> header;
  final List<_Nested> nested;
}

class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.stmt, required this.ctrl});
  final Stmt stmt;
  final ProgramController ctrl;

  _Spec _spec() {
    Widget t(String s) => Text(
      s,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );

    Widget p(String value, void Function(String) set, [double w = 64]) =>
        _Param(
          value: value,
          width: w,
          onChanged: (v) {
            set(v);
            ctrl.touch();
          },
        );

    return switch (stmt) {
      MoveStmt s => _Spec('move', motionColor, [
        t('move'),
        p(s.distance, (v) => s.distance = v),
        t('steps'),
      ]),
      TurnStmt s => _Spec('turn', motionColor, [
        t('turn'),
        p(s.degrees, (v) => s.degrees = v),
        t('degrees'),
      ]),
      StepStmt() => _Spec('move forward', motionColor, [t('move forward')]),
      TurnDirStmt s => _Spec('turn', motionColor, [
        t(s.right ? 'turn right' : 'turn left'),
      ]),
      PenStmt s => _Spec('pen', looksColor, [
        _Pill(s.down ? 'pen down' : 'pen up', () {
          s.down = !s.down;
          ctrl.touch();
        }),
      ]),
      ColorStmt s => _Spec('color', looksColor, [
        t('pen color'),
        GestureDetector(
          onTap: () {
            final i = penColorValues.indexOf(s.colorValue);
            s.colorValue = penColorValues[(i + 1) % penColorValues.length];
            ctrl.touch();
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(s.colorValue),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ]),
      SetVarStmt s => _Spec('set', dataColor, [
        t('set'),
        p(s.name, (v) => s.name = v, 56),
        t('to'),
        p(s.value, (v) => s.value = v, 90),
      ]),
      PrintStmt s => _Spec('print', dataColor, [
        t('print'),
        p(s.value, (v) => s.value = v, 110),
      ]),
      RepeatStmt s => _Spec(
        'repeat',
        controlColor,
        [t('repeat'), p(s.times, (v) => s.times = v), t('times')],
        [(label: null, list: s.body)],
      ),
      WhileStmt s => _Spec(
        'while',
        controlColor,
        [t('while'), p(s.cond, (v) => s.cond = v, 120)],
        [(label: null, list: s.body)],
      ),
      IfStmt s => _Spec(
        'if',
        controlColor,
        [t('if'), p(s.cond, (v) => s.cond = v, 120), t('then')],
        [(label: null, list: s.thenBody), (label: 'else', list: s.elseBody)],
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final spec = _spec();
    final active = ctrl.highlightId == stmt.id;

    final body = Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: spec.color,
        borderRadius: BorderRadius.circular(10),
        border: active
            ? Border.all(color: Colors.yellowAccent, width: 3)
            : null,
        boxShadow: const [
          BoxShadow(blurRadius: 2, offset: Offset(0, 1), color: Colors.black26),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: spec.header,
                ),
              ),
              InkWell(
                onTap: () => ctrl.remove(stmt),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18, color: Colors.white70),
                ),
              ),
            ],
          ),
          for (final n in spec.nested) ...[
            if (n.label != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  n.label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Container(
              margin: const EdgeInsets.only(left: 12, top: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: BlockList(list: n.list, ctrl: ctrl),
            ),
          ],
        ],
      ),
    );

    return LongPressDraggable<Object>(
      data: stmt,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: spec.color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            spec.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: body),
      child: body,
    );
  }
}

/// Small text box inside a block.
class _Param extends StatefulWidget {
  const _Param({required this.value, required this.onChanged, this.width = 64});
  final String value;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  State<_Param> createState() => _ParamState();
}

class _ParamState extends State<_Param> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: 34,
      child: TextField(
        controller: _c,
        onChanged: widget.onChanged,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        decoration: const InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.onTap);
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
