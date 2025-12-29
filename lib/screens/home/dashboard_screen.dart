import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/primary_button.dart';
import '../../utils/navigation_helper.dart';
import '../home/about_screen.dart';
import '../profile/profile_screen.dart';
import '../payment/send_payment_screen.dart';
import '../payment/close_payment_screen.dart';
import '../search/search_screen.dart';
import '../payment/payment_history_screen.dart';
import '../chat/chat_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return Text(
              'Finance Notes',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            );
          },
        ),
        elevation: 0,
      ),
      drawer: _buildDrawer(context),
      body: Column(
        children: [
          // Aadhaar Verification Banner
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final isAadharVerified = authProvider.user?.aadharVerified ?? false;
              if (isAadharVerified) {
                return const SizedBox.shrink(); // Don't show banner if verified
              }
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange[300]!,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: Colors.orange[700],
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verify Your Aadhaar',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Complete Aadhaar verification to send payment requests',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                          // Refresh user data when returning from profile
                          if (context.mounted) {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            await authProvider.fetchProfile();
                          }
                        },
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('Verify'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Dashboard Grid
          Expanded(
            child: GridView.builder(
              // Optimize: Use builder for better performance
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0, // Changed from 1.1 to 1.0 for more vertical space
              ),
              itemCount: 5,
              itemBuilder: (context, index) {
          final tiles = [
            {
              'title': 'Send Payment',
              'icon': Icons.send,
              'color': Colors.blue,
              'route': '/sendPayment',
            },
            {
              'title': 'Close Payment',
              'icon': Icons.close,
              'color': Colors.orange,
              'route': '/closePayment',
            },
            {
              'title': 'Search Transactions',
              'icon': Icons.search,
              'color': Colors.green,
              'route': '/search',
            },
            {
              'title': 'Payment History',
              'icon': Icons.history,
              'color': Colors.purple,
              'route': '/paymentHistory',
            },
            {
              'title': 'Chats',
              'icon': Icons.chat_bubble_outline,
              'color': Colors.teal,
              'route': '/chats',
            },
          ];
          final tile = tiles[index];
          return _buildDashboardTile(
            context,
            title: tile['title'] as String,
            icon: tile['icon'] as IconData,
            color: tile['color'] as Color,
            onTap: () {
              // Optimize: Use smooth navigation transitions
              final route = tile['route'] as String;
              NavigationHelper.fadeTo(
                context,
                _getRouteWidget(route),
              );
            },
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // User Header Section
            Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.user;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.8),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.name.substring(0, 1).toUpperCase() ?? 'U',
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'User',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.phone ?? user?.email ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      NavigationHelper.fadeTo(context, const ProfileScreen());
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    title: 'Payment History',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/paymentHistory');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.search,
                    title: 'Search Transactions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/search');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.send,
                    title: 'Send Payment',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/sendPayment');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.close,
                    title: 'Close Payment',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/closePayment');
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    context,
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    onTap: () async {
                      Navigator.pop(context);
                      final url = Uri.parse('https://notreallymani.github.io/FinanceNotes/delete-account.html');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open delete account page'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/help');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_outline,
                    title: 'About',
                    onTap: () {
                      Navigator.pop(context);
                      // Show about screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Logout Button
            Container(
              padding: const EdgeInsets.all(16),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return PrimaryButton(
                    text: 'Logout',
                    onPressed: () async {
                      Navigator.pop(context);
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    isLoading: authProvider.isLoading,
                    backgroundColor: Colors.red,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.grey[700],
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
    );
  }

  Widget _buildDashboardTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Hero(
      tag: 'tile_$title',
      child: Material(
        color: Colors.transparent,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            // Optimize: Add splash effect for better UX
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Container(
              padding: const EdgeInsets.all(16), // Reduced from 20 to 16
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.1),
                    color.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                children: [
                  Container(
                    padding: const EdgeInsets.all(10), // Reduced from 12 to 10
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 36, // Reduced from 40 to 36
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16 to 12
                  Flexible( // Added Flexible to prevent overflow
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14, // Reduced from 15 to 14
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _getRouteWidget(String route) {
    switch (route) {
      case '/sendPayment':
        return const SendPaymentScreen();
      case '/closePayment':
        return const ClosePaymentScreen();
      case '/search':
        return const SearchScreen();
      case '/paymentHistory':
        return const PaymentHistoryScreen();
      case '/chats':
        return const ChatListScreen();
      default:
        return const SizedBox.shrink();
    }
  }

}
