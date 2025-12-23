# Finance Notes Server

Backend API server for the Finance Notes Flutter application.

## Quick Start

### Prerequisites
- Node.js (v16 or higher)
- MongoDB (local or Atlas)
- Google Cloud Platform account (for Storage and OAuth)

### Installation

```bash
# Install dependencies
npm install

# Set up environment variables
# Create .env.dev for development and .env.production for production
# See environment variables section below
```

### Running the Server

**Development Mode:**
```bash
npm run dev
# or
npm run start:dev
```

**Production Mode:**
```bash
npm start
# or
npm run start:prod
```

The server will start on port 5000 (or the port specified in your `.env` file).

## Project Structure

```
server/
├── src/
│   ├── app.js              # Express app configuration
│   ├── config.js            # Environment configuration
│   ├── index.js             # Server entry point
│   ├── middleware/
│   │   └── auth.js          # JWT authentication middleware
│   ├── models/              # Mongoose models
│   │   ├── User.js
│   │   ├── Transaction.js
│   │   └── Otp.js
│   ├── routes/              # API routes
│   │   ├── auth.js          # Authentication endpoints
│   │   ├── profile.js       # User profile endpoints
│   │   ├── payment.js       # Payment/transaction endpoints
│   │   └── aadhar.js        # Aadhaar verification endpoints
│   └── services/            # Business logic services
│       ├── googleAuthService.js
│       └── jwtService.js
├── uploads/                 # Temporary file uploads (gitignored)
├── index.js                 # Main entry point
├── package.json
└── README.md               # This file
```

## API Endpoints

### Authentication
- `POST /api/auth/google` - Google OAuth sign-in
- `POST /api/auth/email-register` - Email/password registration
- `POST /api/auth/email-login` - Email/password login
- `GET /api/auth/me` - Get current user (requires auth)
- `POST /api/auth/change-password` - Change password (requires auth)
- `POST /api/auth/logout` - Logout

### Profile
- `GET /api/profile` - Get user profile (requires auth)
- `PUT /api/profile` - Update user profile (requires auth)

### Payments
- `POST /api/payment/send` - Create payment request (requires auth)
- `POST /api/payment/close` - Close payment (requires auth)
- `GET /api/payment/history` - Get payment history (requires auth)
- `GET /api/payment/all` - Get all user payments (requires auth)

### Aadhaar Verification
- `POST /api/aadhar/generate-otp` - Generate OTP for Aadhaar verification
- `POST /api/aadhar/verify-otp` - Verify OTP and complete Aadhaar verification

### Health Check
- `GET /api/health` - Server health check

## Environment Configuration

The server supports two environments:
- **Development**: Uses `.env.dev` file
- **Production**: Uses `.env.production` file

See environment variables section below for configuration.

## Required Credentials

Before running the server, ensure you have:

1. ✅ **MongoDB Connection String**
   - Development: `DEV_MONGO_URI`
   - Production: `MONGO_URI`

2. ✅ **JWT Secret**
   - Development: `DEV_JWT_SECRET`
   - Production: `JWT_SECRET`

3. ✅ **Google OAuth Web Client ID**
   - Development: `DEV_GOOGLE_CLIENT_ID`
   - Production: `GOOGLE_CLIENT_ID`

4. ✅ **Google Cloud Storage Service Account Key**
   - File path: `GCP_STORAGE_KEY_FILE`
   - Default: `./financenotes-11ff0-05155bafecde.json`

5. ✅ **CORS Origin**
   - Development: `DEV_CLIENT_ORIGIN`
   - Production: `CLIENT_ORIGIN`

6. ⚠️ **QuickeKYC API Key** (Optional)
   - Development: `DEV_QUICKEKYC_API_KEY`
   - Production: `QUICKEKYC_API_KEY`

See environment variables section below for required values.

## Development Notes

### OTP Verification
- **Development**: Uses fixed OTP `123456` for testing
- **Production**: Uses QuickeKYC API or local provider based on configuration

### File Uploads
- Files are temporarily stored in `uploads/` directory
- Then uploaded to Google Cloud Storage
- Temporary files should be cleaned up automatically

## Scripts

- `npm run dev` - Start development server with hot-reload
- `npm start` - Start production server
- `npm run start:dev` - Explicitly start development server
- `npm run start:prod` - Explicitly start production server

## Troubleshooting

### Server won't start
- Check that MongoDB is running and accessible
- Verify all required environment variables are set
- Check environment variables section below

### Google Sign-In fails
- Verify `GOOGLE_CLIENT_ID` matches Web Client ID (client_type: 3)
- Check `google-services.json` in Flutter app
- Verify Google Client ID matches Web Client ID (client_type: 3) from google-services.json

### File uploads fail
- Verify GCP Storage key file exists and is valid
- Check Google Cloud Storage bucket permissions
- Ensure service account has Storage Admin role

## Environment Variables

See `ENVIRONMENT_VARIABLES.md` for complete checklist of required and optional environment variables for both development and production.

### Quick Checklist

**Development (`.env.dev`):**
- ⚠️ `DEV_MONGO_URI` - MongoDB connection string
- ⚠️ `DEV_JWT_SECRET` - JWT secret (generate with `openssl rand -base64 32`)
- ⚠️ `GCP_STORAGE_BUCKET` - Storage bucket name

**Production (`.env.production`):**
- ⚠️ `MONGO_URI` - MongoDB connection string
- ⚠️ `JWT_SECRET` - JWT secret (generate with `openssl rand -base64 32`)
- ⚠️ `GOOGLE_CLIENT_ID` - Google OAuth Web Client ID
- ⚠️ `CLIENT_ORIGIN` - CORS origin (your backend API URL)
- ⚠️ `QUICKEKYC_API_KEY` - QuickeKYC API key (if using QuickeKYC)
- ⚠️ `GCP_STORAGE_BUCKET` - Storage bucket name

See `ENVIRONMENT_VARIABLES.md` for detailed information and templates.

## License

[Your License Here]

