const mongoose = require('mongoose');
const app = require('./app');
const config = require('./config');

async function start() {
  try {
    // Connect to MongoDB with timeout
    console.log(`🔌 Connecting to MongoDB...`);
    console.log(`   URI: ${config.mongoUri.replace(/\/\/[^:]+:[^@]+@/, '//***:***@')}`); // Hide credentials if any
    
    if (!config.mongoUri || typeof config.mongoUri !== 'string') {
      console.error('❌ MongoDB URI is not configured!');
      console.error('   For development, set DEV_MONGO_URI in .env.dev');
      console.error('   Example: DEV_MONGO_URI=mongodb://localhost:27017/financenotes_dev');
      process.exit(1);
    }
    
    try {
      await mongoose.connect(config.mongoUri, {
        serverSelectionTimeoutMS: 5000, // Timeout after 5 seconds
        socketTimeoutMS: 45000,
      });
      console.log(`✅ MongoDB connected successfully`);
    } catch (error) {
      console.error('❌ MongoDB connection failed:', error.message);
      if (error.message.includes('ECONNREFUSED')) {
        console.error('   MongoDB is not running or not accessible');
        console.error('   Please start MongoDB or check your connection string');
        console.error(`   Attempted URI: ${config.mongoUri}`);
      }
      throw error;
    }

    // Start server - bind to 0.0.0.0 to allow network access
    const server = app.listen(config.port, '0.0.0.0', () => {
      console.log(`🚀 Server running in ${config.env} mode`);
      console.log(`📡 Listening on port ${config.port}`);
      console.log(`🌐 Health check: http://localhost:${config.port}/api/health`);
      console.log(`🌐 Network access: http://10.118.84.136:${config.port}/api/health`);
      if (config.env === 'development') {
        console.log(`📝 Development mode: Using QuickeKYC Sandbox API`);
        console.log(`   Sandbox URL: ${config.quickekycBaseUrl}`);
        console.log(`   Sandbox Key: ${config.quickekycKey ? config.quickekycKey.substring(0, 20) + '...' : 'Not configured'}`);
      } else {
        console.log(`📝 Production mode: Using QuickeKYC Production API`);
      }
    });

    // Handle server errors
    server.on('error', async (error) => {
      if (error.code === 'EADDRINUSE') {
        console.error(`❌ Port ${config.port} is already in use`);
        
        // Try to automatically find and kill the process (Windows)
        if (process.platform === 'win32') {
          try {
            const { execSync } = require('child_process');
            const findPort = `netstat -ano | findstr :${config.port}`;
            const result = execSync(findPort, { encoding: 'utf8' }).trim();
            
            if (result) {
              const lines = result.split('\n');
              const pidLine = lines.find(line => line.includes('LISTENING'));
              if (pidLine) {
                const pid = pidLine.trim().split(/\s+/).pop();
                console.log(`   Found process ${pid} using port ${config.port}`);
                console.log(`   Attempting to kill process...`);
                
                try {
                  execSync(`taskkill /PID ${pid} /F`, { stdio: 'ignore' });
                  console.log(`   ✅ Process ${pid} killed successfully`);
                  console.log(`   🔄 Restarting server in 2 seconds...`);
                  
                  setTimeout(() => {
                    start();
                  }, 2000);
                  return;
                } catch (killError) {
                  console.error(`   ⚠️  Could not kill process: ${killError.message}`);
                }
              }
            }
          } catch (autoKillError) {
            // Auto-kill failed, show manual instructions
          }
        }
        
        console.error(`   Manual fix:`);
        console.error(`   1. Find process: netstat -ano | findstr :${config.port}`);
        console.error(`   2. Kill it: taskkill /PID <PID> /F`);
        console.error(`   3. Or change PORT in .env.dev to a different port (e.g., 5001)`);
        process.exit(1);
      } else {
        console.error('❌ Server error:', error);
        process.exit(1);
      }
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (err) => {
  console.error('❌ Unhandled Promise Rejection:', err);
  process.exit(1);
});

// Handle uncaught exceptions
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

start();
