// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class StoreListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> stores;
  final Function(LatLng) onSelectStore;

  const StoreListWidget({
    required this.stores,
    required this.onSelectStore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: stores.length,
        itemBuilder: (context, index) {
          final store = stores[index];
          final coordinates = LatLng(
            store['coordinates']['lat'],
            store['coordinates']['lng'],
          );

          return Column(
            children: [
              ListTile(
                title: Text(store['name']),
                subtitle: Text(store['address']),
                trailing: Hero(
                  tag: store['_id'], // Sử dụng _id của cửa hàng làm tag duy nhất
                  child: Icon(Icons.arrow_forward_ios),
                ),
                onTap: () {
                  onSelectStore(coordinates); // Gọi hàm để báo về MapScreen
                },
              ),
              if (index < stores.length - 1) Divider(), // Thêm Divider nếu không phải item cuối
            ],
          );
        },
      ),
    );
  }
}