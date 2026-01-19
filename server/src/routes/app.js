const express = require('express');
const router = express.Router();

/**
 * GET /api/app/version
 * Returns the latest app version information
 * 
 * Response:
 * {
 *   version: "1.0.0",
 *   buildNumber: 12,
 *   forceUpdate: false,
 *   message: "A new version is available. Please update to continue."
 * }
 */
router.get('/version', (req, res) => {
  try {
    // TODO: Store this in database or config file for easy updates
    // For now, hardcode the latest version
    // Update these values when you release a new version
    
    const latestVersion = {
      version: '1.0.0',           // Version name (e.g., 1.0.0, 1.0.1, 1.1.0)
      buildNumber: 12,            // Build number (must be higher than current app version)
      forceUpdate: false,          // Set to true to force users to update
      message: 'A new version is available with bug fixes and performance improvements. Please update to continue.', // Update message
      releaseNotes: [              // Optional: Release notes
        'Bug fixes and performance improvements',
        'Enhanced security features',
        'Improved user experience',
      ],
    };

    res.json(latestVersion);
  } catch (error) {
    console.error('[App] Error getting version:', error);
    res.status(500).json({ 
      message: 'Error retrieving version information',
      error: error.message 
    });
  }
});

module.exports = router;
