/**
 * Error Handler Middleware
 * 
 * Single Responsibility: Centralized error handling
 * Open/Closed: Extendable with new error types
 */

const config = require('../config');

class AppError extends Error {
  constructor(message, statusCode = 500, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = isOperational;
    Error.captureStackTrace(this, this.constructor);
  }
}

class NotFoundError extends AppError {
  constructor(resource = 'Resource') {
    super(`${resource} not found`, 404);
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Unauthorized') {
    super(message, 401);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Forbidden') {
    super(message, 403);
  }
}

class ValidationError extends AppError {
  constructor(message = 'Validation failed', errors = {}) {
    super(message, 400);
    this.errors = errors;
  }
}

class ConflictError extends AppError {
  constructor(message = 'Resource conflict') {
    super(message, 409);
  }
}

/**
 * Global error handler middleware
 */
function errorHandler(err, req, res, next) {
  // Log error
  console.error(`[ERROR] ${req.method} ${req.path}:`, {
    message: err.message,
    stack: config.env === 'development' ? err.stack : undefined,
    statusCode: err.statusCode || 500,
  });

  // Handle known errors
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      success: false,
      message: err.message,
      errors: err.errors,
      ...(config.env === 'development' && { stack: err.stack }),
    });
  }

  // Handle validation errors
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: { [err.field || 'general']: err.message },
    });
  }

  // Handle MongoDB errors
  if (err.name === 'MongoServerError') {
    if (err.code === 11000) {
      const field = Object.keys(err.keyPattern)[0];
      return res.status(409).json({
        success: false,
        message: `${field} already exists`,
      });
    }
  }

  // Handle JWT errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token',
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token expired',
    });
  }

  // Default error
  return res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    ...(config.env === 'development' && { stack: err.stack }),
  });
}

/**
 * Async handler wrapper to catch errors
 */
function asyncHandler(fn) {
  return (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };
}

module.exports = {
  errorHandler,
  asyncHandler,
  AppError,
  NotFoundError,
  UnauthorizedError,
  ForbiddenError,
  ValidationError,
  ConflictError,
};

