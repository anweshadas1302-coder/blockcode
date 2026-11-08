# 🧩 BlockCode

**A Scratch-style visual programming playground built with Flutter and Dart.**
Drag blocks together, press Run, and watch a custom interpreter execute your program step by step.

![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.6+-0175C2?logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/tests-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

<!-- Add a demo GIF here once the UI is done: -->
<!-- ![BlockCode demo](docs/demo.gif) -->

---

## ✨ Features

- 🧱 **Visual blocks**: move, turn, pen, color, repeat, while, if/else, variables, print
- ⚙️ **Custom interpreter**: written from scratch in Dart, no external parsing libraries
- 🔦 **Live execution highlighting**: the running block lights up as the program steps through
- 🐢 **Turtle graphics stage**: drawings render on a `CustomPainter` canvas
- 🧮 **Expression parser**: type things like `size + 3` or `(a + b) * 2` directly in blocks
- 🐍 **Code export**: converts your blocks to runnable Python (turtle module)
- 🛡️ **Safe execution**: step limit catches infinite loops and shows a friendly error
- 💾 **Save and load**: programs are stored as JSON
- ✅ **Unit tested**: parser, interpreter, serialization and code generation

---

## 🏗️ How it works

```
 Blocks (UI)  ──►  AST (Dart objects)  ──►  Interpreter  ──►  Turtle stage
                          │
                          └──►  Code generator  ──►  Python
```

1. **Blocks are the AST.** Each block is a Dart class (`RepeatStmt`, `MoveStmt`, ...), so there is no separate conversion step.
2. **Expressions are parsed on demand** by a recursive-descent parser (`expr.dart`) with proper operator precedence.
3. **The interpreter is async**, so the UI can repaint between steps and highlight the active block.
4. **A step guard** stops runaway programs instead of freezing the app.

### Grammar

```
comparison := additive (("<="|">="|"=="|"!="|"<"|">") additive)?
additive   := term (("+"|"-") term)*
term       := unary (("*"|"/"|"%") unary)*
unary      := "-" unary | primary
primary    := number | identifier | "(" comparison ")"
```

---

## 📁 Project structure

```
lib/
├── main.dart                      # app entry, neon dark theme
├── core/                          # pure language logic
│   ├── expr.dart                  # expression parser + evaluator
│   ├── ast.dart                   # block (statement) classes + JSON
│   ├── interpreter.dart           # async executor + bot sensors
│   └── codegen.dart               # AST → Python
├── game/                          # Quest mode engine
│   ├── level.dart                 # 7 puzzle levels (text maps)
│   ├── robot_world.dart           # bot position, gems, lava, sensors
│   ├── board_view.dart            # animated neon board (CustomPainter)
│   └── progress.dart              # saved stars + level unlocking
├── features/
│   ├── home/                      # title screen + level select
│   ├── game/                      # Quest level screen
│   ├── editor/                    # drag-and-drop block editor
│   │   ├── block_widget.dart      # glowing blocks + drop zones
│   │   ├── palette.dart           # block menu (filtered per level)
│   │   ├── editor_parts.dart      # run toolbar, workspace, palette bar
│   │   ├── editor_page.dart       # Sandbox screen
│   │   └── program_controller.dart
│   └── stage/                     # Sandbox turtle drawing
│       ├── turtle_state.dart
│       └── stage_view.dart
└── ui/                            # shared theme
    ├── block_colors.dart          # neon palette + glow helpers
    └── neon_background.dart       # animated background
test/
├── interpreter_test.dart          # parser, interpreter, codegen
└── quest_test.dart                # all 7 levels solved at par
```
---

## 🚀 Getting started

```bash
git clone https://github.com/anweshadas1302-coder/blockcode.git
cd blockcode
flutter pub get
flutter test
flutter run -d chrome
```

Requires Flutter 3.27 or newer.

---

## 🧪 Example program

A square, built from blocks:

```
repeat 4 times
    move 100 steps
    turn 90 degrees
```

Exported Python:

```python
import turtle

t = turtle.Turtle()
t.left(90)

for _ in range(int(4)):
    t.forward(100)
    t.right(90)

turtle.done()
```

---

## 🗺️ Roadmap

- [x] Expression parser with operator precedence
- [x] AST and JSON serialization
- [x] Async interpreter with step limit
- [x] Python code generation
- [x] Unit tests
- [ ] Turtle stage renderer
- [ ] Drag-and-drop block editor *(in progress)*
- [ ] Save and load programs
- [ ] User-defined functions
- [ ] Challenge mode with star ratings
- [ ] Undo / redo
- [ ] Flutter Web live demo

---

## 🛠️ Tech stack

Flutter · Dart 3 (sealed classes, pattern matching) · CustomPainter · ChangeNotifier · shared_preferences · flutter_test

---

## 👤 Author

**Anwesha Das**
[GitHub](https://github.com/anweshadas1302-coder)

---

## 📄 License

MIT
