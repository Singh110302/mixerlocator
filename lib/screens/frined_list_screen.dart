import 'package:flutter/material.dart';
import 'chat_screen.dart'; // Import the chat screen

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  final List<Map<String, String>> friends = const [
    {'name': 'Alice', 'uid': 'user_id_1'},
    {'name': 'Bob', 'uid': 'user_id_2'},
    {'name': 'Charlie', 'uid': 'user_id_3'},
    {'name': 'Daisy', 'uid': 'user_id_4'},
  ];

  // Remove the old _sendMessage function and replace with this:
  void _navigateToChatScreen(BuildContext context, String friendId, String friendName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          friendId: friendId,
          friendName: friendName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
      ),
      body: Container(
        color: Colors.grey[200],
        child: ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(friend['name']![0]),
                  radius: 22,
                  backgroundColor: Colors.blue[100],
                ),
                title: Text(
                  friend['name']!,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.blue),
                      onPressed: () => _navigateToChatScreen(
                        context,
                        friend['uid']!,
                        friend['name']!,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.directions, color: Colors.green),
                      onPressed: () {
                        // Keep your existing directions functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Getting directions to ${friend['name']}")),
                        );
                      },
                    ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            );
          },
        ),
      ),
    );
  }
}