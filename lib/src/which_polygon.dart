// Port of https://github.com/mapbox/which-polygon v2.2.0
// Code mainly by Vladimir Agafonkin, ported by Ilya Zverev.
// Licensed ISC.

import 'package:rbush/rbush.dart';
import 'bbox.dart';
import 'lineclip.dart';
import 'dart:math' as math;

/// Index for matching points against a set of GeoJSON polygons.
class WhichPolygon<T> {
  final _tree = RBushBase<_TreeItem<T>>(
    toBBox: (item) => item,
    getMinX: (item) => item.minX,
    getMinY: (item) => item.minY,
  );

  /// Reads a GeoJSON-like collection of features, and
  /// stores all polygon and multipolygon geometries along
  /// with their properties in an r-tree.
  ///
  /// Note that properties can be of any type, marked with [T].
  /// Sometimes you might want to preprocess a feature stream like this:
  ///
  /// ```dart
  /// final query = WhichPolygon<MyData>(fc['features'].map((f) => {
  ///   'geometry': f['geometry'],
  ///   'properties': MyData.fromJson(f['properties']),
  /// });
  /// ```
  WhichPolygon(Iterable<Map<String, dynamic>> features) {
    final List<_TreeItem<T>> bboxes = [];
    for (final feature in features) {
      final Map<String, dynamic>? geom = feature['geometry'];
      if (geom == null || feature['properties'] == null) continue;

      if (feature['id'] != null && feature['properties'] is Map) {
        // Push id property into the properties map
        feature['properties']['id'] ??= feature['id'];
      }

      final List<dynamic> coords = geom['coordinates'];
      if (geom['type'] == 'Polygon') {
        bboxes.add(_TreeItem<T>(
          _Polygon.fromJson(coords),
          feature['properties'],
        ));
      } else if (geom['type'] == 'MultiPolygon') {
        for (final List<dynamic> polygon in coords) {
          bboxes.add(_TreeItem<T>(
            _Polygon.fromJson(polygon),
            feature['properties'],
          ));
        }
      }
    }
    _tree.load(bboxes);
  }

  /// Instantiates the class using an object from [serialize].
  factory WhichPolygon.fromSerialized(dynamic data) =>
      WhichPolygon<T>([]).._tree.data = data;

  /// Returns a serializable object that can be passed between threads.
  dynamic serialize() => _tree.data;

  /// Returns a single polygon matching the location. An alias for [one].
  T? call(double lon, double lat) => one(lon, lat);

  /// Returns a single polygon containing the ([lon], [lat]) location.
  /// Or `null` if nothing is found.
  T? one(double lon, double lat) {
    final point = Point(lon, lat);
    final result = _findInTree(point: point);
    for (final item in result) {
      if (_insidePolygon(item.polygon, point)) {
        return item.props;
      }
    }
    return null;
  }

  /// Returns all polygons that contain the ([lon], [lat]) location.
  List<T> all(double lon, double lat) {
    final List<T> output = [];
    final point = Point(lon, lat);
    final result = _findInTree(point: point);
    for (final item in result) {
      if (_insidePolygon(item.polygon, point)) {
        output.add(item.props);
      }
    }
    return output;
  }

  /// Returns all polygons that intersect with the given bounding box.
  List<T> bbox(double minLon, double minLat, double maxLon, double maxLat) {
    final List<T> output = [];
    final bbox = BBox(minLon, minLat, maxLon, maxLat);
    final result = _findInTree(bbox: bbox);
    for (final item in result) {
      if (_polygonIntersectsBBox(item.polygon, bbox)) {
        output.add(item.props);
      }
    }
    return output;
  }

  List<_TreeItem<T>> _findInTree({Point? point, BBox? bbox}) {
    RBushBox rbox;
    if (point != null) {
      rbox = RBushBox(
          minX: point.lon, minY: point.lat, maxX: point.lon, maxY: point.lat);
    } else {
      if (bbox == null) throw ArgumentError('point or bbox should not be null');
      rbox = RBushBox(
          minX: bbox.minLon,
          minY: bbox.minLat,
          maxX: bbox.maxLon,
          maxY: bbox.maxLat);
    }
    return _tree.search(rbox);
  }

  static bool _polygonIntersectsBBox(_Polygon polygon, BBox bbox) {
    if (_insidePolygon(polygon, bbox.center)) return true;
    final lineclip = LineClip();
    for (final ring in polygon.rings) {
      if (lineclip(ring, bbox).isNotEmpty) return true;
    }
    return false;
  }

  static bool _insidePolygon(_Polygon polygon, Point p) {
    bool inside = false;
    for (final ring in polygon.rings) {
      int j = 0;
      int len2 = ring.length;
      int k = len2 - 1;
      while (j < len2) {
        if (_rayIntersect(p, ring[j], ring[k])) {
          inside = !inside;
        }
        k = j++;
      }
    }
    return inside;
  }

  static bool _rayIntersect(Point p, Point p1, Point p2) {
    bool part1 = (p1.lat > p.lat && p2.lat <= p.lat) ||
        (p1.lat <= p.lat && p2.lat > p.lat);
    bool part2 = p.lon <
        (p2.lon - p1.lon) * (p.lat - p1.lat) / (p2.lat - p1.lat) + p1.lon;
    return part1 && part2;
  }
}

class _Polygon {
  final List<List<Point>> rings;

  const _Polygon(this.rings);

  factory _Polygon.fromJson(List<dynamic> coords) {
    final List<List<Point>> rings = [];
    for (final List<dynamic> r in coords) {
      rings.add(r.map((pt) => Point.fromJson(pt)).toList());
    }
    return _Polygon(rings);
  }

  List<Point> get outerRing => rings[0];
}

class _TreeItem<T> extends RBushBox {
  final _Polygon polygon;
  final T props;

  _TreeItem(this.polygon, this.props) {
    for (final p in polygon.outerRing) {
      minX = math.min(minX, p.lon);
      minY = math.min(minY, p.lat);
      maxX = math.max(maxX, p.lon);
      maxY = math.max(maxY, p.lat);
    }
  }
}
