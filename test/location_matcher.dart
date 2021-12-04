import 'package:country_coder/country_coder.dart';
import 'package:test/test.dart';
import 'fixtures/locset_features.dart';

void main() {
  CountryCoder.instance.load();
  final matcher = LocationMatcher(features);

  test('empty location set matches anywhere', () {
    expect(matcher(10, 10, LocationSet()), isTrue);
    expect(matcher(-100, 70, LocationSet()), isTrue);
    expect(matcher(60, 35, LocationSet()), isTrue);
  });

  test('exclude before include', () {
    final locSet = LocationSet.fromJson({
      'exclude': ['DE'],
      'include': ['EU']
    });
    expect(matcher(19.7, 52.3, locSet), isTrue, reason: 'Poland');
    expect(matcher(10.4, 53.1, locSet), isFalse, reason: 'Germany');
    expect(matcher(38, 53, locSet), isFalse, reason: 'Russia');
  });

  test('custom polygons work', () {
    final locSet = LocationSet.fromJson({
      'include': ['usa'],
      'exclude': ['philly_metro.geojson', 'dc_metro.geojson']
    });
    expect(matcher(-76.6, 39.3, locSet), isTrue, reason: 'Baltimore');
    expect(matcher(-77.0, 38.9, locSet), isFalse, reason: 'Washington, DC');
    expect(matcher(-75.2, 39.9, locSet), isFalse, reason: 'Philadelphia');
    expect(matcher(-75.2, 39.3, locSet), isTrue, reason: 'around');
    expect(matcher(-100.0, 24, locSet), isFalse, reason: 'Mexico');
  });

  test('circular areas, default radius is 25 km', () {
    final locSet = LocationSet.fromJson({
      'include': ['BRB', [18.55, 4.37]]
    });
    expect(matcher(18.5, 4.48, locSet), isTrue, reason: 'near center');
    expect(matcher(18.324, 4.371, locSet), isFalse, reason: '25.05 km west');
    expect(matcher(18.331, 4.371, locSet), isTrue, reason: '24.5 km west');
    expect(matcher(18.7357, 4.4973, locSet), isFalse, reason: '25.01 km northeast');
    expect(matcher(18.7353, 4.4972, locSet), isTrue, reason: '24.98 km northeast');
    expect(matcher(-59.54, 13.16, locSet), isTrue, reason: 'Barbados');
    expect(matcher(-61.2, 13.26, locSet), isFalse, reason: 'Saint Vincent');
  });
}