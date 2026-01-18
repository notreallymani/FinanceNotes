/// Chat Dependency Injection
/// 
/// High-level design: Dependency injection container
/// Low-level design: Factory pattern for creating dependencies
/// 
/// Dependency Inversion: Centralized dependency creation

import '../../core/result.dart';
import '../domain/interfaces/chat_repository_interface.dart';
import '../domain/interfaces/chat_api_interface.dart';
import '../domain/use_cases/load_messages_use_case.dart';
import '../domain/use_cases/send_message_use_case.dart';
import '../domain/use_cases/load_conversations_use_case.dart';
import '../domain/use_cases/get_unread_count_use_case.dart';
import '../data/api/chat_api_impl.dart';
import '../data/repository/chat_repository_impl.dart';

/// Chat Dependency Container
/// 
/// Provides all chat-related dependencies
/// Follows Singleton pattern for shared instances
class ChatDependencyContainer {
  // Lazy singletons
  IChatApi? _api;
  IChatRepository? _repository;
  LoadMessagesUseCase? _loadMessagesUseCase;
  SendMessageUseCase? _sendMessageUseCase;
  LoadConversationsUseCase? _loadConversationsUseCase;
  GetUnreadCountUseCase? _getUnreadCountUseCase;
  
  /// Get or create API instance
  IChatApi get api {
    _api ??= ChatApiImpl();
    return _api!;
  }
  
  /// Get or create repository instance
  IChatRepository get repository {
    _repository ??= ChatRepositoryImpl(api: api);
    return _repository!;
  }
  
  /// Get or create load messages use case
  LoadMessagesUseCase get loadMessagesUseCase {
    _loadMessagesUseCase ??= LoadMessagesUseCase(repository);
    return _loadMessagesUseCase!;
  }
  
  /// Get or create send message use case
  SendMessageUseCase get sendMessageUseCase {
    _sendMessageUseCase ??= SendMessageUseCase(repository);
    return _sendMessageUseCase!;
  }
  
  /// Get or create load conversations use case
  LoadConversationsUseCase get loadConversationsUseCase {
    _loadConversationsUseCase ??= LoadConversationsUseCase(repository);
    return _loadConversationsUseCase!;
  }
  
  /// Get or create get unread count use case
  GetUnreadCountUseCase get getUnreadCountUseCase {
    _getUnreadCountUseCase ??= GetUnreadCountUseCase(repository);
    return _getUnreadCountUseCase!;
  }
  
  /// Reset all dependencies (useful for testing)
  void reset() {
    _api = null;
    _repository = null;
    _loadMessagesUseCase = null;
    _sendMessageUseCase = null;
    _loadConversationsUseCase = null;
    _getUnreadCountUseCase = null;
  }
}

/// Global dependency container instance
final chatDependencies = ChatDependencyContainer();

