import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/codegen.dart';
import '../stage/stage_view.dart';
import 'block_widget.dart';
import 'palette.dart';
import 'program_controller.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final ctrl = ProgramController();

  @override
  void initState() {
    super.initState();
    ctrl.loadExample('Square');
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
  );

  void _showCode() {
    final code = toPython(ctrl.program);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Python equivalent',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  code,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BlockCode'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Examples',
            onSelected: ctrl.loadExample,
            itemBuilder: (_) => [
              for (final n in ProgramController.examples.keys)
                PopupMenuItem(value: n, child: Text(n)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Show code',
            onPressed: _showCode,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: () async {
              await ctrl.save();
              if (mounted) _snack('Saved');
            },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load',
            onPressed: () async {
              final ok = await ctrl.load();
              if (mounted) _snack(ok ? 'Loaded' : 'Nothing saved yet');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear blocks',
            onPressed: ctrl.clearAll,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth > 800;
          if (wide) {
            return Column(
              children: [
                _Toolbar(ctrl: ctrl),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(width: 170, child: PaletteView(ctrl: ctrl)),
                      Expanded(child: _Workspace(ctrl: ctrl)),
                      SizedBox(
                        width: 380,
                        child: Column(
                          children: [
                            Expanded(child: StageView(turtle: ctrl.turtle)),
                            SizedBox(height: 140, child: _Console(ctrl: ctrl)),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _Toolbar(ctrl: ctrl),
              SizedBox(height: 200, child: StageView(turtle: ctrl.turtle)),
              SizedBox(height: 64, child: _Console(ctrl: ctrl)),
              Expanded(child: _Workspace(ctrl: ctrl)),
              SizedBox(
                height: 64,
                child: PaletteView(ctrl: ctrl, axis: Axis.horizontal),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.ctrl});
  final ProgramController ctrl;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            FilledButton.icon(
              onPressed: () => ctrl.running ? ctrl.stop() : ctrl.run(),
              icon: Icon(ctrl.running ? Icons.stop : Icons.play_arrow),
              label: Text(ctrl.running ? 'Stop' : 'Run'),
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Clear stage',
              onPressed: ctrl.clearStage,
            ),
            const Icon(Icons.speed, size: 20),
            Expanded(
              child: Slider(value: ctrl.speed, onChanged: ctrl.setSpeed),
            ),
          ],
        ),
      ),
    );
  }
}

class _Workspace extends StatelessWidget {
  const _Workspace({required this.ctrl});
  final ProgramController ctrl;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                    bottom: Radius.circular(6),
                  ),
                ),
                child: const Text(
                  'when Run is pressed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              BlockList(list: ctrl.program, ctrl: ctrl),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _Console extends StatelessWidget {
  const _Console({required this.ctrl});
  final ProgramController ctrl;

  @override
  Widget build(BuildContext context) {
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 13,
      color: Colors.greenAccent,
    );
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ctrl.console.isEmpty
            ? const Text(
                '> output appears here',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              )
            : ListView(
                reverse: true,
                children: [
                  for (final line in ctrl.console.reversed)
                    Text('> $line', style: mono),
                ],
              ),
      ),
    );
  }
}
