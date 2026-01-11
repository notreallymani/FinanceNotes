/// Chat Provider (Refactored with SOLID Principles)
/// 
/// Single Responsibility: State management only
/// Dependency Inversion: Depends on use case abstraction

import 'package:flutter/foundation.dart';
import '../use_cases/chat_use_case.dart';
import '../repositories/chat_repository.dart';
import '../models/chat_model.dart';
import '../models/chat_conversation_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatUseCase _useCase;

  ChatProvider({ChatUseCase? useCase})
      : _useCase = useCase ?? ChatUseCase(ChatRepository());

  List<ChatMessage> _messages = [];
  List<ChatConversation> _conversations = [];
  bool _isLoading = false;
  String? _error;
  String? _currentTransactionId;

  List<ChatMessage> get messages => _messages;
  List<ChatConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentTransactionId => _currentTransactionId;

  /// Load messages for a transaction
  Future<bool> loadMessages(String transactionId, {bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    _currentTransactionId = transactionId;
    notifyListeners();

    final result = await _useCase.loadMessages(transactionId, useCache: useCache);

    _isLoading = false;
    if (result.success && result.messages != null) {
      _messages = result.messages!;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Load conversations
  Future<bool> loadConversations({bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _useCase.loadConversations(useCache: useCache);

    _isLoading = false;
    if (result.success && result.conversations != null) {
      _conversations = result.conversations!;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Send message
  Future<bool> sendMessage(String transactionId, String message) async {
    final result = await _useCase.sendMessage(
      transactionId: transactionId,
      message: message,
    );

    if (result.success && result.message != null) {
      _messages.add(result.message!);
      _error = null;
      notifyListeners();
      
      // Refresh conversations list to update last message (don't wait for it)
      loadConversations(useCache: false).catchError((_) {
        // Silently fail - user can manually refresh
        return false;
      });
      
      return true;
    } else {
      _error = result.error;
      notifyListeners();
      return false;
    }
  }

  void addMessage(ChatMessage message) {
    if (!_messages.any((m) => m.id == message.id)) {
      _messages.add(message);
      notifyListeners();
    }
  }

  void clearMessages() {
    _messages = [];
    _currentTransactionId = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

