import 'package:country_coder/which_polygon.dart';
import 'package:flutter/foundation.dart';
import 'package:test/test.dart';
import 'fixtures/overlapping.dart';
import 'fixtures/states.dart';

dynamic loadAsync(Map<String, dynamic> featureCollection) {
  return WhichPolygon(states['features'] as List<Map<String, dynamic>>).serialize();
}

void main() {
  final query = WhichPolygon(states['features'] as List<Map<String, dynamic>>);

  test('queries polygons with a point', () {
    expect(query(-100, 45)['name'], equals('South Dakota'));
    expect(query(-90, 30)['name'], equals('Louisiana'));
    expect(query(-50, 30), isNull);
  });

  test('queries polygons with a bbox', () {
    final result = query.bbox(-100, 45, -99.5, 45.5);
    expect(result, isNotEmpty);
    expect(result[0]['name'], equals('South Dakota'));

    final qq = query.bbox(-104.2, 44, -103, 45);
    final names = qq.map((e) => e['name']).toList();
    names.sort();
    expect(names.length, equals(2));
    expect(names, equals(['South Dakota', 'Wyoming']));
  });

  test('queries overlapping polygons with a point', () {
    final queryOver = WhichPolygon(overlapping['features'] as List<Map<String, dynamic>>);
    expect(queryOver.one(7.5, 7.5)['name'], equals('A'), reason: 'without multi option');
    expect(queryOver.all(7.5, 7.5), equals([{'name': 'A'}, {'name': 'B'}]), reason: 'with multi option');
    expect(queryOver(-10, 10), isNull);
  });

  test('can load data asynchronously', () async {
    final query = WhichPolygon.fromSerialized(await compute(loadAsync, states));
    expect(query(-90, 30)['name'], equals('Louisiana'));
  });
}
