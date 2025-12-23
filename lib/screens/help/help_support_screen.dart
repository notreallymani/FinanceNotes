import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'If you have any problems or questions, please contact us:',
              style: GoogleFonts.inter(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Email',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• manikantaboddu5@gmail.com\n• palakolanu298@gmail.com',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'WhatsApp Numbers',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• +91 84660 33103\n• +91 91008 15949',
              style: GoogleFonts.inter(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Text(
              'We will help you as soon as possible.',
              style: GoogleFonts.inter(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
