import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/user.dart';
import '../../services/message_service.dart';
import '../../components/chat/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;
  final User currentUser;
  final User otherUser;
  final String jobTitle;

  const ChatScreen({
    Key? key,
    required this.conversation,
    required this.currentUser,
    required this.otherUser,
    required this.jobTitle,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  late StreamSubscription<List<Message>> _messagesSubscription;

  List<Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Listen to the message stream for this conversation
      _messagesSubscription = _messageService
          .getMessagesStream(widget.conversation.id)
          .listen((messages) {
            setState(() {
              _messages = messages;
              _isLoading = false;
            });

            // Mark messages as read as they come in
            _messageService.markMessagesAsRead(
              widget.conversation.id,
              widget.currentUser.id,
            );
          });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _messageService.sendMessage(
        conversationId: widget.conversation.id,
        senderId: widget.currentUser.id,
        content: messageText,
      );

      // Clear the text field
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherUser.name,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 2),
            Text(
              'Job: ${widget.jobTitle}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.teal[700],
              radius: 16,
              child: Text(
                widget.otherUser.name.isNotEmpty
                    ? widget.otherUser.name[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            onPressed: () {
              // Could open user profile in future
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat header with job info
          Container(
            padding: EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.work_outline, color: Colors.teal, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This conversation is about "${widget.jobTitle}"',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child:
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                      reverse: true,
                      padding: EdgeInsets.only(bottom: 16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        // Show messages in reverse order (newest at bottom)
                        final message = _messages[_messages.length - 1 - index];
                        final isCurrentUser =
                            message.senderId == widget.currentUser.id;
                        final senderName =
                            isCurrentUser
                                ? widget.currentUser.name
                                : widget.otherUser.name;

                        return MessageBubble(
                          message: message,
                          isCurrentUser: isCurrentUser,
                          senderName: senderName,
                        );
                      },
                    ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: Offset(0, -2),
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon:
                        _isSending
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Icon(Icons.send, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Send a message to start the conversation',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
