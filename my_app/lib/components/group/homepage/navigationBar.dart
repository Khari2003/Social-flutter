import 'package:flutter/material.dart';
import 'package:my_app/map/screens/mapScreen.dart';


class NavigationBarWidget extends StatelessWidget {
  final String? selectedGroupId;
  const NavigationBarWidget({super.key, required this.selectedGroupId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(
          top: BorderSide(
            color: const Color.fromARGB(255, 39, 41, 42),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    if (ModalRoute.of(context)?.settings.name != '/home') {
                      Navigator.popUntil(context, ModalRoute.withName('/home'));
                    }
                  },
                  icon: const Icon(Icons.home),
                  color: Color.fromARGB(255, 226, 229, 233),
                ),
                Container(
                  height: 2,
                  width: 20,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MapScreen(selectedGroupId: selectedGroupId!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map),
                  color: Color.fromARGB(255, 226, 229, 233),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 IconButton(
                  onPressed: () {
                     if (ModalRoute.of(context)?.settings.name != '/reel') {
                      Navigator.pushNamed(context, '/reel');
                    }
                  },
                  icon: const Icon(Icons.play_circle_outline),
                  color: Color.fromARGB(255, 226, 229, 233),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_bag,
                  color: Color.fromARGB(255, 226, 229, 233),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 226, 229, 233),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
