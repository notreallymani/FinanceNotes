const express = require('express');
const axios = require('axios');
const Otp = require('../models/Otp');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const config = require('../config');

const router = express.Router();

router.post('/generate-otp', async (req, res) => {
  try {
    const startTime = Date.now();
    const { aadhar } = req.body;
    if (!aadhar) {
      return res.status(400).json({ message: 'Aadhaar required' });
    }

    // Development bypass: accept any Aadhaar and return OTP 123456
    if (config.env === 'development') {
      const devRequestId = 'dev_' + Date.now();
      Otp.create({
        aadhar,
        requestId: devRequestId,
        provider: 'dev',
        type: 'aadhaar',
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      }).catch(err => console.error(`[Aadhar OTP] DEV DB save error:`, err.message));
      return res.json({
        success: true,
        request_id: devRequestId,
        data: { message: 'OTP sent (dev mode)' },
        hint: 'Use OTP: 123456',
      });
    }
    
    // Rate limiting - Check for recent OTP generation to prevent spam
    // Note: Same Aadhaar can be used by different users for different payment transactions
    const latest = await Otp.findOne({ aadhar, type: 'aadhaar' })
      .sort({ createdAt: -1 })
      .lean()
      .select('createdAt');
    
    // Rate limiting: Prevent generating OTP too frequently (45 seconds cooldown)
    if (latest && latest.createdAt > new Date(Date.now() - 45 * 1000)) {
      return res.status(429).json({ message: 'Too many requests. Please wait before requesting another OTP.' });
    }
    
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    
    // Sandbox test data: Aadhaar 123456789111 (auto-success in development)
    if (config.env === 'development' && aadhar === '123456789111') {
      console.log(`[Aadhar OTP] ✅ Using sandbox test data - Auto-generating OTP for Aadhaar: 123456789111`);
      const testRequestId = 'sandbox_' + Date.now();
      Otp.create({ aadhar, requestId: testRequestId, provider: 'quickekyc', type: 'aadhaar', expiresAt })
        .catch(err => console.error(`[Aadhar OTP] DB save error (non-critical):`, err.message));
      return res.json({ 
        success: true, 
        request_id: testRequestId, 
        data: { message: 'OTP sent successfully (sandbox mode)' },
        hint: 'Use OTP: 111111 for verification'
      });
    }
    
    // Use QuickeKYC API (sandbox in dev, production in prod)
    if (config.quickekycKey) {
      const quickekycUrl = `${config.quickekycBaseUrl}/api/v1/aadhaar-v2/generate-otp`;
      
      console.log(`[Aadhar OTP] Calling QuickeKYC: ${quickekycUrl}`);
      console.log(`[Aadhar OTP] Aadhaar: ${aadhar.substring(0, 4)}****`);
      
      try {
        // Optimize: Reduce timeout for faster failure, return early if possible
        const r = await axios.post(
          quickekycUrl,
          { key: config.quickekycKey, id_number: aadhar },
          { headers: { 'Content-Type': 'application/json' }, timeout: 8000 } // Reduced from 15s to 8s
        );
        
        console.log(`[Aadhar OTP] QuickeKYC Response:`, {
          status_code: r.data?.status_code,
          status: r.data?.status,
          message: r.data?.message,
          request_id: r.data?.request_id
        });
        
        if (r.data && r.data.status_code === 200 && r.data.status === 'success') {
          const requestId = String(r.data.request_id || '');
          // Optimize: Don't wait for DB save, return response immediately
          Otp.create({ aadhar, requestId, provider: 'quickekyc', type: 'aadhaar', expiresAt })
            .catch(err => console.error(`[Aadhar OTP] DB save error (non-critical):`, err.message));
          
          const elapsed = Date.now() - startTime;
          console.log(`[Aadhar OTP] ✅ OTP generated in ${elapsed}ms, request_id: ${requestId}`);
          return res.json({ success: true, request_id: requestId, data: r.data.data });
        } else {
          // Handle specific QuickeKYC error messages
          let errorMessage = r.data?.message || 'Unknown provider response';
          let statusCode = 400; // Default to 400 for client errors
          
          if (errorMessage.includes('Mobile number is not linked')) {
            errorMessage = 'Mobile number is not linked to this Aadhaar number';
          } else if (errorMessage.includes('Invalid Aadhar number') || errorMessage.includes('Invalid Aadhaar')) {
            errorMessage = 'Invalid Aadhaar number';
          } else if (errorMessage.includes('Maximum attempts reached')) {
            errorMessage = 'Maximum OTP generation attempts reached. Please try again later.';
            statusCode = 429; // Too Many Requests
          } else if (errorMessage.includes('Error from backend')) {
            errorMessage = 'Service temporarily unavailable. Please try again later.';
            statusCode = 502; // Bad Gateway
          }
          
          console.log(`[Aadhar OTP] ⚠️  QuickeKYC error: ${errorMessage}`);
          return res.status(statusCode).json({ 
            message: errorMessage,
            error: r.data?.message || 'OTP generation failed',
            data: r.data 
          });
        }
      } catch (err) {
        console.error(`[Aadhar OTP] ❌ QuickeKYC API Error:`, err.message);
        console.error(`[Aadhar OTP] Error details:`, err.response?.data);
        const status = err.response?.status || 502;
        const data = err.response?.data || {};
        return res.status(status).json({ 
          message: 'Provider error', 
          error: data.error || data.message || String(err.message || 'Request failed'), 
          raw: data 
        });
      }
    }
    
    // Fallback: Local OTP generation (if QuickeKYC not configured)
    console.log(`[Aadhar OTP] ⚠️  QuickeKYC not configured, using local OTP generation`);
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    await Otp.create({ aadhar, code, provider: 'local', type: 'aadhaar', expiresAt });
    return res.json({ success: true, code });
  } catch (e) {
    console.error(`[Aadhar OTP] ERROR in generate-otp:`, e);
    console.error(`[Aadhar OTP] Error stack:`, e.stack);
    return res.status(500).json({ 
      message: 'Server error',
      error: config.env === 'development' ? e.message : undefined
    });
  }
});

