/// A puzzle level. Map legend:
///   #  wall     .  floor    S  bot start (facing right)
///   E  exit     G  gem      L  lava
class Level {
  const Level({
    required this.title,
    required this.hint,
    required this.map,
    required this.par,
    required this.blocks,
    this.startDir = 1,
  });

  final String title;
  final String hint;
  final List<String> map;
  final int par; // fewest blocks needed = 3 stars
  final List<String> blocks; // palette ids allowed in this level
  final int startDir; // 0 = up, 1 = right, 2 = down, 3 = left

  int get rows => map.length;
  int get cols => map.first.length;
  int get gemTotal => map.fold(0, (n, row) => n + row.split('G').length - 1);
}

const levels = <Level>[
  Level(
    title: 'First Steps',
    hint: 'Walk the bot to the glowing exit. Grab the gem on the way!',
    par: 4,
    blocks: ['step'],
    map: ['#######', '#S.G.E#', '#######'],
  ),
  Level(
    title: 'Around the Bend',
    hint: 'Use "turn right" to change direction.',
    par: 6,
    blocks: ['step', 'left', 'right'],
    map: ['######', '#S..G#', '####.#', '####E#', '######'],
  ),
  Level(
    title: 'Loop It',
    hint: 'Too many steps? Put "move forward" inside a "repeat" block.',
    par: 2,
    blocks: ['step', 'left', 'right', 'repeat'],
    map: ['###########', '#S.G..G..E#', '###########'],
  ),
  Level(
    title: 'Staircase',
    hint: 'Spot the pattern: step, turn, step, turn. Then repeat it!',
    par: 5,
    blocks: ['step', 'left', 'right', 'repeat'],
    map: [
      '#######',
      '#S.####',
      '##.G###',
      '###..##',
      '####G.#',
      '#####E#',
      '#######',
    ],
  ),
  Level(
    title: 'Hot Lava',
    hint:
        'Sensors! "lava" is 1 when lava is right ahead. '
        'Try: while lava == 0',
    par: 5,
    blocks: ['step', 'left', 'right', 'repeat', 'while'],
    map: ['#######', '#SG..L#', '####G##', '####E##', '#######'],
  ),
  Level(
    title: 'Hallway Runner',
    hint:
        '"wall" is 1 when a wall is ahead. Walk until a wall, turn, '
        'and loop the whole thing.',
    par: 4,
    blocks: ['step', 'left', 'right', 'repeat', 'while'],
    map: [
      '########',
      '#S.G...#',
      '######.#',
      '######G#',
      '#E.....#',
      '########',
    ],
  ),
  Level(
    title: 'The Spiral',
    hint:
        'Wall hugger: if there is a wall ahead, turn right, otherwise '
        'step. Loop until goal == 1.',
    par: 4,
    blocks: ['step', 'left', 'right', 'repeat', 'while', 'if'],
    map: [
      '#########',
      '#S..G...#',
      '#######.#',
      '#.....#.#',
      '#.###G#.#',
      '#G#E..#.#',
      '#.#####.#',
      '#.......#',
      '#########',
    ],
  ),
];
