import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHelp());
  }

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _maybeShowHelp() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seen_help') ?? false) return;
    await prefs.setBool('seen_help', true);
    if (mounted) _showHelp();
  }

  void _showHelp() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('How BlockCode works'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HelpStep(
                icon: Icons.touch_app,
                title: '1. Build',
                text:
                    'Tap a block at the bottom to add it, or long-press and drag it '
                    'to an exact spot. Drop blocks inside "repeat" or "if" to put '
                    'them in a loop.',
              ),
              _HelpStep(
                icon: Icons.play_arrow,
                title: '2. Run',
                text:
                    'The computer reads your blocks from top to bottom, one at a '
                    'time. The block with the yellow border is the one running now.',
              ),
              _HelpStep(
                icon: Icons.navigation,
                title: '3. Watch the turtle',
                text:
                    'The green triangle is a turtle. "move" walks it forward and '
                    'draws a line. "turn" rotates it clockwise. It starts in the '
                    'middle, facing up.',
              ),
              _HelpStep(
                icon: Icons.repeat,
                title: '4. Loops and variables',
                text:
                    '"repeat" runs its blocks many times. "set variable" stores a '
                    'number you can reuse, like  size + 5.',
              ),
              _HelpStep(
                icon: Icons.auto_awesome,
                title: 'Try this',
                text:
                    'Open the sparkle menu for ready-made examples. To draw a '
                    'closed shape, the turns must add up to 360: repeat 8 times, '
                    'move 100, turn 45 makes an octagon.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
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
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How it works',
            onPressed: _showHelp,
          ),
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
            tooltip: 'Show Python code',
            onPressed: _showCode,
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              switch (v) {
                case 'save':
                  await ctrl.save();
                  if (mounted) _snack('Saved');
                case 'load':
                  final ok = await ctrl.load();
                  if (mounted) _snack(ok ? 'Loaded' : 'Nothing saved yet');
                case 'clear':
                  ctrl.clearAll();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'save', child: Text('Save program')),
              PopupMenuItem(value: 'load', child: Text('Load program')),
              PopupMenuItem(value: 'clear', child: Text('Clear all blocks')),
            ],
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
              SizedBox(height: 240, child: StageView(turtle: ctrl.turtle)),
              SizedBox(height: 60, child: _Console(ctrl: ctrl)),
              const SizedBox(height: 4),
              Expanded(child: _Workspace(ctrl: ctrl)),
              _PaletteBar(ctrl: ctrl),
            ],
          );
        },
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  const _HelpStep({
    required this.icon,
    required this.title,
    required this.text,
  });
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteBar extends StatelessWidget {
  const _PaletteBar({required this.ctrl});
  final ProgramController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tap a block to add it  -  long-press and drag to place it',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            SizedBox(
              height: 60,
              child: PaletteView(ctrl: ctrl, axis: Axis.horizontal),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.ctrl});
  final ProgramController ctrl;

  @override
  Widget build(BuildContext context) {
    const small = TextStyle(fontSize: 11, color: Colors.grey);
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
              tooltip: 'Clear the drawing',
              onPressed: ctrl.clearStage,
            ),
            const SizedBox(width: 4),
            const Text('slow', style: small),
            Expanded(
              child: Slider(value: ctrl.speed, onChanged: ctrl.setSpeed),
            ),
            const Text('fast', style: small),
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
                child: const Row(
                  children: [
                    Icon(Icons.flag, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'when Run is pressed',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (ctrl.program.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Text(
                    'Your program is empty.\nTap a block below to add it, or open '
                    'the sparkle menu for an example. Then press Run.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
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
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ctrl.console.isEmpty
            ? const Text(
                '> output from "print" blocks appears here',
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
