import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleStatus;
  final bool showActions;

  const JobCard({
    Key? key,
    required this.job,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                job.location,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          job.isActive
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color:
                            job.isActive
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Salary
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    NumberFormat.currency(
                      symbol: '₱',
                      decimalDigits: 2,
                    ).format(job.salary),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              // Skills
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    job.requiredSkills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skill,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 12),
              // Date and actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date posted
                  Text(
                    'Posted: ${DateFormat('MMM dd, yyyy').format(job.datePosted)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  // Actions
                  if (showActions) ...[
                    Row(
                      children: [
                        // Edit button
                        if (onEdit != null)
                          IconButton(
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.blue,
                            tooltip: 'Edit job',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        // Toggle status button
                        if (onToggleStatus != null)
                          IconButton(
                            onPressed: onToggleStatus,
                            icon: Icon(
                              job.isActive
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                            ),
                            color: job.isActive ? Colors.orange : Colors.green,
                            tooltip:
                                job.isActive
                                    ? 'Deactivate job'
                                    : 'Activate job',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                        // Delete button
                        if (onDelete != null)
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete, size: 20),
                            color: Colors.red,
                            tooltip: 'Delete job',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(8),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
