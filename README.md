Country Coder is a lightweight package that looks up region identifiers for geographic points
without calling a server. It can code and convert between several common IDs:

- 🆎 [ISO 3166-1 alpha-2 code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) (`ZA`)
- 🔤 [ISO 3166-1 alpha-3 code](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) (`ZAF`)
- 3️⃣ [ISO 3166-1 numeric-3 code](https://en.wikipedia.org/wiki/ISO_3166-1_numeric) (`710`)
- 3️⃣ [United Nations M49 code](https://en.wikipedia.org/wiki/UN_M49) (`710`)
- 🌐 [Wikidata QID](https://www.wikidata.org/wiki/Q43649390) (`Q258`)
- 🇺🇳 [Emoji flag](https://en.wikipedia.org/wiki/Regional_Indicator_Symbol) (🇿🇦)
- 💻 [ccTLD (country code top-level domain)](https://en.wikipedia.org/wiki/Country_code_top-level_domain) (`.za`)

In addition to identifiers, Country Coder can provide basic regional information:

- ☎️ [Telephone Calling Codes](https://en.wikipedia.org/wiki/List_of_country_calling_codes) (+44)
- 🛣 [Driving Side](https://en.wikipedia.org/wiki/Left-_and_right-hand_traffic) (right, left)
- 🚗 [Traffic Speed Unit](https://en.wikipedia.org/wiki/Speed_limit#Signage) (km/h, mph)
- 🚚 [Vehicle Height Unit](https://wiki.openstreetmap.org/wiki/Key:maxheight) (m, ft)
- 🇪🇺 [European Union Membership](https://en.wikipedia.org/wiki/Member_state_of_the_European_Union)

## This Is A Port

The original country coder and its data file was written by Quincy Morgan and Bryan Housel.
See [its documentaion](https://github.com/ideditor/country-coder) for function reference
and general description of what it can and cannot do.

Note that `feature` in function names here was replaced with `region`. For example, instead
of `featuresIn()`, the `CountryCoder` class has `regionsIn`.

Also, geometries are not stored in `RegionFeature` objects that some of the methods return.
This means, you get full information on a region, but not its boundaries.

## Usage

You do not instantiate a `CountryCoder`, but use a static `instance` property.
You should call `load()` once to initialize the instance. There is an option for
asynchronous loading via `prepareData()` (see the API reference).

```dart
final countries = CountryCoder.instance;
countries.load(); // initialize the instance, does nothing the second time

// Find a country's 2-letter ISO code by longitude and latitude
final String? code = countries.iso1A2Code(lon: -4.5, lat: 54.2);

// Get a full info on a country
final gb = countries.region(query: 'UK');
assert(gb == countries.region(query: '.uk'));
assert(gb == countries.region(lon: -4.5, lat: 54.2));

// Specify level if you need a sub-territory
final im = countries.region(lon: -4.0, lat: 54.2, level: RegionLevel.territory);
assert(im.name == 'Isle of Man');

// Useful convenience methods!
assert(!countries.isInEuropeanUnion(query: 'GB'));

// Which is equivalent to
assert(countries.isIn(query: 'DE', outer: 'EU'));

// And some country info
assert(countries.drivingSide(query: 'UK') != countries.drivingSide(query: 'CH'));
```

## Location Matcher

When you have objects associated with groups of countries, you define these via a
`LocationSet`. Usually you don't instantiate it, but read from a GeoJSON property.
For a description of the `locationSet` structure, see the
[location-conflation](https://github.com/ideditor/location-conflation#what-is-it)
library documentation. All the features are supported, but this class does not produce
any geometries.

Use it like this:

```dart
// You can pass additional GeoJSON features, with ids ending in ".geojson"
final matcher = LocationMatcher(features);

final locationSet = LocationSet.fromJson({
  'includes': ['uk'],
  'excludes': ['im', [0.3, 51.5, 60]]
});

bool inLondon = matcher(-0.11, 51.51, locationSet); // false
bool inSheffield = matcher(-1.46, 53.28, locationSet); // true
```

## Point-in-Polygon Index

This library also includes a fast lookup engine for polygons containing a point or intersecting
a bounding box. Its data structures are loosely based on GeoJSON geometries. In fact, passing
a features list from a GeoJSON's `FeatureCollection` is the primary mode of its operation:

```dart
final features = [
  {
    'geometry': {'type': 'Polygon', 'coordinates': [[[...]]]},
    'properties': {'id': 1, 'name': 'Something'}
  },
  {
    'geometry': {'type': 'MultiPolygon', 'coordinates': [[[...]]]},
    'properties': {'id': 2, 'name': 'Another one'}
  },
];

final query = WhichPolygon(features);

// Query the smallest polygon at a (longitude, latitude) location
final name = query(-30, 41)?['name'];

// Query all polygons at a location
final names = query.all(-30, 41).map((p) => p['name']).toList();

// Query polygons in a bounding box
final inBBox = query.bbox(-30, 41, -28, 51).length;
```

## Upstream

This library is a straight-up port of several JavaScript libraries:

* [country-coder 5.0.3](https://github.com/ideditor/country-coder) by Quincy Morgan and Bryan Housel, ISC license.
* [which-polygon 2.2.0](https://github.com/mapbox/which-polygon) by Vladimir Agafonkin, ISC license.
* [lineclip 1.1.5](https://github.com/mapbox/lineclip) by Vladimir Agafonkin, ISC license.