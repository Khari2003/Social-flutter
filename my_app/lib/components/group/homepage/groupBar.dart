import 'package:flutter/material.dart';

class GroupbarWidget extends StatelessWidget {
  final bool isOpen;
  final List<Map<String, dynamic>> userGroups;
  final String? selectedGroupId;
  final Function(String) onGroupSelected;

  const GroupbarWidget({
    Key? key,
    required this.isOpen,
    required this.userGroups,
    required this.selectedGroupId,
    required this.onGroupSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.15,
      color: const Color.fromARGB(47, 0, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: userGroups.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => onGroupSelected(userGroups[index]["id"]!),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedGroupId == userGroups[index]["id"]
                          ? Colors.blue
                          : Colors.grey,
                    ),
                    padding: const EdgeInsets.all(15),
                    alignment: Alignment.center,
                    child: Text(
                      userGroups[index]["name"]![0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
