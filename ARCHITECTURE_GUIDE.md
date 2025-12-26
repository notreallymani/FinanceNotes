# Architecture Guide - SOLID Principles & Design Patterns

## 🏗️ Architecture Overview

This document describes the refactored architecture following SOLID principles and design patterns for both backend and frontend.

---

## 📋 SOLID Principles Applied

### **S - Single Responsibility Principle**
- Each class/function has one reason to change
- Services handle business logic only
- Repositories handle data access only
- Routes handle HTTP only

### **O - Open/Closed Principle**
- Open for extension, closed for modification
- Base classes can be extended without changing base code
- New features added through inheritance/composition

### **L - Liskov Substitution Principle**
- Derived classes can replace base classes
- All repositories can be used interchangeably
- All services follow same interface

### **I - Interface Segregation Principle**
- Clients depend only on interfaces they use
- Small, focused interfaces
- No forced implementation of unused methods

### **D - Dependency Inversion Principle**
- High-level modules don't depend on low-level modules
- Both depend on abstractions
- Dependency injection throughout

---

## 🔧 Backend Architecture

### **Layer Structure**

```
┌─────────────────────────────────────┐
│         Routes (HTTP Layer)         │  ← Handles HTTP requests/responses
├─────────────────────────────────────┤
│         Services (Business Logic)    │  ← Business rules and orchestration
├─────────────────────────────────────┤
│      Repositories (Data Access)     │  ← Database operations
├─────────────────────────────────────┤
│         Models (Data Models)        │  ← Data structure
└─────────────────────────────────────┘
```

### **1. Routes Layer** (`server/src/routes/`)
- **Responsibility**: HTTP request/response handling
- **Dependencies**: Services, Middleware
- **Example**: `auth.refactored.js`

```javascript
// Routes only handle HTTP, delegate to services
router.post('/email-login', 
  validate({ email: validateEmail, password: validatePassword }),
  asyncHandler(async (req, res) => {
    const result = await authService.loginWithEmail(req.body.email, req.body.password);
    res.json({ success: true, ...result });
  })
);
```

### **2. Services Layer** (`server/src/services/`)
- **Responsibility**: Business logic and orchestration
- **Dependencies**: Repositories, Other Services
- **Example**: `AuthService.js`

```javascript
// Services contain business logic
class AuthService {
  async loginWithEmail(email, password) {
    const user = await userRepository.findByEmail(email);
    if (!user || !user.passwordHash) {
      throw new Error('Invalid credentials');
    }
    const isValid = await bcrypt.compare(password, user.passwordHash);
    if (!isValid) {
      throw new Error('Invalid credentials');
    }
    return { user, token: jwtService.generateToken(user) };
  }
}
```

### **3. Repositories Layer** (`server/src/repositories/`)
- **Responsibility**: Data access operations
- **Dependencies**: Models only
- **Example**: `UserRepository.js`

```javascript
// Repositories handle only data access
class UserRepository extends BaseRepository {
  async findByEmail(email) {
    return await this.findOne({ email: email.toLowerCase().trim() });
  }
  
  async createUser(userData) {
    // Validation and duplicate checking
    return await this.create(userData);
  }
}
```

### **4. Middleware** (`server/src/middleware/`)
- **Validation**: `validation.js` - Request validation
- **Error Handling**: `errorHandler.js` - Centralized error handling
- **Authentication**: `auth.js` - JWT verification

---

## 📱 Frontend Architecture

