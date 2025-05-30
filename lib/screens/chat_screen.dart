import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // <-- Add this import

class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;

  const ChatScreen({
    Key? key,
    required this.friendId,
    required this.friendName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      final docRef = _firestore.collection('chats').doc();

      await docRef.set({
        'id': docRef.id,
        'senderId': currentUser.uid,
        'receiverId': widget.friendId,
        'message': _messageController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'isLocation': _messageController.text.contains('maps.google.com'),
      });

      _messageController.clear();
      setState(() {});
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _getMessagesStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>>.empty();
    }

    final sentMessagesQuery = _firestore
        .collection('chats')
        .where('senderId', isEqualTo: currentUser.uid)
        .where('receiverId', isEqualTo: widget.friendId)
        .orderBy('timestamp');

    final receivedMessagesQuery = _firestore
        .collection('chats')
        .where('senderId', isEqualTo: widget.friendId)
        .where('receiverId', isEqualTo: currentUser.uid)
        .orderBy('timestamp');

    return Rx.combineLatest2(
      sentMessagesQuery.snapshots(),
      receivedMessagesQuery.snapshots(),
          (QuerySnapshot<Map<String, dynamic>> sent, QuerySnapshot<Map<String, dynamic>> received) {
        final allDocs = [...sent.docs, ...received.docs];
        allDocs.sort((a, b) {
          final tsA = a.data()['timestamp'] as Timestamp?;
          final tsB = b.data()['timestamp'] as Timestamp?;
          if (tsA == null && tsB == null) return 0;
          if (tsA == null) return -1;
          if (tsB == null) return 1;
          return tsA.compareTo(tsB);
        });
        return allDocs;
      },
    );
  }

  Future<void> _getCurrentLocationLink() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied')),
        );
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Navigator.of(context).pop();

      final locationLink = 'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      _messageController.text = locationLink;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  void _openLocationInMap(String url) {
    final uri = Uri.parse(url);
    final query = uri.queryParameters['query'];
    if (query != null) {
      final parts = query.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapScreen(
                targetLat: lat,
                targetLng: lng,
              ),
            ),
          );
          return;
        }
      }
    }

    // Fallback if parsing failed — open external map app
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(widget.friendName[0]),
              radius: 16,
            ),
            const SizedBox(width: 10),
            Text(
              widget.friendName,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _getMessagesStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = _auth.currentUser?.uid == message['senderId'];
                    final timestamp = (message['timestamp'] as Timestamp?)?.toDate();
                    final isLocation = message['isLocation'] == true ||
                        (message['message'] as String).contains('maps.google.com');

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: isLocation
                            ? () => _openLocationInMap(message['message'])
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLocation)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.location_on, color: Colors.red, size: 18),
                                        SizedBox(width: 4),
                                        Text(
                                          'Location Shared',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message['message'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue[600],
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap to open in maps',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  message['message'],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    DateFormat('h:mm a').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.location_on, color: Colors.blue),
                              title: const Text('Share Location'),
                              onTap: () {
                                Navigator.pop(context);
                                _getCurrentLocationLink();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple MapScreen for showing the tapped location inside the app
class MapScreen extends StatelessWidget {
  final double targetLat;
  final double targetLng;

  const MapScreen({
    super.key,
    required this.targetLat,
    required this.targetLng,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(targetLat, targetLng),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('sharedLocation'),
            position: LatLng(targetLat, targetLng),
          ),
        },
      ),
    );
  }
}
