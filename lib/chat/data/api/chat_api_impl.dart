/// Chat API Implementation
/// 
/// High-level design: Concrete implementation of IChatApi
/// Low-level design: HTTP client wrapper with error handling
/// 
/// Dependency Inversion: Implements interface, not concrete HTTP client

import 'package:dio/dio.dart';
import '../../../core/result.dart';
import '../../../core/errors.dart';
import '../../../utils/app_constants.dart';
import '../../../utils/http_client.dart';
import '../../../utils/logger.dart';
import '../../../models/chat_model.dart';
import '../../../models/chat_conversation_model.dart';
import '../../domain/interfaces/chat_api_interface.dart';

class ChatApiImpl implements IChatApi {
  final Dio _dio = HttpClient.instance;
  
  @override
  Future<Result<List<ChatMessage>>> getMessages(String transactionId) async {
    try {
      Logger.log('📤 Fetching chat messages for transaction: $transactionId');
      final response = await _dio.get(
        '${AppConstants.chatMessagesEndpoint}/$transactionId',
      );
      
      Logger.log('✅ Chat messages received');
      final List<dynamic> messages = response.data['messages'] ?? [];
      final chatMessages = messages
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
      
      return Success(chatMessages);
    } on DioException catch (e) {
      Logger.log('❌ Error fetching messages: $e');
      return _handleDioError(e);
    } catch (e) {
      Logger.log('❌ Unexpected error: $e');
      return Failure(UnknownError.fromException(e).message);
    }
  }
  
  @override
  Future<Result<ChatMessage>> sendMessage({
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
      final chatMessage = ChatMessage.fromJson(
        response.data['message'] ?? response.data,
      );
      
      return Success(chatMessage);
    } on DioException catch (e) {
      Logger.log('❌ Error sending message: $e');
      return _handleDioError(e);
    } catch (e) {
      Logger.log('❌ Unexpected error: $e');
      return Failure(UnknownError.fromException(e).message);
    }
  }
  
  @override
  Future<Result<List<ChatConversation>>> getConversations() async {
    try {
      Logger.log('📤 Fetching chat conversations');
      final response = await _dio.get(AppConstants.chatListEndpoint);
      Logger.log('✅ Chat conversations received: ${response.data}');
      
      final List<dynamic> conversations = response.data['conversations'] ?? [];
      Logger.log('📊 Found ${conversations.length} conversations');
      
      final parsedConversations = <ChatConversation>[];
      for (var json in conversations) {
        try {
          final conversation = ChatConversation.fromJson(
            json as Map<String, dynamic>,
          );
          parsedConversations.add(conversation);
        } catch (e) {
          Logger.log('❌ Error parsing conversation: $e');
          Logger.log('❌ Conversation data: $json');
          // Continue with other conversations
        }
      }
      
      Logger.log('✅ Successfully parsed ${parsedConversations.length} conversations');
      return Success(parsedConversations);
    } on DioException catch (e) {
      Logger.log('❌ Error fetching conversations: $e');
      return _handleDioError(e);
    } catch (e) {
      Logger.log('❌ Unexpected error: $e');
      return Failure(UnknownError.fromException(e).message);
    }
  }
  
  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final response = await _dio.get(AppConstants.unreadCountEndpoint);
      final count = response.data['count'] ?? 0;
      return Success(count as int);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return Failure(UnknownError.fromException(e).message);
    }
  }
  
  /// Handle Dio errors and convert to Result
  Result<T> _handleDioError<T>(DioException error) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode ?? 500;
      final message = error.response?.data['message'] ?? 
                     error.response?.data['error'] ?? 
                     'Server error';
      
      return Failure(
        ServerError.fromResponse(statusCode, message).message,
      );
    } else if (error.type == DioExceptionType.connectionTimeout ||
               error.type == DioExceptionType.receiveTimeout ||
               error.type == DioExceptionType.sendTimeout) {
      return Failure(
        NetworkError(message: 'Connection timeout').message,
      );
    } else {
      return Failure(
        NetworkError.fromException(error).message,
      );
    }
  }
}

