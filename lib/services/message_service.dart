import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../models/user_type.dart';
import 'storage_service.dart';
import 'notification_service.dart';

class MessageService {
  final _uuid = Uuid();

  // Stream controllers for live updates
  final _conversationsController =
      StreamController<List<Conversation>>.broadcast();
  final _messagesControllers = <String, StreamController<List<Message>>>{};

  Stream<List<Conversation>> get conversationsStream =>
      _conversationsController.stream;

  // Get conversations for a user
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    final conversations = await _getAllConversations();
    final filteredConversations =
        conversations
            .where(
              (conv) => conv.employerId == userId || conv.helperId == userId,
            )
            .toList();

    // Sort by most recent first
    filteredConversations.sort(
      (a, b) => b.lastMessageTime.compareTo(a.lastMessageTime),
    );

    return filteredConversations;
  }

  // Get a specific conversation
  Future<Conversation?> getConversation(String conversationId) async {
    final conversations = await _getAllConversations();
    return conversations.firstWhere(
      (conv) => conv.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );
  }

  // Get or create conversation between employer and helper for a job
  Future<Conversation> getOrCreateConversation(
    String employerId,
    String helperId,
    String jobId,
  ) async {
    final conversations = await _getAllConversations();
    final existingConversation = conversations.firstWhere(
      (conv) =>
          conv.employerId == employerId &&
          conv.helperId == helperId &&
          conv.jobId == jobId,
      orElse:
          () => Conversation(
            id: _uuid.v4(),
            employerId: employerId,
            helperId: helperId,
            lastMessageTime: DateTime.now(),
            jobId: jobId,
          ),
    );

    if (!conversations.contains(existingConversation)) {
      await _saveConversation(existingConversation);
    }

    return existingConversation;
  }

  // Get messages for a conversation
  Future<List<Message>> getMessagesForConversation(
    String conversationId,
  ) async {
    final messagesMap = await _getAllMessagesMap();
    final messages = messagesMap[conversationId] ?? [];

    // Sort by timestamp (oldest first)
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return messages;
  }

  // Get messages stream for a conversation
  Stream<List<Message>> getMessagesStream(String conversationId) {
    if (!_messagesControllers.containsKey(conversationId)) {
      _messagesControllers[conversationId] =
          StreamController<List<Message>>.broadcast();

      // Initialize with current messages
      getMessagesForConversation(conversationId).then((messages) {
        if (!_messagesControllers[conversationId]!.isClosed) {
          _messagesControllers[conversationId]!.add(messages);
        }
      });
    }

    return _messagesControllers[conversationId]!.stream;
  }

  // Send a new message
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    final conversation = await getConversation(conversationId);

    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    // Create the message
    final message = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Update conversation with last message
    final updatedConversation = conversation.copyWith(
      lastMessageTime: message.timestamp,
      lastMessage: content,
      unreadCount:
          conversation.unreadCount +
          (senderId != conversation.employerId ? 1 : 0),
    );

    // Save changes
    await _saveMessage(message);
    await _saveConversation(updatedConversation);

    // Send notification to the other user
    _sendMessageNotification(message, conversation, senderId);

    return message;
  }

  // Send a notification for a new message
  Future<void> _sendMessageNotification(
    Message message,
    Conversation conversation,
    String senderId,
  ) async {
    try {
      // Get sender name

      // Get sender name
      final users = await StorageService.getUsers();
      final sender = users.firstWhere(
        (user) => user.id == senderId,
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

      // Send notification
      await NotificationService.showNotification(
        id: message.hashCode,
        title: 'New message from ${sender.name}',
        body: message.content,
        payload: 'conversation_${conversation.id}',
      );
    } catch (e) {
      // Log error but don't throw exception - notification failure shouldn't break messaging
      debugPrint('Error sending notification: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final messages = await getMessagesForConversation(conversationId);
    final conversation = await getConversation(conversationId);

    if (conversation == null) {
      return;
    }

    bool hasChanges = false;
    final updatedMessages = <Message>[];

    for (final message in messages) {
      if (!message.isRead && message.senderId != userId) {
        updatedMessages.add(message.copyWith(isRead: true));
        hasChanges = true;
      }
    }

    if (hasChanges) {
      final updatedConversation = conversation.copyWith(unreadCount: 0);
      await _saveConversation(updatedConversation);
      await _saveUpdatedMessages(conversationId, messages, updatedMessages);
    }
  }

  // Helper methods for storage
  Future<List<Conversation>> _getAllConversations() async {
    final conversationsJson =
        await StorageService.getString('conversations') ?? '[]';
    return Conversation.fromJsonList(conversationsJson);
  }

  Future<Map<String, List<Message>>> _getAllMessagesMap() async {
    final Map<String, dynamic> messagesMap =
        await StorageService.getJson('messages') ?? {};

    final result = <String, List<Message>>{};

    messagesMap.forEach((conversationId, messagesJson) {
      final messagesList =
          (messagesJson as List<dynamic>)
              .map((json) => Message.fromJson(Map<String, dynamic>.from(json)))
              .toList();
      result[conversationId] = messagesList;
    });

    return result;
  }

  Future<void> _saveConversation(Conversation conversation) async {
    final conversations = await _getAllConversations();

    final index = conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      conversations[index] = conversation;
    } else {
      conversations.add(conversation);
    }

    await StorageService.setString(
      'conversations',
      Conversation.toJsonList(conversations),
    );

    // Notify listeners
    _conversationsController.add(conversations);
  }

  Future<void> _saveMessage(Message message) async {
    final messagesMap = await _getAllMessagesMap();

    if (!messagesMap.containsKey(message.conversationId)) {
      messagesMap[message.conversationId] = [];
    }

    messagesMap[message.conversationId]!.add(message);

    await _saveMessagesMap(messagesMap);

    // Notify listeners
    if (_messagesControllers.containsKey(message.conversationId) &&
        !_messagesControllers[message.conversationId]!.isClosed) {
      _messagesControllers[message.conversationId]!.add(
        messagesMap[message.conversationId]!,
      );
    }
  }

  Future<void> _saveUpdatedMessages(
    String conversationId,
    List<Message> oldMessages,
    List<Message> updatedMessages,
  ) async {
    final messagesMap = await _getAllMessagesMap();

    if (!messagesMap.containsKey(conversationId)) {
      return;
    }

    // Replace old messages with updated ones
    for (final updatedMessage in updatedMessages) {
      final index = messagesMap[conversationId]!.indexWhere(
        (m) => m.id == updatedMessage.id,
      );
      if (index >= 0) {
        messagesMap[conversationId]![index] = updatedMessage;
      }
    }

    await _saveMessagesMap(messagesMap);

    // Notify listeners
    if (_messagesControllers.containsKey(conversationId) &&
        !_messagesControllers[conversationId]!.isClosed) {
      _messagesControllers[conversationId]!.add(messagesMap[conversationId]!);
    }
  }

  Future<void> _saveMessagesMap(Map<String, List<Message>> messagesMap) async {
    final jsonMap = <String, dynamic>{};

    messagesMap.forEach((conversationId, messages) {
      jsonMap[conversationId] = messages.map((m) => m.toJson()).toList();
    });

    await StorageService.setJson('messages', jsonMap);
  }

  // Close all streams when not needed
  void dispose() {
    _conversationsController.close();
    _messagesControllers.forEach((_, controller) => controller.close());
    _messagesControllers.clear();
  }
}
