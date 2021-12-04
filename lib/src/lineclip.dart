// A very fast library for clipping polylines and polygons by a bounding box.
//
// Port of https://github.com/mapbox/lineclip v1.1.5
// Code mainly by Vladimir Agafonkin, ported by Ilya Zverev.
// Licensed ISC.

import 'bbox.dart';

class LineClip {
  List<List<Point>> call(List<Point> points, BBox bbox, [List<List<Point>>? start]) =>
      polyline(points, bbox, start);

  /// Cohen-Sutherland line clipping algorithm, adapted to efficiently
  /// handle polylines rather than just segments.
  List<List<Point>> polyline(List<Point> points, BBox bbox, [List<List<Point>>? start]) {
    final List<List<Point>> result = start ?? [];
    if (points.isEmpty) return result;

    final int len = points.length;
    int codeA = _bitCode(points.first, bbox);
    List<Point> part = [];

    for (int i = 1; i < len; i++) {
      Point a = points[i - 1];
      Point b = points[i];
      int codeB = _bitCode(b, bbox);
      int lastCode = codeB;

      int lastCodes = -1;
      while (true) {
        if ((codeA << 4) + codeB == lastCodes) {
          throw StateError('Stuck in an infinite loop. CodeA=$codeA, CodeB=$codeB.');
        }
        lastCodes = (codeA << 4) + codeB;

        if (codeA | codeB == 0) { // accept
          part.add(a);

          if (codeB != lastCode) { // start a new line
            part.add(b);

            if (i < len - 1) {
              result.add(part);
              part = [];
            }
          } else if (i == len - 1) {
            part.add(b);
          }
          break;

        } else if (codeA & codeB != 0) { // trivial reject
          break;

        } else if (codeA != 0) { // a outside, intersect with clip edge
          a = _intersect(a, b, codeA, bbox);
          codeA = _bitCode(a, bbox);

        } else { // b outside
          b = _intersect(a, b, codeB, bbox);
          codeB = _bitCode(b, bbox);
        }
      }

      codeA = lastCode;
    }

    if (part.isNotEmpty) result.add(part);
    return result;
  }

  /// Sutherland-Hodgeman polygon clipping algorithm.
  List<Point> polygon(List<Point> points, BBox bbox) {
    List<Point> result = [];
    if (points.isEmpty) return result;

    // clip against each side of the clip rectangle
    for (int edge = 1; edge <= 8; edge *= 2) {
      result = [];
      Point prev = points.last;
      bool prevInside = (_bitCode(prev, bbox) & edge) == 0;

      for (final p in points) {
        final bool inside = (_bitCode(p, bbox) & edge) == 0;

        // if segment goes through the clip window, add an intersection
        if (inside != prevInside)
          result.add(_intersect(prev, p, edge, bbox));

        if (inside) result.add(p); // add a point if it's inside

        prev = p;
        prevInside = inside;
      }

      points = result;

      if (points.isEmpty) break;
    }

    return result;
  }

  /// Intersect a segment against one of the 4 lines that make up the bbox.
  Point _intersect(Point a, Point b, int edge, BBox bbox) {
    if (edge & 8 != 0) {
      assert(a.lat != b.lat);
      return Point(a.lon + (b.lon - a.lon) * (bbox.maxLat - a.lat) / (b.lat - a.lat), bbox.maxLat); // top
    } else if (edge & 4 != 0) {
      assert(a.lat != b.lat);
      return Point(a.lon + (b.lon - a.lon) * (bbox.minLat - a.lat) / (b.lat - a.lat), bbox.minLat); // bottom
    } else if (edge & 2 != 0) {
      assert(a.lon != b.lon);
      return Point(bbox.maxLon, a.lat + (b.lat - a.lat) * (bbox.maxLon - a.lon) / (b.lon - a.lon)); // right
    } else if (edge & 1 != 0) {
      assert(a.lon != b.lon);
      return Point(bbox.minLon, a.lat + (b.lat - a.lat) * (bbox.minLon - a.lon) / (b.lon - a.lon)); // left
    }
    throw StateError('Segment does not intersect with the bbox.');
  }

  /// Bit code reflects the point position relative to the bbox:
  ///
  /// ```
  ///         left  mid  right
  ///    top  1001  1000  1010
  ///    mid  0001  0000  0010
  /// bottom  0101  0100  0110
  /// ```
  int _bitCode(Point p, BBox bbox) {
    int code = 0;

    if (p.lon < bbox.minLon) code |= 1; // left
    else if (p.lon > bbox.maxLon) code |= 2; // right

    if (p.lat < bbox.minLat) code |= 4; // bottom
    else if (p.lat > bbox.maxLat) code |= 8; // top

    return code;
  }
}