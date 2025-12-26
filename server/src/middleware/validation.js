/**
 * Validation Middleware
 * 
 * Single Responsibility: Validates request data
 * Open/Closed: Extendable with new validators
 */

class ValidationError extends Error {
  constructor(message, field) {
    super(message);
    this.name = 'ValidationError';
    this.field = field;
    this.statusCode = 400;
  }
}

/**
 * Validate email format
 */
function validateEmail(email) {
  if (!email) {
    throw new ValidationError('Email is required', 'email');
  }
  
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new ValidationError('Invalid email format', 'email');
  }
  
  return email.toLowerCase().trim();
}

/**
 * Validate password
 */
function validatePassword(password) {
  if (!password) {
    throw new ValidationError('Password is required', 'password');
  }
  
  if (password.length < 6) {
    throw new ValidationError('Password must be at least 6 characters', 'password');
  }
  
  return password;
}

/**
 * Validate Aadhaar
 */
function validateAadhar(aadhar) {
  if (!aadhar) {
    throw new ValidationError('Aadhaar is required', 'aadhar');
  }
  
  const aadharRegex = /^\d{12}$/;
  if (!aadharRegex.test(aadhar)) {
    throw new ValidationError('Aadhaar must be 12 digits', 'aadhar');
  }
  
  return aadhar;
}

/**
 * Validate phone
 */
function validatePhone(phone) {
  if (!phone) {
    return null; // Optional
  }
  
  const phoneRegex = /^\d{10}$/;
  if (!phoneRegex.test(phone)) {
    throw new ValidationError('Phone must be 10 digits', 'phone');
  }
  
  return phone;
}

/**
 * Validate OTP
 */
function validateOtp(otp) {
  if (!otp) {
    throw new ValidationError('OTP is required', 'otp');
  }
  
  const otpRegex = /^\d{6}$/;
  if (!otpRegex.test(otp)) {
    throw new ValidationError('OTP must be 6 digits', 'otp');
  }
  
  return otp;
}

/**
 * Validate amount
 */
function validateAmount(amount) {
  if (amount === undefined || amount === null) {
    throw new ValidationError('Amount is required', 'amount');
  }
  
  const numAmount = parseFloat(amount);
  if (isNaN(numAmount) || numAmount <= 0) {
    throw new ValidationError('Amount must be a positive number', 'amount');
  }
  
  return numAmount;
}

/**
 * Validation middleware factory
 */
function validate(schema) {
  return (req, res, next) => {
    try {
      const errors = {};
      
      for (const [field, validator] of Object.entries(schema)) {
        try {
          const value = req.body[field];
          const validated = validator(value);
          req.body[field] = validated;
        } catch (error) {
          if (error instanceof ValidationError) {
            errors[error.field] = error.message;
          } else {
            errors[field] = error.message;
          }
        }
      }
      
      if (Object.keys(errors).length > 0) {
        return res.status(400).json({
          message: 'Validation failed',
          errors,
        });
      }
      
      next();
    } catch (error) {
      return res.status(500).json({
        message: 'Validation error',
        error: error.message,
      });
    }
  };
}

module.exports = {
  validate,
  validateEmail,
  validatePassword,
  validateAadhar,
  validatePhone,
  validateOtp,
  validateAmount,
  ValidationError,
};

