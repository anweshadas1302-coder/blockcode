import 'package:flutter/material.dart';

import '../../core/ast.dart';
import '../../ui/block_colors.dart';
import 'program_controller.dart';

class PaletteItem {
  const PaletteItem(this.label, this.color, this.icon, this.create);
  final String label;
  final Color color;
  final IconData icon;
  final Stmt Function() create;
}

final paletteItems = <PaletteItem>[
  PaletteItem('move', motionColor, Icons.arrow_upward, () => MoveStmt()),
  PaletteItem('turn', motionColor, Icons.rotate_right, () => TurnStmt()),
  PaletteItem('pen up/down', looksColor, Icons.edit, () => PenStmt()),
  PaletteItem('pen color', looksColor, Icons.palette, () => ColorStmt()),
  PaletteItem('repeat', controlColor, Icons.repeat, () => RepeatStmt()),
  PaletteItem('while', controlColor, Icons.loop, () => WhileStmt()),
  PaletteItem('if / else', controlColor, Icons.call_split, () => IfStmt()),
  PaletteItem('set variable', dataColor, Icons.data_object, () => SetVarStmt()),
  PaletteItem('print', dataColor, Icons.terminal, () => PrintStmt()),
];

class _Chip extends StatelessWidget {
  const _Chip(this.item);
  final PaletteItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            item.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tap a chip to append the block, or long-press and drag it to an exact spot.
class PaletteView extends StatelessWidget {
  const PaletteView({super.key, required this.ctrl, this.axis = Axis.vertical});
  final ProgramController ctrl;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: axis,
      padding: const EdgeInsets.all(8),
      itemCount: paletteItems.length,
      separatorBuilder: (context, index) => const SizedBox(width: 8, height: 8),
      itemBuilder: (context, i) {
        final item = paletteItems[i];
        return Align(
          alignment: Alignment.centerLeft,
          child: LongPressDraggable<Object>(
            data: item,
            feedback: Material(color: Colors.transparent, child: _Chip(item)),
            child: GestureDetector(
              onTap: () =>
                  ctrl.insert(item.create(), ctrl.program, ctrl.program.length),
              child: _Chip(item),
            ),
          ),
        );
      },
    );
  }
}
