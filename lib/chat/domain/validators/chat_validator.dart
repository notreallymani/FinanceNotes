/// Chat Validators
/// 
/// High-level design: Validation layer
/// Low-level design: Business rule validation
/// 
/// Single Responsibility: Validate chat-related inputs

import '../../../core/errors.dart';

class ChatValidator {
  /// Validate transaction ID
  static ValidationError? validateTransactionId(String? transactionId) {
    if (transactionId == null || transactionId.trim().isEmpty) {
      return const ValidationError(
        message: 'Transaction ID is required',
        code: 'TRANSACTION_ID_REQUIRED',
      );
    }
    
    // Check if it's a valid MongoDB ObjectId format (24 hex characters)
    if (!RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(transactionId.trim())) {
      return const ValidationError(
        message: 'Invalid transaction ID format',
        code: 'INVALID_TRANSACTION_ID',
      );
    }
    
    return null;
  }
  
  /// Validate message content
  static ValidationError? validateMessage(String? message) {
    if (message == null || message.trim().isEmpty) {
      return const ValidationError(
        message: 'Message cannot be empty',
        code: 'MESSAGE_EMPTY',
      );
    }
    
    final trimmedMessage = message.trim();
    
    if (trimmedMessage.length > 1000) {
      return ValidationError(
        message: 'Message is too long (max 1000 characters, got ${trimmedMessage.length})',
        code: 'MESSAGE_TOO_LONG',
      );
    }
    
    // Check for only whitespace
    if (trimmedMessage.isEmpty) {
      return const ValidationError(
        message: 'Message cannot contain only whitespace',
        code: 'MESSAGE_WHITESPACE_ONLY',
      );
    }
    
    return null;
  }
  
  /// Validate both transaction ID and message
  static ValidationError? validateSendMessage({
    required String? transactionId,
    required String? message,
  }) {
    final transactionError = validateTransactionId(transactionId);
    if (transactionError != null) return transactionError;
    
    final messageError = validateMessage(message);
    if (messageError != null) return messageError;
    
    return null;
  }
}

