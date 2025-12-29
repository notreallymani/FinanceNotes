/// Interest Calculator Utility
/// 
/// Single Responsibility: Calculate interest based on transaction dates
/// Clean Architecture: Pure calculation logic

import 'time_utils.dart';

class InterestCalculation {
  final double principal;
  final double interestRate; // Can be percentage or fixed amount
  final DateTime startDate;
  final DateTime endDate;
  final int days;
  final double dailyInterest;
  final double totalInterest;
  final double totalAmount;
  final bool isPercentage; // true if interest is percentage, false if fixed amount

  InterestCalculation({
    required this.principal,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.dailyInterest,
    required this.totalInterest,
    required this.totalAmount,
    required this.isPercentage,
  });

  String get formattedStartDate => TimeUtils.formatISTDateOnly(startDate);
  String get formattedEndDate => TimeUtils.formatISTDateOnly(endDate);
  String get formattedPeriod => '$days ${days == 1 ? 'day' : 'days'}';
}

class InterestCalculator {
  /// Calculate simple interest from transaction creation to today (or closed date)
  /// 
  /// Interest is calculated as a percentage per month (30 days)
  /// Simple formula: (Principal × Rate × Days) / (100 × 30)
  static InterestCalculation calculateInterest({
    required double principal,
    required double interest, // Interest rate as percentage per month
    required DateTime createdAt,
    DateTime? closedAt,
  }) {
    final endDate = closedAt ?? DateTime.now();
    final startDate = createdAt;
    
    // Calculate days difference
    final days = endDate.difference(startDate).inDays;
    
    // Simple interest calculation: percentage per month (30 days)
    // Formula: (Principal × Rate × Days) / (100 × 30)
    final monthlyRate = interest;
    final dailyInterest = (principal * monthlyRate) / (100 * 30);
    final totalInterest = dailyInterest * days;
    
    // Ensure interest is not negative
    final safeTotalInterest = totalInterest < 0 ? 0.0 : totalInterest;
    final safeDailyInterest = dailyInterest < 0 ? 0.0 : dailyInterest;
    
    final totalAmount = principal + safeTotalInterest;
    
    return InterestCalculation(
      principal: principal,
      interestRate: interest,
      startDate: startDate,
      endDate: endDate,
      days: days,
      dailyInterest: safeDailyInterest,
      totalInterest: safeTotalInterest,
      totalAmount: totalAmount,
      isPercentage: true, // Always percentage
    );
  }
  
  /// Format number as currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
  
  /// Format number as percentage
  static String formatPercentage(double rate) {
    return '${rate.toStringAsFixed(2)}%';
  }
}

