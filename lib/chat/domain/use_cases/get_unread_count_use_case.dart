/// Get Unread Count Use Case
/// 
/// High-level design: Use case pattern
/// Low-level design: Business logic for getting unread count

import '../../../core/result.dart';
import '../../../core/errors.dart';
import '../interfaces/chat_repository_interface.dart';

class GetUnreadCountUseCase {
  final IChatRepository _repository;
  
  GetUnreadCountUseCase(this._repository);
  
  /// Execute the use case
  Future<Result<int>> execute() async {
    try {
      return await _repository.getUnreadCount();
    } catch (e) {
      return Failure(
        UnknownError.fromException(e).message,
      );
    }
  }
}

