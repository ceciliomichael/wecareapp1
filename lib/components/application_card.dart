import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/application.dart';
import '../models/job.dart';
import '../models/user.dart';

class ApplicationCard extends StatelessWidget {
  final Application application;
  final Job job;
  final User helper;
  final Function(String)? onStatusChange;
  final VoidCallback? onViewDetails;

  const ApplicationCard({
    Key? key,
    required this.application,
    required this.job,
    required this.helper,
    this.onStatusChange,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Helper profile image
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.2),
                    child:
                        helper.photoUrl != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.memory(
                                base64Decode(helper.photoUrl!),
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                            : Icon(
                              Icons.person,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                  ),
                  const SizedBox(width: 12),
                  // Helper name and job title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helper.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Applied for: ${job.title}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Application status
                  _buildStatusBadge(context, application.status),
                ],
              ),
              const SizedBox(height: 16),
              // Application date
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Applied: ${DateFormat('MMM dd, yyyy').format(application.dateApplied)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              // Cover letter preview (if available)
              if (application.coverLetter != null &&
                  application.coverLetter!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  application.coverLetter!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              // Skills
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (helper.skills != null)
                    ...helper.skills!.map((skill) {
                      // Check if skill is required for the job
                      final bool isRequired = job.requiredSkills.contains(
                        skill,
                      );
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isRequired
                                  ? Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color:
                                isRequired
                                    ? Theme.of(context).colorScheme.secondary
                                    : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
              // Action buttons (accept/reject)
              if (onStatusChange != null &&
                  application.status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => onStatusChange!('rejected'),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text(
                        'Reject',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => onStatusChange!('accepted'),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.amber.withOpacity(0.2);
        textColor = Colors.amber.shade800;
        label = 'Pending';
        break;
      case 'accepted':
        bgColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade700;
        label = 'Accepted';
        break;
      case 'rejected':
        bgColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade700;
        label = 'Rejected';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// Helper function to decode base64 string
dynamic base64Decode(String str) {
  return const Base64Decoder().convert(str);
}
