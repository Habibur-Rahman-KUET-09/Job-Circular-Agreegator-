import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/user_profile_provider.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _currentPositionController;
  late TextEditingController _yearsController;
  late TextEditingController _skillsController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _currentPositionController = TextEditingController();
    _yearsController = TextEditingController();
    _skillsController = TextEditingController();

    Future.microtask(() {
      context.read<UserProfileProvider>().fetchProfile();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _currentPositionController.dispose();
    _yearsController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final profileProvider = context.watch<UserProfileProvider>();
    final profile = profileProvider.profile;

    if (profileProvider.isLoading && profile == null) {
      return Scaffold(
        appBar: AppBar(title: Text(s.myProfile)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _phoneController.text = profile.phone ?? '';
      _bioController.text = profile.bio ?? '';
      _currentPositionController.text = profile.currentPosition ?? '';
      _yearsController.text = profile.yearsOfExperience?.toString() ?? '';
      _skillsController.text = profile.skills.join(', ');
    }

    return Scaffold(
      appBar: AppBar(title: Text(s.myProfile)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            if (profile != null)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profile.profilePhotoUrl != null
                          ? NetworkImage(profile.profilePhotoUrl!)
                          : null,
                      child: profile.profilePhotoUrl == null
                          ? const Icon(Icons.person, size: 40)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.fullName ?? s.noName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (profile.currentPosition != null)
                      Text(
                        profile.currentPosition!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ],
                ),
              )
            else
              Center(
                child: Text(s.noProfileData),
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Basic Info Section
            Text(
              s.basicInfo,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: s.fullName,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.phone,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: s.bio,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _currentPositionController,
              decoration: InputDecoration(
                labelText: s.currentPosition,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: s.yearsOfExperience,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Skills Section
            Text(
              s.requiredSkills,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _skillsController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.skillsHint,
                hintText: s.skillsHintExample,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (profile?.skills.isNotEmpty ?? false)
              Wrap(
                spacing: 8,
                children: profile!.skills
                    .map((skill) => Chip(
                          label: Text(skill),
                          onDeleted: () {
                            final skills = profile.skills.where((s) => s != skill).toList();
                            profileProvider.updateSkills(skills);
                          },
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: profileProvider.isLoading
                    ? null
                    : () => _saveProfile(profileProvider),
                child: profileProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(s.save),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile(UserProfileProvider provider) async {
    final yearsStr = _yearsController.text.trim();
    final years = yearsStr.isEmpty ? null : int.tryParse(yearsStr);

    final skills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await provider.updateBasicInfo(
      fullName: _fullNameController.text.trim().isEmpty ? null : _fullNameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      currentPosition: _currentPositionController.text.trim().isEmpty
          ? null
          : _currentPositionController.text.trim(),
      yearsOfExperience: years,
    );

    if (skills.isNotEmpty) {
      await provider.updateSkills(skills);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Strings.of(context).profileUpdated)),
      );
    }
  }
}
