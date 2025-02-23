// ignore_for_file: file_names

import 'dart:async'; // Thêm thư viện này để sử dụng Timer
import 'package:flutter/material.dart';
import '../services/osmService.dart';

class SearchPlaces extends StatefulWidget {
  const SearchPlaces({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchPlacesState createState() => _SearchPlacesState();
}

class _SearchPlacesState extends State<SearchPlaces> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> _suggestions = [];
  Timer? _debounce; // Biến Timer để kiểm soát debounce

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel(); // Hủy bỏ debounce trước đó

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isNotEmpty) {
        List<Map<String, dynamic>> results = await OSMService.searchPlaces(query);
        setState(() {
          _suggestions = results.map((item) {
            return item.map((key, value) => MapEntry(key, value.toString()));
          }).toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Hủy Timer khi thoát màn hình
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tìm kiếm địa điểm (OSM)")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Nhập địa điểm...",
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged, // Kích hoạt debounce khi nhập liệu
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final place = _suggestions[index];
                  return ListTile(
                    title: Text(place["name"]!),
                    subtitle: Text(
                        "Lat: ${place["lat"]}, Lon: ${place["lon"]}\nCách đây: ${place["distance"]} km"),
                    onTap: () {
                      Navigator.pop(context, place);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
