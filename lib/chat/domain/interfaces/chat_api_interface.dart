/// Chat API Interface
/// 
/// High-level design: API abstraction layer
/// Low-level design: Abstract methods for network operations
/// 
/// Interface Segregation Principle: Clients depend only on methods they use

import '../../../core/result.dart';
import '../../../models/chat_model.dart';
import '../../../models/chat_conversation_model.dart';

abstract class IChatApi {
  /// Fetch messages for a transaction
  Future<Result<List<ChatMessage>>> getMessages(String transactionId);
  
  /// Send a message
  Future<Result<ChatMessage>> sendMessage({
    required String transactionId,
    required String message,
  });
  
  /// Get conversations list
  Future<Result<List<ChatConversation>>> getConversations();
  
  /// Get unread count
  Future<Result<int>> getUnreadCount();
}

