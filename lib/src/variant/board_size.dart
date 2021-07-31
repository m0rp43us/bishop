part of 'variant.dart';

class BoardSize {
  final int h;
  final int v;
  int get numSquares => h * v;
  int get minDim => min(h, v);
  int get maxDim => max(h, v);
  int get maxRank => v - 1;
  int get maxFile => h - 1;
  int get north => h * 2;
  const BoardSize(this.h, this.v);
  factory BoardSize.standard() => BoardSize(8, 8);
}
