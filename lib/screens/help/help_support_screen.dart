import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Finance Notes Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      // Fallback: Copy to clipboard
      // You can add clipboard functionality here
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Colors.blue[50]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re Here to Help!',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team for any questions or assistance',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Email Support Section
            Text(
              'Email Support',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              iconColor: Colors.blue,
              title: 'manikantaboddu5@gmail.com',
              subtitle: 'Send us an email',
              onTap: () => _launchEmail('manikantaboddu5@gmail.com'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              iconColor: Colors.blue,
              title: 'palakolanu298@gmail.com',
              subtitle: 'Send us an email',
              onTap: () => _launchEmail('palakolanu298@gmail.com'),
            ),
            const SizedBox(height: 32),

            // WhatsApp Support Section
            Text(
              'WhatsApp Support',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.green,
              title: '+91 84660 33103',
              subtitle: 'Chat with us on WhatsApp',
              onTap: () => _launchWhatsApp('918466033103'),
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              icon: Icons.chat_bubble_outline,
              iconColor: Colors.green,
              title: '+91 91008 15949',
              subtitle: 'Chat with us on WhatsApp',
              onTap: () => _launchWhatsApp('919100815949'),
            ),
            const SizedBox(height: 32),

            // Response Time Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange[200]!,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.orange[700],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Response',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We typically respond within 24 hours',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // FAQ Section (Optional - can be expanded)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: Colors.grey[700],
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Common Questions',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    context,
                    question: 'How do I verify my Aadhaar?',
                    answer: 'Go to Profile → Enter Aadhaar → Get OTP → Verify',
                  ),
                  const Divider(height: 24),
                  _buildFAQItem(
                    context,
                    question: 'How do I send a payment request?',
                    answer: 'Go to Send Payment → Enter receiver details → Send OTP',
                  ),
                  const Divider(height: 24),
                  _buildFAQItem(
                    context,
                    question: 'How do I close a payment?',
                    answer: 'Go to Close Payment → Enter transaction ID → Verify OTP',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(
    BuildContext context, {
    required String question,
    required String answer,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          answer,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
