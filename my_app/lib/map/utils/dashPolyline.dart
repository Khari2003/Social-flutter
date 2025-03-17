// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

List<Polyline> generateDashedPolyline(List<LatLng> coordinates) {
  const double segmentLength = 5.0; // Độ dài mỗi đoạn nét đứt
  const double gapLength = 3.0; // Độ dài khoảng trống giữa các đoạn

  List<Polyline> dashedPolylines = [];
  for (int i = 0; i < coordinates.length - 1; i++) {
    LatLng start = coordinates[i];
    LatLng end = coordinates[i + 1];

    // Tính toán khoảng cách giữa hai điểm
    final distance = Distance().as(LengthUnit.Meter, start, end);
    final totalSegments = (distance / (segmentLength + gapLength)).floor();

    for (int j = 0; j < totalSegments; j++) {
      double t1 = j / totalSegments;
      double t2 = (j + 0.5) / totalSegments;

      // Nội suy các điểm
      LatLng segmentStart = LatLng(
        start.latitude + (end.latitude - start.latitude) * t1,
        start.longitude + (end.longitude - start.longitude) * t1,
      );
      LatLng segmentEnd = LatLng(
        start.latitude + (end.latitude - start.latitude) * t2,
        start.longitude + (end.longitude - start.longitude) * t2,
      );

      // Thêm đoạn nét đứt
      dashedPolylines.add(
        Polyline(
          points: [segmentStart, segmentEnd],
          strokeWidth: 5.0,
          color: Colors.blue, // Màu đường nét đứt
        ),
      );
    }
  }

  return dashedPolylines;
}
