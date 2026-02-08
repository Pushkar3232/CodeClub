import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/hackathon_model.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';

/// Add / Edit hackathon form screen used by Admin
class AdminHackathonFormScreen extends StatefulWidget {
  final HackathonModel? hackathon; // null = add, non-null = edit

  const AdminHackathonFormScreen({super.key, this.hackathon});

  @override
  State<AdminHackathonFormScreen> createState() =>
      _AdminHackathonFormScreenState();
}

class _AdminHackathonFormScreenState extends State<AdminHackathonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _venueCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _minTeamCtrl;
  late final TextEditingController _maxTeamCtrl;
  late final TextEditingController _prizesCtrl;
  late final TextEditingController _rulesCtrl;

  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _regDeadline;
  bool _isActive = true;
  bool _isSaving = false;

  bool get _isEditing => widget.hackathon != null;

  @override
  void initState() {
    super.initState();
    final h = widget.hackathon;
    _titleCtrl = TextEditingController(text: h?.title ?? '');
    _descCtrl = TextEditingController(text: h?.description ?? '');
    _venueCtrl = TextEditingController(text: h?.venue ?? '');
    _websiteCtrl = TextEditingController(text: h?.website ?? '');
    _minTeamCtrl =
        TextEditingController(text: (h?.minTeamSize ?? 1).toString());
    _maxTeamCtrl =
        TextEditingController(text: (h?.maxTeamSize ?? 4).toString());
    _prizesCtrl = TextEditingController(text: h?.prizes.join(', ') ?? '');
    _rulesCtrl = TextEditingController(text: h?.rules?.join('\n') ?? '');
    _startDate = h?.startDate ?? DateTime.now().add(const Duration(days: 7));
    _endDate = h?.endDate ?? DateTime.now().add(const Duration(days: 9));
    _regDeadline =
        h?.registrationDeadline ?? DateTime.now().add(const Duration(days: 5));
    _isActive = h?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _venueCtrl.dispose();
    _websiteCtrl.dispose();
    _minTeamCtrl.dispose();
    _maxTeamCtrl.dispose();
    _prizesCtrl.dispose();
    _rulesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(DateTime initial, ValueChanged<DateTime> onPicked,
      {DateTime? firstDate}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // Also pick time
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );
      if (time != null) {
        onPicked(DateTime(
            picked.year, picked.month, picked.day, time.hour, time.minute));
      } else {
        onPicked(picked);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final adminProvider = context.read<AdminProvider>();
    final adminUid = context.read<AuthProvider>().currentUserId;

    final prizes = _prizesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final rules = _rulesCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final hackathon = HackathonModel(
      id: widget.hackathon?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      registrationDeadline: _regDeadline,
      minTeamSize: int.tryParse(_minTeamCtrl.text) ?? 1,
      maxTeamSize: int.tryParse(_maxTeamCtrl.text) ?? 4,
      venue: _venueCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isNotEmpty
          ? _websiteCtrl.text.trim()
          : null,
      prizes: prizes,
      rules: rules.isNotEmpty ? rules : null,
      isActive: _isActive,
      createdAt: widget.hackathon?.createdAt ?? DateTime.now(),
      createdBy: widget.hackathon?.createdBy ?? adminUid,
      registeredTeamIds: widget.hackathon?.registeredTeamIds ?? [],
      registeredIndividualIds:
          widget.hackathon?.registeredIndividualIds ?? [],
    );

    bool success;
    if (_isEditing) {
      success = await adminProvider.updateHackathon(hackathon);
    } else {
      success = await adminProvider.createHackathon(hackathon);
    }

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEditing ? 'Hackathon updated!' : 'Hackathon created!'),
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              adminProvider.errorMessage ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Hackathon' : 'Add Hackathon'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Title
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'e.g. HackAI 2026',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the hackathon...',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),

            // Venue
            TextFormField(
              controller: _venueCtrl,
              decoration: const InputDecoration(
                labelText: 'Venue *',
                hintText: 'e.g. APSIT Seminar Hall',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Venue is required' : null,
            ),
            const SizedBox(height: 16),

            // Website
            TextFormField(
              controller: _websiteCtrl,
              decoration: const InputDecoration(
                labelText: 'Website (optional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link_rounded),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),

            // Date pickers
            Text('Schedule',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _DatePickerTile(
              label: 'Start Date & Time',
              date: _startDate,
              onTap: () => _pickDate(_startDate, (d) {
                setState(() => _startDate = d);
              }),
            ),
            const SizedBox(height: 8),
            _DatePickerTile(
              label: 'End Date & Time',
              date: _endDate,
              onTap: () => _pickDate(_endDate, (d) {
                setState(() => _endDate = d);
              }),
            ),
            const SizedBox(height: 8),
            _DatePickerTile(
              label: 'Registration Deadline',
              date: _regDeadline,
              onTap: () => _pickDate(_regDeadline, (d) {
                setState(() => _regDeadline = d);
              }),
            ),
            const SizedBox(height: 24),

            // Team size
            Text('Team Size',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minTeamCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      prefixIcon: Icon(Icons.people_outline),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxTeamCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Max',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Prizes
            TextFormField(
              controller: _prizesCtrl,
              decoration: const InputDecoration(
                labelText: 'Prizes (comma separated)',
                hintText: '₹10,000, Goodies, Internship',
                prefixIcon: Icon(Icons.card_giftcard_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Rules
            TextFormField(
              controller: _rulesCtrl,
              decoration: const InputDecoration(
                labelText: 'Rules (one per line, optional)',
                hintText: 'Each line is a rule...',
                prefixIcon: Icon(Icons.rule_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Active toggle
            SwitchListTile(
              title: const Text('Active'),
              subtitle: const Text('Students can see and apply'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Update Hackathon' : 'Create Hackathon',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/// Date picker tile widget
class _DatePickerTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                size: 20, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_rounded,
                size: 18, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
