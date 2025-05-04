import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/job.dart';
import '../models/user.dart';
import '../models/salary_type.dart';
import 'activity_status_indicator.dart';

class HelperServiceCard extends StatelessWidget {
  final Job service;
  final User helper;
  final Function() onTap;
  final Function()? onContactPressed;
  final bool isDetailed;

  const HelperServiceCard({
    Key? key,
    required this.service,
    required this.helper,
    required this.onTap,
    this.onContactPressed,
    this.isDetailed = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Helper profile image
                  _buildProfileImage(),
                  const SizedBox(width: 12),

                  // Service information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              helper.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ActivityStatusIndicator(isActive: helper.isActive),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                service.location,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
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
                              '${service.salary} ${service.salaryType.label}/hr',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isDetailed) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(service.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),

                // Skills section
                if (helper.skills != null && helper.skills!.isNotEmpty) ...[
                  Text(
                    'Skills',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        helper.skills!.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.1),
                            labelStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact button
                if (onContactPressed != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onContactPressed,
                      icon: const Icon(Icons.message),
                      label: const Text('Contact Helper'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
            image:
                helper.photoUrl != null
                    ? DecorationImage(
                      image: MemoryImage(base64Decode(helper.photoUrl!)),
                      fit: BoxFit.cover,
                    )
                    : null,
          ),
          child:
              helper.photoUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: ActivityStatusIndicator(isActive: helper.isActive, size: 10),
        ),
      ],
    );
  }
}
