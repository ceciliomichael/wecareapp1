import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/job.dart';
import '../../models/salary_type.dart';
import '../../services/job_service.dart';
import '../../services/contact_helper_service.dart';
import '../../services/storage_service.dart';

class HelperServicesScreen extends StatefulWidget {
  final User employer;

  const HelperServicesScreen({super.key, required this.employer});

  @override
  State<HelperServicesScreen> createState() => _HelperServicesScreenState();
}

class _HelperServicesScreenState extends State<HelperServicesScreen> {
  List<Job> _helperServices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHelperServices();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  Future<void> _loadHelperServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final services = await JobService.getHelperPostedJobs();
      setState(() {
        _helperServices = services;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading helper services: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _viewServiceDetails(Job service) async {
    // Get the helper who posted this service
    final helper = await _getHelperForService(service);

    if (!mounted) return;

    if (helper == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Helper information not available')),
      );
      return;
    }

    // Show service details dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(service.title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Helper info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(
                          helper.name.isNotEmpty ? helper.name[0] : '?',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              helper.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (helper.isActive)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 8,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Active now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Location: ${service.location}'),
                  const SizedBox(height: 8),
                  Text(
                    'Rate: ₱${service.salary.toStringAsFixed(2)} ${service.salaryType.label}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(service.description),
                  const SizedBox(height: 16),
                  const Text(
                    'Skills:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children:
                        service.requiredSkills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await ContactHelperService.contactHelperForJob(
                    context: context,
                    employer: widget.employer,
                    helper: helper,
                    job: service,
                  );
                },
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Contact Helper'),
              ),
            ],
          ),
    );
  }

  Future<User?> _getHelperForService(Job service) async {
    try {
      final users = await StorageService.getUsers();
      return users.firstWhere(
        (user) => user.id == service.posterId,
        orElse: () => throw Exception('Helper not found'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredServices =
        _searchQuery.isEmpty
            ? _helperServices
            : _helperServices
                .where(
                  (service) =>
                      service.title.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      service.description.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      service.requiredSkills.any(
                        (skill) => skill.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ),
                      ),
                )
                .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Helper Services'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search services',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
              ),
            ),
          ),

          // Grid of services
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredServices.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                      onRefresh: _loadHelperServices,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredServices.length,
                        itemBuilder: (context, index) {
                          final service = filteredServices[index];
                          return _buildServiceCard(service);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Job service) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _viewServiceDetails(service),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.handyman,
                    size: 48,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service.location,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₱${service.salary.toStringAsFixed(2)} ${service.salaryType.label}',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        service.description,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Contact button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final helper = await _getHelperForService(service);
                          if (helper != null && mounted) {
                            await ContactHelperService.contactHelperForJob(
                              context: context,
                              employer: widget.employer,
                              helper: helper,
                              job: service,
                            );
                          }
                        },
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text(
                          'Contact',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.handyman_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No helper services available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Helpers haven\'t posted any services yet',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
