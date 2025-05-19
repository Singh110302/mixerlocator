import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = 'User';
  ImageProvider profileImage = AssetImage('assets/profile.png');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          _buildUserHeader(),
          const Divider(height: 40),

          _buildListTile(
            icon: Icons.people_alt_outlined,
            title: 'Invite Friends',
            subtitle: 'Share the app with your friends',
            onTap: () => _showInviteDialog(context),
          ),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs, contact support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            ),
          ),
          _buildListTile(
            icon: Icons.settings_outlined,
            title: 'Account Settings',
            subtitle: 'Privacy, security, preferences',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AccountSettingsScreen(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(155.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black26,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _showLogoutConfirmation(context),
              child: const Text('Logout',
                  style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(35.0),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: profileImage,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? 'unknown@example.com',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditProfileDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: userName);
    XFile? pickedImage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      pickedImage = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedImage != null) {
                        setStateDialog(() {
                          profileImage = FileImage(File(pickedImage!.path));
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImage,
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              setState(() {
                userName = nameController.text.trim().isEmpty
                    ? userName
                    : nameController.text.trim();
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Friends'),
        content: const Text('Share your referral code or invite link with friends'),
        actions: [
          TextButton(
            child: const Text('Copy Link'),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite link copied to clipboard')),
              );
            },
          ),
          TextButton(
            child: const Text('Share'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          _buildSupportOption('FAQs', Icons.question_answer),
          _buildSupportOption('Contact Us', Icons.email),
          _buildSupportOption('Report a Problem', Icons.report),
        ],
      ),
    );
  }

  Widget _buildSupportOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: ListView(
        children: [
          _buildSettingOption('Privacy Settings', Icons.privacy_tip),
          _buildSettingOption('Security', Icons.security),
          _buildSettingOption('Notification Preferences', Icons.notifications),
          _buildSettingOption('Change Password', Icons.lock),
        ],
      ),
    );
  }

  Widget _buildSettingOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}