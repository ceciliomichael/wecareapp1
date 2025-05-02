import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../models/user.dart';
import '../../models/user_type.dart';
import '../../models/job.dart';
import '../../services/message_service.dart';
import '../../services/storage_service.dart';
import '../../services/job_service.dart';
import '../../components/chat/conversation_tile.dart';
import 'chat_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  final User currentUser;

  const ConversationsListScreen({Key? key, required this.currentUser})
    : super(key: key);

  @override
  _ConversationsListScreenState createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final MessageService _messageService = MessageService();
  final _jobService = JobService();

  List<Conversation> _conversations = [];
  Map<String, Job> _jobCache = {};
  Map<String, User> _userCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load conversations for the current user
      final conversations = await _messageService.getConversationsForUser(
        widget.currentUser.id,
      );

      setState(() {
        _conversations = conversations;
      });

      // Preload job and user data for all conversations
      for (final conversation in conversations) {
        await _cacheJobData(conversation.jobId);
        await _cacheUserData(
          widget.currentUser.userType == UserType.employer
              ? conversation.helperId
              : conversation.employerId,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading conversations: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cacheJobData(String jobId) async {
    if (_jobCache.containsKey(jobId)) return;

    try {
      final job = await JobService.getJobById(jobId);
      if (job != null) {
        setState(() {
          _jobCache[jobId] = job;
        });
      }
    } catch (e) {
      print('Error loading job data: $e');
    }
  }

  Future<void> _cacheUserData(String userId) async {
    if (_userCache.containsKey(userId)) return;

    try {
      final users = await StorageService.getUsers();
      final user = users.firstWhere(
        (u) => u.id == userId,
        orElse:
            () => User(
              id: 'unknown',
              name: 'Unknown User',
              email: '',
              phone: '',
              password: '',
              userType: UserType.helper,
            ),
      );

      setState(() {
        _userCache[userId] = user;
      });
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  User _getOtherUser(Conversation conversation) {
    final String otherUserId =
        widget.currentUser.userType == UserType.employer
            ? conversation.helperId
            : conversation.employerId;

    return _userCache[otherUserId] ??
        User(
          id: 'unknown',
          name: 'Unknown User',
          email: '',
          phone: '',
          password: '',
          userType: UserType.helper,
        );
  }

  String _getJobTitle(String jobId) {
    final job = _jobCache[jobId];
    return job?.title ?? 'Unknown Job';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Messages'), backgroundColor: Colors.teal),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadConversations,
                child: ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = _conversations[index];
                    final otherUser = _getOtherUser(conversation);
                    final jobTitle = _getJobTitle(conversation.jobId);

                    return ConversationTile(
                      conversation: conversation,
                      currentUser: widget.currentUser,
                      otherUser: otherUser,
                      jobTitle: jobTitle,
                      onTap:
                          () => _navigateToChatScreen(
                            conversation,
                            otherUser,
                            jobTitle,
                          ),
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.currentUser.userType == UserType.employer
                ? 'When helpers apply to your jobs, you can chat with them here.'
                : 'Apply to jobs to start chatting with employers.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _navigateToChatScreen(
    Conversation conversation,
    User otherUser,
    String jobTitle,
  ) async {
    // Mark messages as read when entering chat
    await _messageService.markMessagesAsRead(
      conversation.id,
      widget.currentUser.id,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatScreen(
              conversation: conversation,
              currentUser: widget.currentUser,
              otherUser: otherUser,
              jobTitle: jobTitle,
            ),
      ),
    ).then((_) {
      // Refresh the list when returning from chat screen
      _loadConversations();
    });
  }
}
