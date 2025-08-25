import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/job.dart';
import '../models/salary_type.dart';
import '../screens/chat/chat_screen.dart';
import 'message_service.dart';
import 'storage_service.dart';

class ContactHelperService {
  static final MessageService _messageService = MessageService();

  /// Contact a helper for a specific job/service
  /// Creates a conversation if it doesn't exist and navigates to chat
  static Future<void> contactHelperForJob({
    required BuildContext context,
    required User employer,
    required User helper,
    required Job job,
  }) async {
    try {
      // Create or get existing conversation
      final conversation = await _messageService.getOrCreateConversation(
        employer.id,
        helper.id,
        job.id,
      );

      // Navigate to chat screen
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  conversation: conversation,
                  currentUser: employer,
                  otherUser: helper,
                  jobTitle: job.title,
                ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error contacting helper: $e')));
      }
    }
  }

  /// Contact a helper with a general inquiry (not job-specific)
  /// Creates a general conversation and navigates to chat
  static Future<void> contactHelperGeneral({
    required BuildContext context,
    required User employer,
    required User helper,
    String? initialMessage,
  }) async {
    try {
      // Create a general job ID for non-job-specific conversations
      const generalJobId = 'general_inquiry';

      // Create or get existing conversation
      final conversation = await _messageService.getOrCreateConversation(
        employer.id,
        helper.id,
        generalJobId,
      );

      // Send initial message if provided
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await _messageService.sendMessage(
          conversationId: conversation.id,
          senderId: employer.id,
          content: initialMessage,
        );
      }

      // Navigate to chat screen
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatScreen(
                  conversation: conversation,
                  currentUser: employer,
                  otherUser: helper,
                  jobTitle: 'General Inquiry',
                ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error contacting helper: $e')));
      }
    }
  }

  /// Get helper user by ID (for contact scenarios where we only have helper ID)
  static Future<User?> getHelperById(String helperId) async {
    try {
      final users = await StorageService.getUsers();
      return users.firstWhere(
        (user) => user.id == helperId,
        orElse: () => throw Exception('Helper not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Show contact helper dialog with options
  static Future<void> showContactHelperDialog({
    required BuildContext context,
    required User employer,
    required User helper,
    required Job job,
  }) async {
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Contact ${helper.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How would you like to contact ${helper.name} about "${job.title}"?',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(job.location)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '₱${job.salary.toStringAsFixed(2)} ${job.salaryType.label}',
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'chat'),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Start Chat'),
              ),
            ],
          ),
    );

    if (result == 'chat' && context.mounted) {
      await contactHelperForJob(
        context: context,
        employer: employer,
        helper: helper,
        job: job,
      );
    }
  }

  /// Show contact options for multiple helpers
  static Future<void> showMultipleContactDialog({
    required BuildContext context,
    required User employer,
    required List<User> helpers,
    required Job job,
  }) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Contact Helpers'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: helpers.length,
                itemBuilder: (context, index) {
                  final helper = helpers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        helper.name.isNotEmpty ? helper.name[0] : '?',
                      ),
                    ),
                    title: Text(helper.name),
                    subtitle: Text(helper.email),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat),
                      onPressed: () async {
                        Navigator.pop(context);
                        if (context.mounted) {
                          await contactHelperForJob(
                            context: context,
                            employer: employer,
                            helper: helper,
                            job: job,
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}
