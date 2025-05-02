import 'dart:async';
import 'package:flutter/material.dart';

class SearchFilterBar extends StatefulWidget {
  final Function(String) onSearch;
  final VoidCallback onFilter;
  final String hintText;
  final bool showFilterButton;
  final bool isLoading;

  const SearchFilterBar({
    Key? key,
    required this.onSearch,
    required this.onFilter,
    this.hintText = 'Search...',
    this.showFilterButton = true,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearch('');
                          },
                        )
                        : null,
              ),
            ),
          ),
          if (widget.isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            ),
          if (widget.showFilterButton) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.filter_list, color: Colors.teal),
              onPressed: widget.onFilter,
            ),
          ],
        ],
      ),
    );
  }
}

class FilterOptions {
  final RangeValues? salaryRange;
  final List<String>? selectedSkills;
  final String? location;
  final bool? isActive;

  FilterOptions({
    this.salaryRange,
    this.selectedSkills,
    this.location,
    this.isActive,
  });

  FilterOptions copyWith({
    RangeValues? salaryRange,
    List<String>? selectedSkills,
    String? location,
    bool? isActive,
  }) {
    return FilterOptions(
      salaryRange: salaryRange ?? this.salaryRange,
      selectedSkills: selectedSkills ?? this.selectedSkills,
      location: location ?? this.location,
      isActive: isActive ?? this.isActive,
    );
  }
}
