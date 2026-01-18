/// Chat Repository Interface
/// 
/// High-level design: Repository pattern with interface
/// Low-level design: Abstract methods for data operations
/// 
/// Dependency Inversion Principle: Depend on abstractions, not concretions

import '../../../core/result.dart';
import '../../../models/chat_model.dart';
import '../../../models/chat_conversation_model.dart';

abstract class IChatRepository {
  /// Get messages for a transaction
  /// Returns Result<List<ChatMessage>> for type-safe error handling
  Future<Result<List<ChatMessage>>> getMessages(
    String transactionId, {
    bool useCache = true,
  });
  
  /// Send a message
  /// Returns Result<ChatMessage> with the sent message or error
  Future<Result<ChatMessage>> sendMessage({
    required String transactionId,
    required String message,
  });
  
  /// Get all conversations for current user
  /// Returns Result<List<ChatConversation>> with conversations or error
  Future<Result<List<ChatConversation>>> getConversations({
    bool useCache = true,
  });
  
  /// Get unread message count
  /// Returns Result<int> with count or error
  Future<Result<int>> getUnreadCount();
  
  /// Clear cache for chat data
  Future<void> clearCache();
  
  /// Invalidate cache for specific transaction
  Future<void> invalidateTransactionCache(String transactionId);
}

