import 'package:flutter/foundation.dart';
import '../api/chat_api.dart';
import '../models/chat_model.dart';
import '../models/chat_conversation_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatApi _api = ChatApi();

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

  Future<bool> loadMessages(String transactionId) async {
    _isLoading = true;
    _error = null;
    _currentTransactionId = transactionId;
    notifyListeners();

    try {
      _messages = await _api.getMessages(transactionId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _api.getConversations();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendMessage(String transactionId, String message) async {
    if (message.trim().isEmpty) return false;

    try {
      final newMessage = await _api.sendMessage(
        transactionId: transactionId,
        message: message.trim(),
      );
      _messages.add(newMessage);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
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

