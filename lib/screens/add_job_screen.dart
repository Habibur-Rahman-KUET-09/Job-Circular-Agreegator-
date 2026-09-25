import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../utils/open_link.dart';
import '../utils/safe_padding.dart';

/// Form for a hand-entered job. It is saved as pending and appears in the feed
/// only after an admin or moderator approves it.
class AddJobScreen extends StatefulWidget {
  final String postedBy;

  /// Recruiters may only post for their own company, so it is fixed for them.
  final String? lockedCompany;
  final JobService? jobService;

  const AddJobScreen({super.key, required this.postedBy, this.lockedCompany, this.jobService});

  @override
  State<AddJobScreen> createState() => _AddJobScreenState();
}

class _AddJobScreenState extends State<AddJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late final JobService _jobService = widget.jobService ?? JobService(FirebaseFirestore.instance);
  late final _company = TextEditingController(text: widget.lockedCompany ?? '');
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _description = TextEditingController();
  final _applyLink = TextEditingController();
  final _salary = TextEditingController();
  final _minYears = TextEditingController();
  JobCategory _category = JobCategory.other;
  JobType? _jobType;
  DateTime? _deadline;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_company, _title, _location, _description, _applyLink, _salary, _minYears]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, Strings s) => (v == null || v.trim().isEmpty) ? s.requiredField : null;

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _submit() async {
    final s = Strings.read(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final salary = _salary.text.trim();
    final link = _applyLink.text.trim();
    try {
      await _jobService.submitManualJob(Job(
        id: '',
        title: _title.text.trim(),
        company: _company.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        category: _category,
        jobType: _jobType,
        source: 'manual',
        sourceType: JobSourceType.manual,
        postedDate: now,
        createdAt: now,
        status: JobStatus.pending,
        deadline: _deadline,
        applyLink: link.isEmpty ? null : link,
        salaryMin: salary.isEmpty ? null : salary,
        minYearsExperience: int.tryParse(_minYears.text.trim()),
        postedBy: widget.postedBy,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.jobSubmittedForReview)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errorOccurred)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    const gap = SizedBox(height: 12);
    final deadline = _deadline;

    return Scaffold(
      appBar: AppBar(title: Text(s.addJob)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: safeBodyPadding(context, amount: 16),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: s.jobTitleLabel),
              textInputAction: TextInputAction.next,
              validator: (v) => _required(v, s),
            ),
            gap,
            TextFormField(
              controller: _company,
              readOnly: widget.lockedCompany != null,
              decoration: InputDecoration(labelText: s.companyLabel),
              textInputAction: TextInputAction.next,
              validator: (v) => _required(v, s),
            ),
            gap,
            TextFormField(
              controller: _location,
              decoration: InputDecoration(labelText: s.location, hintText: s.locationHint),
              textInputAction: TextInputAction.next,
              validator: (v) => _required(v, s),
            ),
            gap,
            DropdownButtonFormField<JobCategory>(
              initialValue: _category,
              decoration: InputDecoration(labelText: s.category),
              items: [
                for (final c in JobCategory.values)
                  DropdownMenuItem(value: c, child: Text(s.categoryLabel(c))),
              ],
              onChanged: (v) => setState(() => _category = v ?? JobCategory.other),
            ),
            gap,
            DropdownButtonFormField<JobType>(
              initialValue: _jobType,
              decoration: InputDecoration(labelText: s.jobTypeLabelText),
              items: [
                for (final t in JobType.values) DropdownMenuItem(value: t, child: Text(s.jobTypeLabel(t))),
              ],
              onChanged: (v) => setState(() => _jobType = v),
            ),
            gap,
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event),
              label: Text(deadline == null
                  ? s.pickDeadline
                  : s.deadline('${deadline.day}/${deadline.month}/${deadline.year}')),
            ),
            gap,
            TextFormField(
              controller: _applyLink,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: s.applyLink, hintText: s.applyLinkHint),
              validator: (v) {
                final value = v?.trim() ?? '';
                return value.isEmpty || isWebLink(value) ? null : s.enterValidLink;
              },
            ),
            gap,
            TextFormField(
              controller: _salary,
              decoration: InputDecoration(labelText: s.salaryLabel),
            ),
            gap,
            TextFormField(
              controller: _minYears,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.minExperienceLabel),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                final n = int.tryParse(value);
                return n == null || n < 0 ? s.enterValidNumber : null;
              },
            ),
            gap,
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 10,
              decoration: InputDecoration(labelText: s.descriptionLabel, alignLabelWithHint: true),
              validator: (v) => _required(v, s),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(s.submitForReview),
            ),
          ],
        ),
      ),
    );
  }
}
