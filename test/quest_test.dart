import 'package:blockcode/core/ast.dart';
import 'package:blockcode/core/expr.dart';
import 'package:blockcode/core/interpreter.dart';
import 'package:blockcode/game/level.dart';
import 'package:blockcode/game/robot_world.dart';
import 'package:flutter_test/flutter_test.dart';

Future<RobotWorld> play(int level, List<Stmt> program) async {
  final world = RobotWorld(levels[level]);
  await Interpreter(robot: world, delayMs: () => 0).run(program);
  return world;
}

bool cleared(RobotWorld w) => w.atExit && w.gemsLeft == 0;

void main() {
  // One reference solution per level. Each must clear the level AND use
  // exactly the level's "par" number of blocks (that is what 3 stars means).
  final solutions = <List<Stmt> Function()>[
    () => [StepStmt(), StepStmt(), StepStmt(), StepStmt()],
    () => [
      StepStmt(),
      StepStmt(),
      StepStmt(),
      TurnDirStmt(true),
      StepStmt(),
      StepStmt(),
    ],
    () => [
      RepeatStmt('8', [StepStmt()]),
    ],
    () => [
      RepeatStmt('4', [
        StepStmt(),
        TurnDirStmt(true),
        StepStmt(),
        TurnDirStmt(false),
      ]),
    ],
    () => [
      WhileStmt('lava == 0', [StepStmt()]),
      TurnDirStmt(true),
      WhileStmt('goal == 0', [StepStmt()]),
    ],
    () => [
      RepeatStmt('3', [
        WhileStmt('wall == 0', [StepStmt()]),
        TurnDirStmt(true),
      ]),
    ],
    () => [
      WhileStmt('goal == 0', [
        IfStmt('wall == 1', [TurnDirStmt(true)], [StepStmt()]),
      ]),
    ],
  ];

  for (var i = 0; i < solutions.length; i++) {
    test('level ${i + 1} (${levels[i].title}) can be cleared at par', () async {
      final program = solutions[i]();
      final world = await play(i, program);
      expect(cleared(world), isTrue);
      expect(countBlocks(program), levels[i].par);
    });
  }

  test('every level has the same number of solutions as levels', () {
    expect(solutions.length, levels.length);
  });

  test('walking into a wall fails', () async {
    expect(
      play(0, [
        RepeatStmt('9', [StepStmt()]),
      ]),
      throwsA(isA<LangError>()),
    );
  });

  test('walking into lava fails and marks the bot dead', () async {
    final world = RobotWorld(levels[4]);
    final run = Interpreter(robot: world, delayMs: () => 0).run([
      RepeatStmt('5', [StepStmt()]),
    ]);
    await expectLater(run, throwsA(isA<LangError>()));
    expect(world.dead, isTrue);
  });

  test('turning changes the sensors', () async {
    final world = RobotWorld(levels[0]);
    expect(world.wallAhead, isFalse);
    world.turn(false, 1); // now facing up, into the wall
    expect(world.wallAhead, isTrue);
  });

  test('bot blocks are rejected without a robot', () async {
    expect(
      Interpreter(delayMs: () => 0).run([StepStmt()]),
      throwsA(isA<LangError>()),
    );
  });
}
