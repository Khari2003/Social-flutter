// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class StoreDetailWidget extends StatelessWidget {
  final String name;
  final String category;
  final String address;
  final LatLng coordinates;
  final String? phoneNumber;
  final String? website;
  final String priceLevel;
  final String openingHours;
  final String? imageURL;
  final VoidCallback onGetDirections;

  const StoreDetailWidget({
    required this.name,
    required this.category,
    required this.address,
    required this.coordinates,
    this.phoneNumber,
    this.website,
    required this.priceLevel,
    required this.openingHours,
    this.imageURL,
    required this.onGetDirections,
    super.key,
  });

  Widget _buildImageWidget() {
    if (imageURL != null && imageURL!.startsWith('https')) {
      return Image.network(
        imageURL!,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Text('Không thể tải ảnh', style: TextStyle(color: Colors.grey)),
        ),
      );
    } else if (imageURL != null && imageURL!.startsWith('file')) {
      final filePath = imageURL!.substring(7);
      final file = File(filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          height: 200,
          fit: BoxFit.cover,
        );
      } else {
        return const Center(
          child: Text('File ảnh không tồn tại', style: TextStyle(color: Colors.grey)),
        );
      }
    } else {
      return const Center(
        child: Text('Không có ảnh', style: TextStyle(color: Colors.grey)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: _buildImageWidget()),
          Hero(
            tag: name,
            child: Text(
              name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          _buildInfoRow(Icons.location_on, 'Địa chỉ', address),
          _buildInfoRow(Icons.access_time, 'Giờ mở cửa', openingHours),
          _buildInfoRow(Icons.attach_money, 'Mức giá', priceLevel),
          if (phoneNumber != null)
            _buildInfoRow(Icons.phone, 'Số điện thoại', phoneNumber!),
          if (website != null)
            _buildInfoRow(Icons.web, 'Website', website!),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: onGetDirections,
              icon: const Icon(Icons.directions),
              label: const Text('Đường đi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
