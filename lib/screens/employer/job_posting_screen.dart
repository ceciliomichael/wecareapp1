import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/job.dart';
import '../../services/job_service.dart';

class JobPostingScreen extends StatefulWidget {
  final User employer;
  final Function onJobPosted;
  final Job? job; // Null for new job, non-null for editing

  const JobPostingScreen({
    Key? key,
    required this.employer,
    required this.onJobPosted,
    this.job,
  }) : super(key: key);

  @override
  State<JobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<JobPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _salaryController;
  late TextEditingController _locationController;

  // For skills input
  final TextEditingController _skillController = TextEditingController();
  final List<String> _skills = [];

  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.job != null;

    // Initialize controllers
    _titleController = TextEditingController(
      text: _isEditing ? widget.job!.title : '',
    );
    _descriptionController = TextEditingController(
      text: _isEditing ? widget.job!.description : '',
    );
    _salaryController = TextEditingController(
      text: _isEditing ? widget.job!.salary.toString() : '',
    );
    _locationController = TextEditingController(
      text: _isEditing ? widget.job!.location : '',
    );

    // Initialize skills list if editing
    if (_isEditing) {
      _skills.addAll(widget.job!.requiredSkills);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  void _addSkill() {
    final skill = _skillController.text.trim();
    if (skill.isNotEmpty && !_skills.contains(skill)) {
      setState(() {
        _skills.add(skill);
        _skillController.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _skills.remove(skill);
    });
  }

  Future<void> _saveJob() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        if (_isEditing) {
          // Update existing job
          final updatedJob = widget.job!.copyWith(
            title: _titleController.text,
            description: _descriptionController.text,
            salary: double.parse(_salaryController.text),
            location: _locationController.text,
            requiredSkills: _skills,
          );

          await JobService.updateJob(updatedJob);
        } else {
          // Create new job
          await JobService.createJob(
            employerId: widget.employer.id,
            title: _titleController.text,
            description: _descriptionController.text,
            salary: double.parse(_salaryController.text),
            location: _locationController.text,
            requiredSkills: _skills,
          );
        }

        // Refresh job list and return
        widget.onJobPosted();
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving job: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Job' : 'Post a New Job'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title',
                  hintText: 'e.g., House Cleaner, Nanny, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description',
                  hintText: 'Describe the job responsibilities, hours, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a job description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Salary field
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary (₱)',
                  hintText: 'Monthly salary amount',
                  border: OutlineInputBorder(),
                  prefixText: '₱ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a salary';
                  }
                  try {
                    double.parse(value);
                  } catch (e) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  hintText: 'e.g., Makati City, Manila',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Skills section
              const Text(
                'Required Skills',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillController,
                      decoration: const InputDecoration(
                        labelText: 'Add a skill',
                        hintText: 'e.g., Cooking, Cleaning, Childcare',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSkill,
                    icon: const Icon(Icons.add),
                    tooltip: 'Add skill',
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Skills chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _skills.map((skill) {
                      return Chip(
                        label: Text(skill),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => _removeSkill(skill),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                      );
                    }).toList(),
              ),

              if (_skills.isEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Add at least one required skill',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveJob,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(_isEditing ? 'Update Job' : 'Post Job'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
