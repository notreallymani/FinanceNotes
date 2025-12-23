// Determine environment from NODE_ENV
const env = process.env.NODE_ENV || 'development';
const isProduction = env === 'production';

// Load environment-specific .env file
if (isProduction) {
  require('dotenv').config({ path: '.env.production' });
} else {
  require('dotenv').config({ path: '.env.dev' });
}

// Fallback: if specific env file doesn't exist, try .env
require('dotenv').config({ path: '.env' });

const config = {
  env,
  // Use port from env, or try 5001 if 5000 is busy, fallback to 5000
  port: parseInt(process.env.PORT) || 5001,
  
  // MongoDB Connection
  // Development: Use DEV_MONGO_URI or fallback to default local MongoDB
  // Production: Use MONGO_URI (required)
  mongoUri: (() => {
    if (isProduction) {
      if (!process.env.MONGO_URI) {
        console.error('❌ MONGO_URI is required for production');
        process.exit(1);
      }
      return process.env.MONGO_URI;
    } else {
      // Development: Try DEV_MONGO_URI, then MONGO_URI, then default
      return process.env.DEV_MONGO_URI || process.env.MONGO_URI || 'mongodb://localhost:27017/financenotes_dev';
    }
  })(),
  
  // JWT Secret
  jwtSecret: isProduction
    ? process.env.JWT_SECRET
    : process.env.DEV_JWT_SECRET || process.env.JWT_SECRET || 'dev_secret_change_me',
  
  // CORS Origin
  clientOrigin: isProduction
    ? process.env.CLIENT_ORIGIN
    : process.env.DEV_CLIENT_ORIGIN || process.env.CLIENT_ORIGIN || 'http://localhost:8081',
  
  // QuickeKYC API Configuration
  // Development: Use sandbox API (sandbox.quickekyc.com)
  // Production: Use production API (api.quickekyc.com)
  quickekycKey: isProduction
    ? process.env.QUICKEKYC_API_KEY
    : process.env.DEV_QUICKEKYC_API_KEY || process.env.QUICKEKYC_API_KEY || 'aab6c79a-a247-4f0d-ad38-ce2887ae4d3c', // Sandbox key default
  quickekycBaseUrl: isProduction
    ? 'https://api.quickekyc.com'
    : 'https://sandbox.quickekyc.com', // Sandbox URL for development
  
  /**
   * Google OAuth Web Client ID
   * 
   * IMPORTANT: This MUST match the serverClientId used in the Flutter app.
   * 
   * From google-services.json:
   * - This is the client_id with client_type: 3 (Web Client)
   * - NOT the Android Client ID (client_type: 1)
   * 
   * Why Web Client ID?
   * - Android Client ID tokens can only be verified by Google's Android SDK
   * - Web Client ID tokens can be verified by google-auth-library (Node.js)
   * - This allows the backend to verify tokens from mobile apps
   */
  googleClientId: isProduction
    ? process.env.GOOGLE_CLIENT_ID
    : process.env.DEV_GOOGLE_CLIENT_ID || process.env.GOOGLE_CLIENT_ID || 
      '136483005746-on8mm0vh6otio3ev71ntekemoaqblous.apps.googleusercontent.com',
  
  // Google Cloud Platform Configuration
  gcpProjectId: process.env.GCP_PROJECT_ID || 'financenotes-11ff0',
  gcpStorageBucket: process.env.GCP_STORAGE_BUCKET || 'financenotes-docs',
  gcpStorageKeyFile: process.env.GCP_STORAGE_KEY_FILE || './financenotes-11ff0-05155bafecde.json'
};

// Validate required production environment variables
if (isProduction) {
  const required = ['MONGO_URI', 'JWT_SECRET', 'GOOGLE_CLIENT_ID'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    console.error('❌ Missing required environment variables for production:');
    missing.forEach(key => console.error(`   - ${key}`));
    console.error('\nPlease set these in .env.production file');
    process.exit(1);
  }
}

module.exports = config;
