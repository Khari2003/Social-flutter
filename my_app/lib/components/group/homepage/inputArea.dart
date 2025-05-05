import 'package:flutter/material.dart';

class InputAreaWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const InputAreaWidget({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.none,
      color: const Color.fromARGB(255, 19, 20, 20),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 19, 20, 20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 40, 42, 44),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color.fromARGB(255, 80, 79, 79), width: 2)
                  ),
                  child: Center(
                    child: Text(
                      "Bạn đang nghĩ gì...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
