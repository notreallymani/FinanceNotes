/// Load Messages Use Case
/// 
/// High-level design: Use case pattern for business logic
/// Low-level design: Encapsulates loading messages logic
/// 
/// Single Responsibility: Handle loading messages for a transaction
/// Open/Closed: Can be extended without modification

import '../../../core/result.dart';
import '../../../core/errors.dart';
import '../interfaces/chat_repository_interface.dart';
import '../validators/chat_validator.dart';
import '../../../models/chat_model.dart';

class LoadMessagesUseCase {
  final IChatRepository _repository;
  
  LoadMessagesUseCase(this._repository);
  
  /// Execute the use case
  /// 
  /// Validates input, then delegates to repository
  /// Returns Result for type-safe error handling
  Future<Result<List<ChatMessage>>> execute({
    required String transactionId,
    bool useCache = true,
  }) async {
    // Validate input
    final validationError = ChatValidator.validateTransactionId(transactionId);
    if (validationError != null) {
      return Failure(validationError.message);
    }
    
    try {
      // Delegate to repository
      return await _repository.getMessages(
        transactionId.trim(),
        useCache: useCache,
      );
    } catch (e) {
      return Failure(
        UnknownError.fromException(e).message,
      );
    }
  }
}

