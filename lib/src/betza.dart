import 'constants.dart';
import 'move_definition.dart';
import 'utils.dart';

class Betza {
  static const Map<String, Direction> ATOMS = {
    'W': Direction(1, 0),
    'F': Direction(1, 1),
    'D': Direction(2, 0),
    'N': Direction(2, 1),
    'A': Direction(2, 2),
    'C': Direction(3, 1),
    'Z': Direction(3, 2),
    'H': Direction(3, 0),
    'G': Direction(3, 3),
  };
  static const List<String> SHORTHANDS = ['B', 'R', 'Q', 'K'];
  static const List<String> DIR_MODIFIERS = ['f', 'b', 'r', 'l', 'v', 's', 'h'];
  static const List<String> FUNC_MODIFIERS = [
    'n', // 'lame'/blockable move, e.g. xiangqi knight
    'j',
    'i', // only allowed for first move of the piece, e.g. pawn double move
    'e', // en-passant
  ];
  static const Map<String, int> MODALITIES = {
    'm': Modality.QUIET,
    'c': Modality.CAPTURE,
  };

  static List<Atom> parse(String string) {
    List<Atom> atoms = [];

    List<String> chars = string.split('');
    List<String> _atoms = [];
    List<String> _dirs = [];
    List<String> _funcs = [];
    int range = 1;
    int modality = Modality.BOTH;

    void add() {
      for (String a in _atoms) {
        Atom atom = Atom(
          base: a,
          dirMods: _dirs,
          funcMods: _funcs,
          range: range,
          modality: modality,
        );
        atoms.add(atom);
      }
      _atoms = [];
      _dirs = [];
      _funcs = [];
      range = 1;
      modality = Modality.BOTH;
    }

    for (String c in chars) {
      if (isNumeric(c)) {
        range = int.parse(c);
      }
      if (_atoms.isNotEmpty) {
        add();
      }

      if (DIR_MODIFIERS.contains(c)) _dirs.add(c);
      if (FUNC_MODIFIERS.contains(c)) _funcs.add(c);
      if (MODALITIES.containsKey(c)) modality = MODALITIES[c]!;
      if (ATOMS.containsKey(c)) _atoms.add(c);
      if (SHORTHANDS.contains(c)) {
        if (c != 'K') range = 0;
        if (c != 'R') _atoms.add('F');
        if (c != 'B') _atoms.add('W');
      }
    }

    if (_atoms.isNotEmpty) add();

    return atoms;
  }
}

class Atom {
  final String base;
  final List<String> dirMods;
  final List<String> funcMods;
  final int range;
  final int modality;

  Atom({
    required this.base,
    this.dirMods = const [],
    this.funcMods = const [],
    this.range = 1,
    this.modality = Modality.BOTH,
  });

  bool get firstOnly => funcMods.contains('i');
  bool get enPassant => funcMods.contains('e');
  bool get lame => funcMods.contains('n');
  bool get quiet => modality == Modality.BOTH || modality == Modality.QUIET;
  bool get capture => modality == Modality.BOTH || modality == Modality.CAPTURE;

  List<Direction> get directions {
    Direction baseDir = Betza.ATOMS[base]!;
    int h = baseDir.h;
    int v = baseDir.v;
    bool allDirs = dirMods.isEmpty;
    List<Direction> dirs = [];
    if (baseDir.orthogonal) {
      int m = h == 0 ? v : h;
      if (allDirs || dirMods.contains('f') || dirMods.contains('v')) dirs.add(Direction(0, m));
      if (allDirs || dirMods.contains('b') || dirMods.contains('v')) dirs.add(Direction(0, -m));
      if (allDirs || dirMods.contains('r') || dirMods.contains('s')) dirs.add(Direction(m, 0));
      if (allDirs || dirMods.contains('l') || dirMods.contains('s')) dirs.add(Direction(-m, 0));
    }
    if (baseDir.diagonal) {
      bool vert = allDirs || dirMods.contains('v');
      bool side = allDirs || dirMods.contains('s');
      bool f = vert || dirMods.contains('f');
      bool b = vert || dirMods.contains('b');
      bool r = side || dirMods.contains('r');
      bool l = side || dirMods.contains('l');
      bool forward = f || !b;
      bool backward = b || !f;
      bool right = r || !l;
      bool left = l || !r;
      if (forward && right) dirs.add(Direction(h, v));
      if (forward && left) dirs.add(Direction(-h, v));
      if (backward && right) dirs.add(Direction(h, -v));
      if (backward && left) dirs.add(Direction(-h, -v));
    }
    if (baseDir.oblique) {
      // TODO: parse directional modifiers for oblique moves
      dirs.addAll(baseDir.permutations);
    }
    return dirs;
  }

  String get modalityString => modality == Modality.QUIET
      ? 'm'
      : modality == Modality.CAPTURE
          ? 'c'
          : '';
  String toString() => '$modalityString${dirMods.join('')}${funcMods.join('')}$base${range == 1 ? '' : range}';
}