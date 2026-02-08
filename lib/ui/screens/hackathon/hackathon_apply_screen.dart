import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/application_model.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

/// Screen for students to apply for a hackathon (solo or with team)
class HackathonApplyScreen extends StatefulWidget {
  final HackathonModel hackathon;

  const HackathonApplyScreen({super.key, required this.hackathon});

  @override
  State<HackathonApplyScreen> createState() => _HackathonApplyScreenState();
}

class _HackathonApplyScreenState extends State<HackathonApplyScreen> {
  bool _applyAsTeam = false;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final authProvider = context.read<AuthProvider>();
    final adminProvider = context.read<AdminProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    final application = ApplicationModel(
      id: '',
      hackathonId: widget.hackathon.id,
      userId: user.uid,
      userName: user.fullName,
      teamId: _applyAsTeam ? user.currentTeamId : null,
      teamName: null, // Will be resolved on server / admin side
      appliedAt: DateTime.now(),
    );

    final success = await adminProvider.submitApplication(application);
    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application submitted successfully!')),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(adminProvider.errorMessage ?? 'Failed to submit'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.watch<AuthProvider>().currentUser;
    final hasTeam =
        user?.currentTeamId != null && user!.currentTeamId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Hackathon')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hackathon info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.hackathon.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      '${_fmt(widget.hackathon.startDate)} — ${_fmt(widget.hackathon.endDate)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(widget.hackathon.venue,
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Team size: ${widget.hackathon.minTeamSize} – ${widget.hackathon.maxTeamSize}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // Applicant info
          Text('Your Details',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                (user?.fullName.isNotEmpty ?? false)
                    ? user!.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue),
              ),
            ),
            title: Text(user?.fullName ?? 'Student'),
            subtitle: Text(user?.email ?? ''),
            tileColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          const SizedBox(height: 24),

          // Application type
          Text('Application Type',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          RadioListTile<bool>(
            value: false,
            groupValue: _applyAsTeam,
            onChanged: (v) => setState(() => _applyAsTeam = v!),
            title: const Text('Apply as Individual'),
            subtitle: const Text('Solo participation'),
            tileColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 8),
          RadioListTile<bool>(
            value: true,
            groupValue: _applyAsTeam,
            onChanged: hasTeam ? (v) => setState(() => _applyAsTeam = v!) : null,
            title: const Text('Apply with Team'),
            subtitle: Text(hasTeam
                ? 'Apply with your current team'
                : 'You must join or create a team first'),
            tileColor: isDark ? AppColors.cardDark : AppColors.cardLight,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Application',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
