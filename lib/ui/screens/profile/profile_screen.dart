import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/user_card.dart';
import 'edit_profile_screen.dart';

/// Profile screen showing user details
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _adminTapCount = 0;
  DateTime? _lastAdminTapAt;

  @override
  void initState() {
    super.initState();
    // Refresh profile when screen is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshUserProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: 'Toggle theme',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              _showSettingsBottomSheet(context);
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;

          if (auth.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return const Center(
              child: Text('Please log in to view your profile'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      UserAvatar(user: user, radius: 50)
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: 500.ms,
                            curve: Curves.elasticOut,
                          ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                      const SizedBox(height: 4),
                      // Email
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
                      const SizedBox(height: 12),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.role,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                      const SizedBox(height: 20),
                      // Edit profile button
                      PrimaryButton(
                        text: 'Edit Profile',
                        icon: Icons.edit_rounded,
                        isOutlined: true,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Profile details
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(
                            context,
                            title: 'Academic Info',
                            icon: Icons.school_rounded,
                            children: [
                              _buildInfoRow(context, 'Branch', user.branch),
                              _buildInfoRow(context, 'Year', user.year),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                            context,
                            title: 'Bio',
                            icon: Icons.info_outline_rounded,
                            children: [
                              Text(
                                user.bio.isEmpty
                                    ? 'No bio added yet'
                                    : user.bio,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: user.bio.isEmpty
                                          ? AppColors.textTertiaryLight
                                          : null,
                                      fontStyle: user.bio.isEmpty
                                          ? FontStyle.italic
                                          : null,
                                    ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 400.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                            context,
                            title: 'Skills',
                            icon: Icons.code_rounded,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: user.skills.map((skill) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.primaryBlue.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.primaryBlueLight
                                                .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      skill,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.primaryBlueLight
                                            : AppColors.primaryBlue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 500.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      const SizedBox(height: 16),
                      if (user.linkedInUrl != null || user.githubUrl != null)
                        _buildInfoCard(
                              context,
                              title: 'Social Profiles',
                              icon: Icons.link_rounded,
                              children: [
                                if (user.linkedInUrl != null && user.linkedInUrl!.isNotEmpty)
                                  _buildSocialLinkRow(context, 'LinkedIn', user.linkedInUrl!),
                                if (user.linkedInUrl != null && user.linkedInUrl!.isNotEmpty && user.githubUrl != null && user.githubUrl!.isNotEmpty)
                                  const SizedBox(height: 12),
                                if (user.githubUrl != null && user.githubUrl!.isNotEmpty)
                                  _buildSocialLinkRow(context, 'GitHub', user.githubUrl!),
                              ],
                            )
                            .animate()
                            .fadeIn(delay: 550.ms, duration: 400.ms)
                            .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                            context,
                            title: 'Account Info',
                            icon: Icons.account_circle_rounded,
                            children: [
                              _buildInfoRow(
                                context,
                                'Member since',
                                user.createdAt.formattedDate,
                              ),
                              _buildInfoRow(
                                context,
                                'Last updated',
                                user.updatedAt.formattedDate,
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 600.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinkRow(BuildContext context, String platform, String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () async {
        try {
          // You can use url_launcher package to open URLs
          // For now, we'll just copy to clipboard
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile link: $url'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open link: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              platform == 'LinkedIn' ? Icons.work_outline_rounded : Icons.code_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    url.replaceFirst(RegExp(r'https?://'), ''),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    // Capture references before showing dialog to avoid context issues
    final authProvider = context.read<AuthProvider>();
    final router = GoRouter.of(context);
    
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close the dialog
              // Sign out and navigate to login using captured references
              await authProvider.signOut();
              router.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement help & support
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement privacy policy
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Terms of Service'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement terms
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Version 1.0.0'),
                subtitle: const Text('Tap 5 times quickly for admin access'),
                onTap: () {
                  final now = DateTime.now();
                  final isQuickTap =
                      _lastAdminTapAt != null &&
                      now.difference(_lastAdminTapAt!).inMilliseconds < 1400;

                  _lastAdminTapAt = now;
                  _adminTapCount = isQuickTap ? _adminTapCount + 1 : 1;

                  if (_adminTapCount >= 5) {
                    _adminTapCount = 0;
                    Navigator.pop(context);
                    if (mounted) {
                      context.go('/admin/login');
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close bottom sheet first
                  _showSignOutDialog(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