router.post('/verify-otp', async (req, res) => {
  const logPrefix = '[POST /api/aadhar/verify-otp]';
  try {
    const startTime = Date.now();
    const { aadhar, otp } = req.body;
    
    console.log(`${logPrefix} Request received - Aadhaar: ${aadhar ? aadhar.substring(0, 4) + '****' : 'missing'}, OTP: ${otp ? otp.substring(0, 2) + '****' : 'missing'}`);
    
    if (!aadhar || !otp) {
      console.log(`${logPrefix} ❌ Missing required fields - aadhar: ${!!aadhar}, otp: ${!!otp}`);
      return res.status(400).json({ message: 'Aadhaar and OTP are required' });
    }

    // Development bypass: any Aadhaar + OTP 123456 succeeds
    if (config.env === 'development' && otp === '123456') {
      const elapsed = Date.now() - startTime;
      console.log(`${logPrefix} ✅ DEV bypass success in ${elapsed}ms`);
      return res.json({ success: true, verified: true, aadhar, message: 'Verified (dev bypass)' });
    }
    
    // Optimize: Use lean() for faster query
    const record = await Otp.findOne({ aadhar, type: 'aadhaar' }).sort({ createdAt: -1 }).lean();
    if (!record) {
      console.log(`${logPrefix} ❌ No OTP record found for Aadhaar: ${aadhar.substring(0, 4)}****`);
      return res.status(400).json({ message: 'OTP not found. Please generate a new OTP.' });
    }
    
    console.log(`${logPrefix} Found OTP record - Provider: ${record.provider}, Request ID: ${record.requestId || 'N/A'}, Expires: ${record.expiresAt}`);
    
    if (record.expiresAt < new Date()) {
      console.log(`${logPrefix} ❌ OTP expired. Expires: ${record.expiresAt}, Now: ${new Date()}`);
      return res.status(400).json({ message: 'OTP expired. Please generate a new OTP.' });
    }
    
    if (record.provider === 'quickekyc') {
      if (!config.quickekycKey) {
        console.log(`${logPrefix} ❌ QuickeKYC not configured`);
        return res.status(500).json({ message: 'QuickeKYC not configured' });
      }
      
      if (!record.requestId) {
        console.log(`${logPrefix} ❌ Missing request_id in OTP record`);
        return res.status(400).json({ message: 'Invalid OTP record. Please generate a new OTP.' });
      }
      
      const quickekycUrl = `${config.quickekycBaseUrl}/api/v1/aadhaar-v2/submit-otp`;
      
      console.log(`${logPrefix} Calling QuickeKYC API: ${quickekycUrl}`);
      console.log(`${logPrefix} Request ID: ${record.requestId}, OTP: ${otp.substring(0, 2)}****`);
      
      // Sandbox test data: Aadhaar 123456789111 with OTP 111111
      if (config.env === 'development' && aadhar === '123456789111' && otp === '111111') {
        console.log(`${logPrefix} ✅ Using sandbox test data - Auto-verifying`);
        // Skip QuickeKYC API call for sandbox test data
      } else {
        try {
          // Optimize: Reduce timeout for faster failure
          const r = await axios.post(
            quickekycUrl,
            { key: config.quickekycKey, request_id: record.requestId, otp },
            { headers: { 'Content-Type': 'application/json' }, timeout: 8000 } // Reduced from 15s to 8s
          );
          
          console.log(`${logPrefix} QuickeKYC Response:`, {
            status_code: r.data?.status_code,
            status: r.data?.status,
            valid_aadhaar: r.data?.data?.valid_aadhaar,
            message: r.data?.message
          });
          
          // Check if verification was successful
          // QuickeKYC may return success with valid_aadhaar as true, or just status success
          const isSuccess = r.data && 
                           r.data.status_code === 200 && 
                           r.data.status === 'success' &&
                           (r.data.data?.valid_aadhaar === true || r.data.data?.valid_aadhaar === undefined);
          
          if (isSuccess) {
            console.log(`${logPrefix} ✅ QuickeKYC verification successful`);
            console.log(`${logPrefix} Response data:`, JSON.stringify(r.data.data || r.data));
            // OTP verified by QuickeKYC, continue to verification success
          } else {
            // Handle specific QuickeKYC error messages
            let errorMessage = r.data?.message || 'OTP verification failed';
            let statusCode = 400;
            
            if (errorMessage.includes('Request already processed')) {
              errorMessage = 'This OTP has already been used. Please generate a new OTP.';
            } else if (errorMessage.includes('Invalid Request')) {
              errorMessage = 'Invalid OTP request. Please generate a new OTP.';
            } else if (errorMessage.includes('Invalid OTP')) {
              errorMessage = 'Invalid OTP code. Please check and try again.';
            } else if (errorMessage.includes('Maximum attempts reached')) {
              errorMessage = 'Maximum OTP verification attempts reached. Please generate a new OTP.';
              statusCode = 429;
            }
            
            console.log(`${logPrefix} ❌ QuickeKYC verification failed: ${errorMessage}`);
            return res.status(statusCode).json({ 
              message: errorMessage,
              error: r.data?.message || 'OTP verification failed',
              details: r.data?.data || r.data
            });
          }
        } catch (err) {
          console.error(`${logPrefix} ❌ QuickeKYC API Error:`, err.message);
          console.error(`${logPrefix} Error response:`, err.response?.data);
          const status = err.response?.status || 502;
          const data = err.response?.data || {};
          return res.status(status).json({ 
            message: 'Provider error', 
            error: data.error || data.message || String(err.message || 'Request failed'),
            details: data
          });
        }
      }
    } else if (record.provider === 'local') {
      console.log(`${logPrefix} Verifying local OTP`);
      if (!record.code || record.code !== otp) {
        console.log(`${logPrefix} ❌ Local OTP mismatch. Expected: ${record.code}, Got: ${otp}`);
        return res.status(400).json({ message: 'Invalid OTP code' });
      }
      console.log(`${logPrefix} ✅ Local OTP verified`);
    } else {
      console.log(`${logPrefix} ❌ Unknown provider: ${record.provider}`);
      return res.status(400).json({ message: 'Invalid OTP provider' });
    }

    // Aadhaar verification is for payment transactions, not user profile creation
    // Same Aadhaar can be used by different users for different payment transactions
    // Just return verification success - don't create/update user profile
    const elapsed = Date.now() - startTime;
    console.log(`${logPrefix} ✅ Aadhaar verified in ${elapsed}ms`);
    
    // Return verification result (not user profile)
    return res.json({ 
      success: true,
      verified: true,
      aadhar: aadhar,
      message: 'Aadhaar verified successfully'
    });
  } catch (e) {
    console.error(`[Aadhar OTP] ERROR in verify-otp:`, e);
    console.error(`[Aadhar OTP] Error stack:`, e.stack);
    const message = e && e.message ? e.message : 'Server error';
    return res.status(500).json({ 
      message,
      error: config.env === 'development' ? e.message : undefined
    });
  }
});

module.exports = router;
