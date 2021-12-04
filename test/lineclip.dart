import 'package:country_coder/which_polygon.dart';
import 'package:test/test.dart';

List<Point> toPoints(List<List<double>> coords) =>
    coords.map((e) => Point(e[0], e[1])).toList();

void main() {
  final clip = LineClip();

  test('clips line', () {
    final result = clip(toPoints([
      [-10, 10], [10, 10], [10, -10], [20, -10], [20, 10], [40, 10],
      [40, 20], [20, 20], [20, 40], [10, 40], [10, 20], [5, 20], [-10, 20]
    ]), BBox(0, 0, 30, 30));

    expect(result, equals([
      toPoints([[0, 10], [10, 10], [10, 0]]),
      toPoints([[20, 0], [20, 10], [30, 10]]),
      toPoints([[30, 20], [20, 20], [20, 30]]),
      toPoints([[10, 30], [10, 20], [5, 20], [0, 20]]),
    ]));
  });

  test('clips line crossing through many times', () {
    final result = clip(
        toPoints([[10, -10], [10, 30], [20, 30], [20, -10]]),
        BBox(0, 0, 20, 20)
    );

    expect(result, equals([
      toPoints([[10, 0], [10, 20]]),
      toPoints([[20, 20], [20, 0]]),
    ]));
  });

  test('clips polygon', () {
    final result = clip.polygon(toPoints([
      [-10, 10], [0, 10], [10, 10], [10, 5], [10, -5], [10, -10], [20, -10],
      [20, 10], [40, 10], [40, 20], [20, 20], [20, 40], [10, 40], [10, 20],
      [5, 20], [-10, 20]
    ]), BBox(0, 0, 30, 30));

    expect(result, equals(toPoints([
      [0, 10], [0, 10], [10, 10], [10, 5], [10, 0], [20, 0], [20, 10], [30, 10],
      [30, 20], [20, 20], [20, 30], [10, 30], [10, 20], [5, 20], [0, 20]
    ])));
  });

  test('appends result if passed third argument', () {
    final List<List<Point>> arr = [];
    final result = clip(toPoints([[-10, 10], [30, 10]]), BBox(0, 0, 20, 20), arr);

    expect(result, equals([toPoints([[0, 10], [20, 10]])]));
    expect(result, same(arr));
  });

  test('clips floating point lines', () {
    final line = toPoints([
      [-86.66015624999999, 42.22851735620852], [-81.474609375, 38.51378825951165], [-85.517578125, 37.125286284966776],
      [-85.8251953125, 38.95940879245423], [-90.087890625, 39.53793974517628], [-91.93359375, 42.32606244456202],
      [-86.66015624999999, 42.22851735620852]
    ]);
    final bbox = BBox(-91.93359375, 42.29356419217009, -91.7578125, 42.42345651793831);
    final result = clip(line, bbox);
    
    expect(result, equals([toPoints([
      [-91.91208030440808, 42.29356419217009],
      [-91.93359375, 42.32606244456202],
      [-91.7578125, 42.3228109416169]
    ])]));
  });

  test('preserves line if no protrusions exist', () {
    final result = clip(toPoints([[1, 1], [2, 2], [3, 3]]), BBox(0, 0, 30, 30));

    expect(result, equals([toPoints([[1, 1], [2, 2], [3, 3]])]));
  });

  test('clips without leaving empty parts', () {
    final result = clip(toPoints([[40, 40], [50, 50]]), BBox(0, 0, 30, 30));
    
    expect(result, isEmpty);
  });

  test('still works when polygon never crosses bbox', () {
    final result = clip.polygon(toPoints([
      [3, 3], [5, 3], [5, 5], [3, 5], [3, 3]
    ]), BBox(0, 0, 2, 2));

    expect(result, isEmpty);
  });
}
