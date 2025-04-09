import 'package:flutter/material.dart';
import 'package:my_app/components/group/homepage/navigationBar.dart';
// Import the navigation bar widget

class testScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool _showNavBar = true;
    return Scaffold(
        body: Stack(children: [
      AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        bottom: _showNavBar ? 0 : -70,
        left: 0,
        right: 0,
        child: NavigationBarWidget(selectedGroupId: "đâsd"),
      ),
    ]));
  }
}
