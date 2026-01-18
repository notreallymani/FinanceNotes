# Chat Module - Clean Architecture

## High-Level Design

This module follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (UI State Management - ChatProvider)   │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Domain Layer                   │
│  (Business Logic - Use Cases)           │
│  - LoadMessagesUseCase                  │
│  - SendMessageUseCase                   │
│  - LoadConversationsUseCase             │
│  - GetUnreadCountUseCase                │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│          Data Layer                     │
│  (Data Access - Repository)             │
│  - ChatRepositoryImpl                   │
│  - ChatApiImpl                          │
└─────────────────────────────────────────┘
```

## Architecture Principles

### 1. **Dependency Inversion Principle (DIP)**
- High-level modules (Use Cases) depend on abstractions (Interfaces)
- Low-level modules (Implementations) implement interfaces
- Dependencies flow inward: Presentation → Domain → Data

### 2. **Single Responsibility Principle (SRP)**
- Each class has one reason to change
- Use Cases: One business operation each
- Repository: Data access only
- Provider: State management only

### 3. **Open/Closed Principle (OCP)**
- Open for extension, closed for modification
- New features added via new use cases
- Existing code remains unchanged

### 4. **Interface Segregation Principle (ISP)**
- Interfaces are small and focused
- Clients depend only on methods they use
- `IChatApi` and `IChatRepository` are separate

### 5. **Liskov Substitution Principle (LSP)**
- Implementations can be swapped without breaking code
- Any `IChatRepository` implementation works with use cases

## Low-Level Design

### Result Type Pattern
Uses functional programming approach for error handling:
```dart
Result<T> // Sealed class with Success<T> and Failure<T> variants
```

Benefits:
- Type-safe error handling
- No exceptions for expected failures
- Composable operations (map, flatMap, fold)

### Dependency Injection
Centralized dependency creation:
```dart
chatDependencies.loadMessagesUseCase
chatDependencies.sendMessageUseCase
```

Benefits:
- Easy testing (mock dependencies)
- Loose coupling
- Single source of truth

### Validation Layer
Separate validation logic:
```dart
ChatValidator.validateTransactionId()
ChatValidator.validateMessage()
```

Benefits:
- Reusable validation
- Clear error messages
- Business rules in one place

## File Structure

```
lib/chat/
├── domain/                    # Business Logic Layer
│   ├── interfaces/            # Abstractions
│   │   ├── chat_api_interface.dart
│   │   └── chat_repository_interface.dart
│   ├── use_cases/             # Business Operations
│   │   ├── load_messages_use_case.dart
│   │   ├── send_message_use_case.dart
│   │   ├── load_conversations_use_case.dart
│   │   └── get_unread_count_use_case.dart
│   └── validators/            # Input Validation
│       └── chat_validator.dart
├── data/                      # Data Access Layer
│   ├── api/                   # Network Layer
│   │   └── chat_api_impl.dart
│   └── repository/            # Data Repository
│       └── chat_repository_impl.dart
├── presentation/              # UI Layer
│   └── chat_provider_refactored.dart
├── di/                        # Dependency Injection
│   └── chat_dependency_injection.dart
└── README.md                  # This file
```

## Usage

### In Provider
```dart
final chatProvider = ChatProvider(); // Uses DI container
await chatProvider.loadConversations();
```

### Direct Use Case Usage
```dart
final useCase = chatDependencies.loadMessagesUseCase;
final result = await useCase.execute(transactionId: '...');
result.fold(
  onSuccess: (messages) => print('Got ${messages.length} messages'),
  onFailure: (error) => print('Error: $error'),
);
```

## Testing

Easy to test with dependency injection:
```dart
// Mock repository
final mockRepo = MockChatRepository();
final useCase = LoadMessagesUseCase(mockRepo);
final provider = ChatProvider(loadMessagesUseCase: useCase);
```

## Benefits

1. **Maintainability**: Clear separation of concerns
2. **Testability**: Easy to mock dependencies
3. **Scalability**: Easy to add new features
4. **Type Safety**: Result type prevents null errors
5. **Error Handling**: Explicit error types
6. **Reusability**: Use cases can be used independently

## Migration from Old Code

The old `ChatProvider` is still available for backward compatibility.
To migrate:
1. Update imports to use `chat/presentation/chat_provider_refactored.dart`
2. No API changes - same methods and properties
3. Better error handling and type safety

