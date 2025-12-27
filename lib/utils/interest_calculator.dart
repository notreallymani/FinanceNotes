/// Interest Calculator Utility
/// 
/// Single Responsibility: Calculate interest based on transaction dates
/// Clean Architecture: Pure calculation logic

import 'package:intl/intl.dart';

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

  String get formattedStartDate => DateFormat('dd MMM yyyy').format(startDate);
  String get formattedEndDate => DateFormat('dd MMM yyyy').format(endDate);
  String get formattedPeriod => '$days ${days == 1 ? 'day' : 'days'}';
}

class InterestCalculator {
  /// Calculate interest from transaction creation to today (or closed date)
  /// 
  /// Interest can be:
  /// - Percentage (e.g., 2.5% per month or per year)
  /// - Fixed amount (e.g., ₹1000)
  /// 
  /// We'll treat interest > 100 as fixed amount, <= 100 as percentage
  static InterestCalculation calculateInterest({
    required double principal,
    required double interest, // Interest rate or fixed amount
    required DateTime createdAt,
    DateTime? closedAt,
  }) {
    final endDate = closedAt ?? DateTime.now();
    final startDate = createdAt;
    
    // Calculate days difference
    final days = endDate.difference(startDate).inDays;
    
    // Determine if interest is percentage or fixed amount
    // If interest > 100, treat as fixed amount; otherwise as percentage
    final isPercentage = interest <= 100;
    
    double totalInterest;
    double dailyInterest;
    
    if (isPercentage) {
      // Treat as percentage per month (30 days)
      // Formula: (Principal × Rate × Days) / (100 × 30)
      final monthlyRate = interest;
      dailyInterest = (principal * monthlyRate) / (100 * 30);
      totalInterest = dailyInterest * days;
    } else {
      // Treat as fixed amount per month (30 days)
      // Calculate daily rate: fixedAmount / 30
      // Then multiply by days
      final monthlyFixed = interest;
      dailyInterest = monthlyFixed / 30;
      totalInterest = dailyInterest * days;
    }
    
    // Ensure interest is not negative
    if (totalInterest < 0) totalInterest = 0;
    if (dailyInterest < 0) dailyInterest = 0;
    
    final totalAmount = principal + totalInterest;
    
    return InterestCalculation(
      principal: principal,
      interestRate: interest,
      startDate: startDate,
      endDate: endDate,
      days: days,
      dailyInterest: dailyInterest,
      totalInterest: totalInterest,
      totalAmount: totalAmount,
      isPercentage: isPercentage,
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

