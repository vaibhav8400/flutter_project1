import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:rxdart/rxdart.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerEmail;

  ChatScreen({required this.peerId, required this.peerEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final CollectionReference _chatsCollection =
  FirebaseFirestore.instance.collection('chats');

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatsCollection.add({
        'senderId': currentUser?.uid,
        'receiverId': widget.peerId,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _messageController.clear();
    }
  }

  void _makeVoiceCall() {
    // Implement voice call logic
    print("Voice call initiated");
  }

  void _makeVideoCall() {
    // Implement video call logic
    print("Video call initiated");
  }

  void _openCamera() {
    // Implement camera logic
    print("Camera opened");
  }

  void _openMediaPicker() {
    // Implement media picker logic
    print("Media picker opened");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerEmail),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.phone),
            onPressed: _makeVoiceCall,
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: _makeVideoCall,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<List<QuerySnapshot>>(
              stream: Rx.combineLatest2(
                _chatsCollection
                    .where('senderId', isEqualTo: currentUser?.uid)
                    .where('receiverId', isEqualTo: widget.peerId)
                    .snapshots(),
                _chatsCollection
                    .where('senderId', isEqualTo: widget.peerId)
                    .where('receiverId', isEqualTo: currentUser?.uid)
                    .snapshots(),
                    (QuerySnapshot a, QuerySnapshot b) => [a, b],
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var messages = snapshot.data![0].docs + snapshot.data![1].docs;
                messages.sort((a, b) => (a['timestamp'] as Timestamp)
                    .compareTo(b['timestamp'] as Timestamp));

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var message = messages[index];
                    bool isSentByCurrentUser =
                        message['senderId'] == currentUser?.uid;
                    return Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 5.0),
                      alignment: isSentByCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSentByCurrentUser
                              ? Colors.green[200]
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: isSentByCurrentUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              message['timestamp'] != null
                                  ? (message['timestamp'] as Timestamp)
                                  .toDate()
                                  .toString()
                                  : 'Sending...',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black54),
                            ),
                          ],
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
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: _openCamera,
                ),
                IconButton(
                  icon: Icon(Icons.photo_library),
                  onPressed: _openMediaPicker,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 20.0),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
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
