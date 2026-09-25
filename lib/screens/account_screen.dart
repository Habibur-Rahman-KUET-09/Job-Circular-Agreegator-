import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/application_provider.dart';
import '../providers/job_provider.dart';
import '../providers/saved_job_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../services/saved_job_service.dart';
import '../services/user_profile_service.dart';
import '../utils/auth_errors.dart';
import '../utils/open_link.dart';
import '../widgets/confirm_dialog.dart';
import 'account_view.dart';
import 'add_job_screen.dart';
import 'applications_screen.dart';
import 'how_it_works_screen.dart';
import 'job_review_screen.dart';
import 'saved_jobs_screen.dart';
import 'user_profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _auth = AuthService.instance;
  final _firestore = FirebaseFirestore.instance;
  UserRole? _role;
  String? _profileName;
  bool _busy = false;

  String get _uid => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _auth.getCurrentUserRole().then((role) {
      if (mounted) setState(() => _role = role);
    });
    _firestore.collection('users').doc(_uid).get().then((doc) {
      final name = doc.data()?['fullName'] as String?;
      if (mounted && name != null && name.trim().isNotEmpty) setState(() => _profileName = name);
    }).catchError((_) {});
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openProfile() => _push(ChangeNotifierProvider(
        create: (_) => UserProfileProvider(UserProfileService(_firestore), _uid),
        child: const UserProfileScreen(),
      ));

  void _openSavedJobs() => _push(ChangeNotifierProvider(
        create: (_) => SavedJobProvider(SavedJobService(_firestore), _uid),
        child: const SavedJobsScreen(),
      ));

  void _openApplications() => _push(ChangeNotifierProvider(
        create: (_) => ApplicationProvider(ApplicationService(_firestore), _uid),
        child: const ApplicationsScreen(),
      ));

  Future<void> _reviewJobs() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JobReviewScreen()));
    if (mounted) context.read<JobProvider>().fetchAllJobs();
  }

  Future<void> _addJob() async {
    final company = _role == UserRole.recruiter ? await _auth.getCurrentUserCompany() : null;
    if (!mounted) return;
    _push(AddJobScreen(postedBy: _uid, lockedCompany: company));
  }

  Future<void> _changePassword() async {
    final s = Strings.read(context);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (_) => _ChangePasswordDialog(strings: s),
    );
    if (result == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await _auth.changePassword(result.$1, result.$2);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.passwordChanged)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(s, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final s = Strings.read(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteAccountConfirmTitle,
      message: s.deleteAccountConfirmMessage,
      confirmLabel: s.deleteAccount,
    );
    if (!confirmed || !mounted) return;

    String? password;
    if (_auth.isPasswordUser) {
      password = await showDialog<String>(context: context, builder: (_) => _PasswordPromptDialog(strings: s));
      if (password == null || !mounted) return;
    }

    setState(() => _busy = true);
    try {
      await _auth.deleteAccount(currentPassword: password);
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authErrorMessage(s, e))));
    }
  }

  Future<void> _logout() async {
    final s = Strings.read(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.confirmLogout,
      message: s.logoutConfirmation,
      confirmLabel: s.logout,
    );
    if (!confirmed || !mounted) return;
    await _auth.signOut();
    // AuthGate at the root switches to the login screen on sign-out.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? '';
    final name = _profileName ?? user?.displayName ?? email.split('@').first;
    return AccountView(
      name: name,
      email: email,
      canReviewJobs: _role == UserRole.admin || _role == UserRole.moderator,
      canAddJobs: _role == UserRole.admin || _role == UserRole.moderator || _role == UserRole.recruiter,
      isPasswordUser: _auth.isPasswordUser,
      busy: _busy,
      onOpenProfile: _openProfile,
      onOpenSavedJobs: _openSavedJobs,
      onOpenApplications: _openApplications,
      onReviewJobs: _reviewJobs,
      onAddJob: _addJob,
      onChangePassword: _changePassword,
      onHowItWorks: () => _push(const HowItWorksScreen()),
      onOpenSop: () => openInAppBrowser(context, sopUrl),
      onDeleteAccount: _deleteAccount,
      onLogout: _logout,
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final Strings strings;

  const _ChangePasswordDialog({required this.strings});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.changePassword),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _current,
              obscureText: true,
              decoration: InputDecoration(labelText: s.currentPassword),
              validator: (v) => (v == null || v.isEmpty) ? s.loginPasswordRequired : null,
            ),
            TextFormField(
              controller: _next,
              obscureText: true,
              decoration: InputDecoration(labelText: s.newPassword),
              validator: (v) {
                if (v == null || v.length < 8) return s.loginPasswordTooShort;
                if (!RegExp(r'\d').hasMatch(v)) return s.loginPasswordNeedsDigit;
                return null;
              },
            ),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              decoration: InputDecoration(labelText: s.loginConfirmPassword),
              validator: (v) => v != _next.text ? s.loginPasswordMismatch : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, (_current.text, _next.text));
            }
          },
          child: Text(s.changePassword),
        ),
      ],
    );
  }
}

class _PasswordPromptDialog extends StatefulWidget {
  final Strings strings;

  const _PasswordPromptDialog({required this.strings});

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    return AlertDialog(
      title: Text(s.confirmWithPassword),
      content: TextField(
        controller: _controller,
        obscureText: true,
        autofocus: true,
        decoration: InputDecoration(labelText: s.currentPassword),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(s.deleteAccount),
        ),
      ],
    );
  }
}
