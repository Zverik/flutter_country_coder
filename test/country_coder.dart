import 'package:country_coder/country_coder.dart';
import 'package:test/test.dart';

void main() {
  final query = CountryCoder.instance;

  test('Initial instance is not initialized', () {
    expect(query.ready, isFalse);
  });

  test('Method throw an exception when not initialized', () {
    expect(() => query.iso1A2Code(query: 'Russia'), throwsStateError);
  });

  test('Can load data asynchronously', () async {
    await query.loadAsync();
    expect(query.ready, isTrue);
  });

  test('Processes basic string queries', () {
    expect(query.iso1A2Code(query: 'uk'), equals('GB'));
    expect(query.iso1A2Code(query: 'Russia'), equals('RU'));
    expect(query.region(query: 'NZ-CIT')?.country, equals('NZ'));
  });

  test('Processes numeric queries', () {
    expect(query.iso1A2Code(query: 191), equals('HR'));
    expect(query.ccTLD(query: 70), equals('.ba'));
    expect(query.region(query: 1)?.nameEn, equals('World'));
  });

  test('There is nothing at sea', () {
    expect(query.region(lon: -40, lat: 30), isNull);
  });

  test('Finds regions by locations', () {
    expect(query.iso1A2Code(lon: 24.7, lat: 59.4), equals('EE'));
    expect(query.iso1A2Code(lon: 21, lat: 42.6), equals('XK'));
    expect(query.region(lon: 50, lat: -77)?.nameEn, equals('Antarctica'));
  });

  test('Smallest region is not the default (country) one', () {
    expect(query.region(lon: 35, lat: 45)?.nameEn, equals('Russia'));
    expect(query.smallestOrMatchingRegion(lon: 35, lat: 45)?.nameEn, equals('Crimea'));
  });

  // TODO: write more tests for the country coder
  // See https://github.com/ideditor/country-coder/blob/main/tests/country-coder.spec.ts
}
