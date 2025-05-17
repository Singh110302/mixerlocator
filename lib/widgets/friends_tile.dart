import 'package:flutter/material.dart';

class FriendTile extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const FriendTile({super.key, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(child: Icon(Icons.person)),
      title: Text(name),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }
}
