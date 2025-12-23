import 'package:dio/dio.dart';
import '../utils/app_constants.dart';
import '../models/chat_model.dart';
import '../models/chat_conversation_model.dart';
import '../utils/http_client.dart';
import '../utils/logger.dart';

class ChatApi {
  final Dio _dio = HttpClient.instance;

  Future<List<ChatMessage>> getMessages(String transactionId) async {
    try {
      Logger.log('📤 Fetching chat messages for transaction: $transactionId');
      final response = await _dio.get(
        '${AppConstants.chatMessagesEndpoint}/$transactionId',
      );
      Logger.log('✅ Chat messages received');
      final List<dynamic> messages = response.data['messages'] ?? [];
      return messages.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ChatMessage> sendMessage({
    required String transactionId,
    required String message,
  }) async {
    try {
      Logger.log('📤 Sending chat message');
      final response = await _dio.post(
        AppConstants.sendChatMessageEndpoint,
        data: {
          'transactionId': transactionId,
          'message': message,
        },
      );
      Logger.log('✅ Chat message sent');
      return ChatMessage.fromJson(response.data['message'] ?? response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ChatConversation>> getConversations() async {
    try {
      Logger.log('📤 Fetching chat conversations');
      final response = await _dio.get(AppConstants.chatListEndpoint);
      Logger.log('✅ Chat conversations received');
      final List<dynamic> conversations = response.data['conversations'] ?? [];
      return conversations
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _dio.get(AppConstants.unreadCountEndpoint);
      return response.data['count'] ?? 0;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final message = error.response?.data['message'] ?? 
                       error.response?.data['error'] ?? 
                       'An error occurred';
        return Exception(message);
      } else {
        Logger.log('Network error: ${error.message}');
        return Exception('Network error');
      }
    }
    return Exception('Unexpected error: $error');
  }
}

