// ignore_for_file: file_names

import 'package:flutter/material.dart';

class RadiusSlider extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onRadiusChanged;

  const RadiusSlider({
    required this.radius,
    required this.onRadiusChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        children: [
          Text('Radius: ${radius.toStringAsFixed(0)} meters'),
          Slider(
            value: radius,
            min: 100,
            max: 5000,
            divisions: 400,
            label: '${radius.toStringAsFixed(0)} m',
            onChanged: onRadiusChanged,
          ),
        ],
      ),
    );
  }
}