### **Layer Structure**

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)           │  ← User interface
├─────────────────────────────────────┤
│         Providers (State)            │  ← State management
├─────────────────────────────────────┤
│      Use Cases (Business Logic)      │  ← Business rules
├─────────────────────────────────────┤
│      Repositories (Data Access)      │  ← API calls
├─────────────────────────────────────┤
│         API Layer                    │  ← HTTP requests
└─────────────────────────────────────┘
```

### **1. UI Layer** (`lib/screens/`)
- **Responsibility**: User interface only
- **Dependencies**: Providers, Use Cases
- **No business logic**

### **2. Providers** (`lib/providers/`)
- **Responsibility**: State management
- **Dependencies**: Use Cases
- **Thin layer** - delegates to use cases

### **3. Use Cases** (`lib/use_cases/`)
- **Responsibility**: Business logic
- **Dependencies**: Repositories
- **Example**: `auth_use_case.dart`

```dart
// Use cases contain business logic
class AuthUseCase {
  Future<AuthResult> loginWithEmail({required String email, required String password}) async {
    if (email.isEmpty || password.isEmpty) {
      return AuthResult.failure('Email and password are required');
    }
    return await _repository.loginWithEmail(email: email, password: password);
  }
}
```

### **4. Repositories** (`lib/repositories/`)
- **Responsibility**: Data access
- **Dependencies**: API layer
- **Example**: `auth_repository.dart`

```dart
// Repositories handle data access
class AuthRepository {
  Future<AuthResult> loginWithEmail({required String email, required String password}) async {
    final response = await _api.loginWithEmail(email: email, password: password);
    await _storage.write(key: AppConstants.tokenKey, value: response['token']);
    return AuthResult(user: UserModel.fromJson(response['user']), token: response['token']);
  }
}
```

### **5. API Layer** (`lib/api/`)
- **Responsibility**: HTTP communication
- **Dependencies**: HTTP client only
- **No business logic**

---

## 🎯 Design Patterns Used

### **1. Repository Pattern**
- **Purpose**: Abstract data access
- **Benefits**: Easy to test, swap data sources
- **Location**: `server/src/repositories/`, `lib/repositories/`

### **2. Service Layer Pattern**
- **Purpose**: Encapsulate business logic
- **Benefits**: Reusable, testable
- **Location**: `server/src/services/`

### **3. Use Case Pattern** (Frontend)
- **Purpose**: Encapsulate business logic
- **Benefits**: Single responsibility, testable
- **Location**: `lib/use_cases/`

### **4. Dependency Injection**
- **Purpose**: Loose coupling
- **Benefits**: Testable, flexible
- **Implementation**: Constructor injection

### **5. Factory Pattern**
- **Purpose**: Create objects
- **Benefits**: Flexible object creation
- **Example**: BaseRepository factory

### **6. Strategy Pattern**
- **Purpose**: Interchangeable algorithms
- **Benefits**: Flexible behavior
- **Example**: Different auth strategies

---

## 🚀 Performance Optimizations

### **Backend**
- ✅ Connection pooling (MongoDB)
- ✅ Request deduplication
- ✅ Caching layer
- ✅ Async/await for non-blocking I/O
- ✅ Error handling without try-catch overhead

### **Frontend**
- ✅ API response caching
- ✅ Request deduplication
- ✅ Skeleton loaders
- ✅ Lazy loading
- ✅ Optimized navigation

---

## 📝 Code Examples

### **Backend: Refactored Route**

```javascript
// Before: Business logic in route
router.post('/email-login', async (req, res) => {
  const user = await User.findOne({ email });
  const isValid = await bcrypt.compare(password, user.passwordHash);
  // ... more logic
});

// After: Route delegates to service
router.post('/email-login',
  validate({ email: validateEmail, password: validatePassword }),
  asyncHandler(async (req, res) => {
    const result = await authService.loginWithEmail(req.body.email, req.body.password);
    res.json({ success: true, ...result });
  })
);
```

### **Frontend: Refactored Provider**

```dart
// Before: Business logic in provider
class AuthProvider {
  Future<bool> loginWithEmail(String email, String password) async {
    if (email.isEmpty) return false;
    final response = await _api.loginWithEmail(email, password);
    // ... more logic
  }
}

// After: Provider delegates to use case
class AuthProvider {
  final AuthUseCase _useCase;
  
  Future<bool> loginWithEmail(String email, String password) async {
    final result = await _useCase.loginWithEmail(email: email, password: password);
    if (result.success) {
      _user = result.user;
      notifyListeners();
    }
    return result.success;
  }
}
```

---

## ✅ Benefits

1. **Testability**: Each layer can be tested independently
2. **Maintainability**: Changes isolated to specific layers
3. **Scalability**: Easy to add new features
4. **Reusability**: Services/use cases can be reused
5. **Performance**: Optimized data access and caching
6. **Type Safety**: Strong typing throughout

---

## 🔄 Migration Path

1. **Phase 1**: Create new architecture (✅ Done)
2. **Phase 2**: Refactor auth routes (In Progress)
3. **Phase 3**: Refactor other routes
4. **Phase 4**: Refactor frontend providers
5. **Phase 5**: Add comprehensive tests

---

**This architecture follows industry best practices and ensures high performance, maintainability, and scalability!** 🚀

