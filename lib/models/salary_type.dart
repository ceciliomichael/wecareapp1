// Enum for salary types
enum SalaryType {
  hourly, // Hourly rate
  daily, // Daily rate
  weekly, // Weekly salary
  biweekly, // Every 15 days
  monthly, // Monthly salary
}

// Extension to provide human-readable labels
extension SalaryTypeExtension on SalaryType {
  String get label {
    switch (this) {
      case SalaryType.hourly:
        return 'Per Hour';
      case SalaryType.daily:
        return 'Per Day';
      case SalaryType.weekly:
        return 'Per Week';
      case SalaryType.biweekly:
        return 'Biweekly';
      case SalaryType.monthly:
        return 'Per Month';
    }
  }
}
