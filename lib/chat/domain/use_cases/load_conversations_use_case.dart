/// Load Conversations Use Case
/// 
/// High-level design: Use case pattern
/// Low-level design: Business logic for loading conversations

import '../../../core/result.dart';
import '../../../core/errors.dart';
import '../interfaces/chat_repository_interface.dart';
import '../../../models/chat_conversation_model.dart';

class LoadConversationsUseCase {
  final IChatRepository _repository;
  
  LoadConversationsUseCase(this._repository);
  
  /// Execute the use case
  Future<Result<List<ChatConversation>>> execute({
    bool useCache = true,
  }) async {
    try {
      return await _repository.getConversations(useCache: useCache);
    } catch (e) {
      return Failure(
        UnknownError.fromException(e).message,
      );
    }
  }
}

