import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Locket", style: TextStyle(fontFamily: 'Billabong', fontSize: 30)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.send, color: Colors.black),
            onPressed: () {
              // Action for sending messages
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return PostCard(index: index);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.black),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, color: Colors.black),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box, color: Colors.black),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, color: Colors.black),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, color: Colors.black),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Handle bottom navigation taps
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final int index;

  PostCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey,
              backgroundImage: AssetImage('assets/user_profile.jpg'), // Use asset image for user profile
            ),
            title: Text('User $index', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Location $index', style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.more_horiz),
          ),
          Center( // Center the image
            child: Image.asset(
              '../../assets/post_image_$index.jpg', // Use asset image for posts
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width, // Set width to match screen
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.favorite_border),
                SizedBox(width: 16),
                Icon(Icons.comment),
                SizedBox(width: 16),
                Icon(Icons.share),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('Liked by User 1 and Others', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text('User $index: This is a caption for the post'),
          ),
        ],
      ),
    );
  }
}