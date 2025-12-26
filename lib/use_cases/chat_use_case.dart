/// Chat Use Case
/// 
/// Single Responsibility: Handles chat business logic
/// Dependency Inversion: Depends on repository abstractions

import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/chat_conversation_model.dart';

class ChatUseCase {
  final ChatRepository _repository;

  ChatUseCase(this._repository);

  /// Load messages for a transaction
  Future<ChatMessagesResult> loadMessages(
    String transactionId, {
    bool useCache = true,
  }) async {
    if (transactionId.isEmpty) {
      return ChatMessagesResult.failure('Transaction ID is required');
    }

    try {
      final messages = await _repository.getMessages(
        transactionId,
        useCache: useCache,
      );
      return ChatMessagesResult.success(messages);
    } catch (e) {
      return ChatMessagesResult.failure(e.toString());
    }
  }

  /// Send message
  Future<ChatMessageResult> sendMessage({
    required String transactionId,
    required String message,
  }) async {
    if (transactionId.isEmpty) {
      return ChatMessageResult.failure('Transaction ID is required');
    }

    if (message.trim().isEmpty) {
      return ChatMessageResult.failure('Message cannot be empty');
    }

    if (message.length > 1000) {
      return ChatMessageResult.failure('Message is too long (max 1000 characters)');
    }

    try {
      final newMessage = await _repository.sendMessage(
        transactionId: transactionId,
        message: message.trim(),
      );
      return ChatMessageResult.success(newMessage);
    } catch (e) {
      return ChatMessageResult.failure(e.toString());
    }
  }

  /// Load conversations
  Future<ChatConversationsResult> loadConversations({bool useCache = true}) async {
    try {
      final conversations = await _repository.getConversations(useCache: useCache);
      return ChatConversationsResult.success(conversations);
    } catch (e) {
      return ChatConversationsResult.failure(e.toString());
    }
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    try {
      return await _repository.getUnreadCount();
    } catch (e) {
      return 0;
    }
  }
}

/// Chat Messages Result
class ChatMessagesResult {
  final bool success;
  final List<ChatMessage>? messages;
  final String? error;

  ChatMessagesResult._({
    required this.success,
    this.messages,
    this.error,
  });

  factory ChatMessagesResult.success(List<ChatMessage> messages) {
    return ChatMessagesResult._(
      success: true,
      messages: messages,
    );
  }

  factory ChatMessagesResult.failure(String error) {
    return ChatMessagesResult._(
      success: false,
      error: error,
    );
  }
}

/// Chat Message Result
class ChatMessageResult {
  final bool success;
  final ChatMessage? message;
  final String? error;

  ChatMessageResult._({
    required this.success,
    this.message,
    this.error,
  });

  factory ChatMessageResult.success(ChatMessage message) {
    return ChatMessageResult._(
      success: true,
      message: message,
    );
  }

  factory ChatMessageResult.failure(String error) {
    return ChatMessageResult._(
      success: false,
      error: error,
    );
  }
}

/// Chat Conversations Result
class ChatConversationsResult {
  final bool success;
  final List<ChatConversation>? conversations;
  final String? error;

  ChatConversationsResult._({
    required this.success,
    this.conversations,
    this.error,
  });

  factory ChatConversationsResult.success(List<ChatConversation> conversations) {
    return ChatConversationsResult._(
      success: true,
      conversations: conversations,
    );
  }

  factory ChatConversationsResult.failure(String error) {
    return ChatConversationsResult._(
      success: false,
      error: error,
    );
  }
}

