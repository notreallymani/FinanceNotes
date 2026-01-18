/// Chat Provider (Refactored with Clean Architecture)
/// 
/// High-level design: Presentation layer state management
/// Low-level design: Uses use cases, handles Result types
/// 
/// Single Responsibility: UI state management only
/// Dependency Inversion: Depends on use case abstractions

import 'package:flutter/foundation.dart';
import '../../models/chat_model.dart';
import '../../models/chat_conversation_model.dart';
import '../domain/use_cases/load_messages_use_case.dart';
import '../domain/use_cases/send_message_use_case.dart';
import '../domain/use_cases/load_conversations_use_case.dart';
import '../domain/use_cases/get_unread_count_use_case.dart';
import '../di/chat_dependency_injection.dart';

class ChatProvider with ChangeNotifier {
  // Use cases (injected via DI)
  final LoadMessagesUseCase _loadMessagesUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final LoadConversationsUseCase _loadConversationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  
  // State
  List<ChatMessage> _messages = [];
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  String? _currentTransactionId;
  int _unreadCount = 0;
  
  ChatProvider({
    LoadMessagesUseCase? loadMessagesUseCase,
    SendMessageUseCase? sendMessageUseCase,
    LoadConversationsUseCase? loadConversationsUseCase,
    GetUnreadCountUseCase? getUnreadCountUseCase,
  })  : _loadMessagesUseCase = loadMessagesUseCase ?? chatDependencies.loadMessagesUseCase,
        _sendMessageUseCase = sendMessageUseCase ?? chatDependencies.sendMessageUseCase,
        _loadConversationsUseCase = loadConversationsUseCase ?? chatDependencies.loadConversationsUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase ?? chatDependencies.getUnreadCountUseCase;
  
  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentTransactionId => _currentTransactionId;
  int get unreadCount => _unreadCount;
  
  /// Load messages for a transaction
  Future<bool> loadMessages(String transactionId, {bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    _currentTransactionId = transactionId;
    notifyListeners();
    
    final result = await _loadMessagesUseCase.execute(
      transactionId: transactionId,
      useCache: useCache,
    );
    
    _isLoading = false;
    
    return result.fold(
      onSuccess: (messages) {
        _messages = messages;
        _error = null;
        debugPrint('[ChatProvider] Loaded ${messages.length} messages');
        notifyListeners();
        return true;
      },
      onFailure: (error) {
        _error = error;
        debugPrint('[ChatProvider] Error loading messages: $error');
        notifyListeners();
        return false;
      },
    );
  }
  
  /// Load conversations
  Future<bool> loadConversations({bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    final result = await _loadConversationsUseCase.execute(useCache: useCache);
    
    _isLoading = false;
    
    return result.fold(
      onSuccess: (conversations) {
        _conversations = conversations;
        _error = null;
        debugPrint('[ChatProvider] Loaded ${conversations.length} conversations');
        notifyListeners();
        return true;
      },
      onFailure: (error) {
        _error = error;
        debugPrint('[ChatProvider] Error loading conversations: $error');
        notifyListeners();
        return false;
      },
    );
  }
  
  /// Send a message
  Future<bool> sendMessage(String transactionId, String message) async {
    final result = await _sendMessageUseCase.execute(
      transactionId: transactionId,
      message: message,
    );
    
    return result.fold(
      onSuccess: (newMessage) {
        _messages.add(newMessage);
        _error = null;
        notifyListeners();
        
        // Refresh conversations list in background (don't wait)
        loadConversations(useCache: false).catchError((_) {
          debugPrint('[ChatProvider] Failed to refresh conversations after send');
          return false;
        });
        
        return true;
      },
      onFailure: (error) {
        _error = error;
        debugPrint('[ChatProvider] Error sending message: $error');
        notifyListeners();
        return false;
      },
    );
  }
  
  /// Load unread count
  Future<void> loadUnreadCount() async {
    final result = await _getUnreadCountUseCase.execute();
    
    result.fold(
      onSuccess: (count) {
        _unreadCount = count;
        notifyListeners();
      },
      onFailure: (error) {
        debugPrint('[ChatProvider] Error loading unread count: $error');
        _unreadCount = 0;
      },
    );
  }
  
  /// Add message to local state (for real-time updates)
  void addMessage(ChatMessage message) {
    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message);
      notifyListeners();
    }
  }
  
  /// Clear messages
  void clearMessages() {
    _messages = [];
    _currentTransactionId = null;
    _error = null;
    notifyListeners();
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  /// Update conversation in list (for real-time updates)
  void updateConversation(ChatConversation conversation) {
    final index = _conversations.indexWhere(
      (c) => c.transactionId == conversation.transactionId,
    );
    
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.insert(0, conversation);
    }
    
    // Sort by last message time
    _conversations.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? DateTime(1970);
      final bTime = b.lastMessage?.createdAt ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });
    
    notifyListeners();
  }
}

