final overlapping = {
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "A"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [0, 0],
            [10, 0],
            [10, 10],
            [0, 10],
            [0, 0]
          ]
        ]
      }
    },
    {
      "type": "Feature",
      "properties": {"name": "B"},
      "geometry": {
        "type": "Polygon",
        "coordinates": [
          [
            [5, 5],
            [15, 5],
            [15, 15],
            [5, 15],
            [5, 5]
          ]
        ]
      }
    }
  ]
};
