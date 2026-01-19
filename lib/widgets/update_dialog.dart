/// Update Dialog Widget
/// 
/// Single Responsibility: Displays update prompt dialog to users
/// Open/Closed Principle: Can be extended for different dialog styles

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback? onUpdate;
  final VoidCallback? onLater;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    this.onUpdate,
    this.onLater,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !updateInfo.isForceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Update icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.system_update,
                  size: 40,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                updateInfo.isForceUpdate ? 'Update Required' : 'Update Available',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                updateInfo.updateMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // Version info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Version',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${updateInfo.currentVersion} (${updateInfo.currentBuildNumber})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Latest Version',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${updateInfo.latestVersion} (${updateInfo.latestBuildNumber})',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Update button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpdate ?? () {
                    Navigator.of(context).pop();
                    UpdateService().openAppStore();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Update Now',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              // Later button (only if not force update)
              if (!updateInfo.isForceUpdate) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onLater ?? () => Navigator.of(context).pop(),
                  child: Text(
                    'Later',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
