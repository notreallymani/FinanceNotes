/// Chat Repository
/// 
/// Single Responsibility: Handles chat data access
/// Dependency Inversion: Depends on API abstraction

import '../api/chat_api.dart';
import '../models/chat_model.dart';
import '../models/chat_conversation_model.dart';
import '../utils/api_cache.dart';
import '../utils/performance_utils.dart';

class ChatRepository {
  final ChatApi _api;
  final ApiCache _cache;
  final RequestDeduplicator _deduplicator;

  ChatRepository({
    ChatApi? api,
    ApiCache? cache,
    RequestDeduplicator? deduplicator,
  })  : _api = api ?? ChatApi(),
        _cache = cache ?? ApiCache(),
        _deduplicator = deduplicator ?? RequestDeduplicator();

  /// Get messages for a transaction
  Future<List<ChatMessage>> getMessages(
    String transactionId, {
    bool useCache = true,
  }) async {
    final cacheKey = 'chat_messages_$transactionId';

    // Check cache first
    if (useCache) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> messages = cachedData['messages'] ?? [];
          return messages
              .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('get_messages_$transactionId');
      final messages = await _api.getMessages(transactionId);
      PerformanceMonitor.end('get_messages_$transactionId');

      // Cache the response
      await _cache.put(cacheKey, {
        'messages': messages.map((m) => m.toJson()).toList(),
      });

      return messages;
    });
  }

  /// Send message
  Future<ChatMessage> sendMessage({
    required String transactionId,
    required String message,
  }) async {
    PerformanceMonitor.start('send_message');
    final newMessage = await _api.sendMessage(
      transactionId: transactionId,
      message: message,
    );
    PerformanceMonitor.end('send_message');

    // Invalidate cache for this transaction's messages
    await _cache.remove('chat_messages_$transactionId');
    // Also invalidate conversations cache so the chat list updates
    await _cache.remove('chat_conversations');

    return newMessage;
  }

  /// Get conversations
  Future<List<ChatConversation>> getConversations({bool useCache = true}) async {
    const cacheKey = 'chat_conversations';

    // Check cache first
    if (useCache) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> conversations = cachedData['conversations'] ?? [];
          return conversations
              .map((json) => ChatConversation.fromJson(json as Map<String, dynamic>))
              .toList();
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }

    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('get_conversations');
      final conversations = await _api.getConversations();
      PerformanceMonitor.end('get_conversations');

      // Cache the response
      await _cache.put(cacheKey, {
        'conversations': conversations.map((c) => c.toJson()).toList(),
      });

      return conversations;
    });
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    return await _api.getUnreadCount();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await _cache.clear();
  }
}

