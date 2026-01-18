/// Send Message Use Case
/// 
/// High-level design: Use case pattern
/// Low-level design: Business logic for sending messages
/// 
/// Single Responsibility: Handle message sending logic

import '../../../core/result.dart';
import '../../../core/errors.dart';
import '../interfaces/chat_repository_interface.dart';
import '../validators/chat_validator.dart';
import '../../../models/chat_model.dart';

class SendMessageUseCase {
  final IChatRepository _repository;
  
  SendMessageUseCase(this._repository);
  
  /// Execute the use case
  /// 
  /// Validates input, then sends message via repository
  Future<Result<ChatMessage>> execute({
    required String transactionId,
    required String message,
  }) async {
    // Validate input
    final validationError = ChatValidator.validateSendMessage(
      transactionId: transactionId,
      message: message,
    );
    
    if (validationError != null) {
      return Failure(validationError.message);
    }
    
    try {
      // Delegate to repository
      final result = await _repository.sendMessage(
        transactionId: transactionId.trim(),
        message: message.trim(),
      );
      
      // Invalidate cache after successful send
      if (result.isSuccess) {
        await _repository.invalidateTransactionCache(transactionId.trim());
      }
      
      return result;
    } catch (e) {
      return Failure(
        UnknownError.fromException(e).message,
      );
    }
  }
}

