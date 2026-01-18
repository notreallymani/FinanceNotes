/// Chat Repository Implementation
/// 
/// High-level design: Concrete implementation of IChatRepository
/// Low-level design: Caching, deduplication, and data access orchestration
/// 
/// Single Responsibility: Data access with caching
/// Open/Closed: Extensible via interface

import '../../../core/result.dart';
import '../../../utils/api_cache.dart';
import '../../../utils/performance_utils.dart';
import '../../../models/chat_model.dart';
import '../../../models/chat_conversation_model.dart';
import '../../domain/interfaces/chat_repository_interface.dart';
import '../../domain/interfaces/chat_api_interface.dart';

class ChatRepositoryImpl implements IChatRepository {
  final IChatApi _api;
  final ApiCache _cache;
  final RequestDeduplicator _deduplicator;
  
  ChatRepositoryImpl({
    required IChatApi api,
    ApiCache? cache,
    RequestDeduplicator? deduplicator,
  })  : _api = api,
        _cache = cache ?? ApiCache(),
        _deduplicator = deduplicator ?? RequestDeduplicator();
  
  @override
  Future<Result<List<ChatMessage>>> getMessages(
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
          final chatMessages = messages
              .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
              .toList();
          return Success(chatMessages);
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }
    
    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('get_messages_$transactionId');
      final result = await _api.getMessages(transactionId);
      PerformanceMonitor.end('get_messages_$transactionId');
      
      // Cache on success
      if (result.isSuccess) {
        final messages = result.valueOrNull!;
        await _cache.put(cacheKey, {
          'messages': messages.map((m) => m.toJson()).toList(),
        });
        return Success(messages);
      } else {
        return Failure(result.errorOrNull!);
      }
    });
  }
  
  @override
  Future<Result<ChatMessage>> sendMessage({
    required String transactionId,
    required String message,
  }) async {
    PerformanceMonitor.start('send_message');
    final result = await _api.sendMessage(
      transactionId: transactionId,
      message: message,
    );
    PerformanceMonitor.end('send_message');
    
    // Invalidate cache on success
    if (result.isSuccess) {
      await invalidateTransactionCache(transactionId);
    }
    
    return result;
  }
  
  @override
  Future<Result<List<ChatConversation>>> getConversations({
    bool useCache = true,
  }) async {
    const cacheKey = 'chat_conversations';
    
    // Check cache first
    if (useCache) {
      final cachedData = await _cache.get(cacheKey);
      if (cachedData != null) {
        try {
          final List<dynamic> conversations = cachedData['conversations'] ?? [];
          final chatConversations = conversations
              .map((json) => ChatConversation.fromJson(json as Map<String, dynamic>))
              .toList();
          return Success(chatConversations);
        } catch (e) {
          // Cache invalid, continue to fetch
        }
      }
    }
    
    return await _deduplicator.deduplicate(cacheKey, () async {
      PerformanceMonitor.start('get_conversations');
      final result = await _api.getConversations();
      PerformanceMonitor.end('get_conversations');
      
      // Cache on success
      if (result.isSuccess) {
        final conversations = result.valueOrNull!;
        await _cache.put(cacheKey, {
          'conversations': conversations.map((c) => c.toJson()).toList(),
        });
        return Success(conversations);
      } else {
        return Failure(result.errorOrNull!);
      }
    });
  }
  
  @override
  Future<Result<int>> getUnreadCount() async {
    return await _api.getUnreadCount();
  }
  
  @override
  Future<void> clearCache() async {
    await _cache.clear();
  }
  
  @override
  Future<void> invalidateTransactionCache(String transactionId) async {
    await _cache.remove('chat_messages_$transactionId');
    await _cache.remove('chat_conversations');
  }
}

