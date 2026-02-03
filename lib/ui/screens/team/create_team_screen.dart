import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/team_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';

/// Create team screen
class CreateTeamScreen extends StatefulWidget {
  const CreateTeamScreen({super.key});

  @override
  State<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _hackathonNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  int _maxSize = 4;
  bool _isOpen = true;

  @override
  void dispose() {
    _teamNameController.dispose();
    _hackathonNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final teamProvider = context.read<TeamProvider>();
    final leaderId = authProvider.currentUserId;
    
    if (leaderId == null) return;

    final success = await teamProvider.createTeam(
      name: _teamNameController.text.trim(),
      hackathonName: _hackathonNameController.text.trim(),
      leaderId: leaderId,
      maxSize: _maxSize,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
    );

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              teamProvider.errorMessage ?? 'Failed to create team',
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Team'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header illustration
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add_rounded,
                    size: 60,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1, 1),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 24),
              Text(
                'Create Your Dream Team',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Fill in the details to start building your hackathon team',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
              const SizedBox(height: 32),
              // Team name
              CustomTextField(
                controller: _teamNameController,
                label: 'Team Name',
                hint: 'Enter your team name',
                prefixIcon: const Icon(Icons.groups_rounded),
                validator: Validators.validateTeamName,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                  ),
              const SizedBox(height: 16),
              // Hackathon name
              CustomTextField(
                controller: _hackathonNameController,
                label: 'Hackathon Name',
                hint: 'Which hackathon is this team for?',
                prefixIcon: const Icon(Icons.emoji_events_rounded),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the hackathon name';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 250.ms, duration: 400.ms).slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                  ),
              const SizedBox(height: 16),
              // Team description
              CustomTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Tell others about your team goals',
                prefixIcon: const Icon(Icons.description_rounded),
                maxLines: 3,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                    begin: 0.05,
                    end: 0,
                    duration: 400.ms,
                  ),
              const SizedBox(height: 24),
              // Team size selector
              Text(
                'Team Size',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ).animate().fadeIn(delay: 350.ms, duration: 400.ms),
              const SizedBox(height: 12),
              Row(
                children: List.generate(4, (index) {
                  final size = index + 2; // 2 to 5
                  final isSelected = _maxSize == size;
                  
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 3 ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _maxSize = size;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue
                                : (isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$size',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                                ),
                              ),
                              Text(
                                'members',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              const SizedBox(height: 24),
              // Open for requests toggle
              Card(
                margin: EdgeInsets.zero,
                child: SwitchListTile(
                  title: const Text('Open for Requests'),
                  subtitle: Text(
                    _isOpen
                        ? 'Others can send join requests'
                        : 'Only you can add members',
                  ),
                  value: _isOpen,
                  onChanged: (value) {
                    setState(() {
                      _isOpen = value;
                    });
                  },
                ),
              ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
              const SizedBox(height: 32),
              // Create button
              Consumer<TeamProvider>(
                builder: (context, teamProvider, _) {
                  return PrimaryButton(
                    text: 'Create Team',
                    onPressed: _createTeam,
                    isLoading: teamProvider.isLoading,
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
