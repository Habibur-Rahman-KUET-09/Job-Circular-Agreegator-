import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/locale_provider.dart';
import '../l10n/strings.dart';

const sopUrl = 'https://shondhan-58fe0.web.app/sop';

/// Layout of the account page; [AccountScreen] supplies the data and actions.
class AccountView extends StatelessWidget {
  final String name;
  final String email;
  final bool canReviewJobs;
  final bool canAddJobs;
  final bool isPasswordUser;
  final bool busy;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSavedJobs;
  final VoidCallback onOpenApplications;
  final VoidCallback onReviewJobs;
  final VoidCallback onAddJob;
  final VoidCallback onChangePassword;
  final VoidCallback onHowItWorks;
  final VoidCallback onOpenSop;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLogout;

  const AccountView({
    super.key,
    required this.name,
    required this.email,
    required this.canReviewJobs,
    required this.canAddJobs,
    required this.isPasswordUser,
    this.busy = false,
    required this.onOpenProfile,
    required this.onOpenSavedJobs,
    required this.onOpenApplications,
    required this.onReviewJobs,
    required this.onAddJob,
    required this.onChangePassword,
    required this.onHowItWorks,
    required this.onOpenSop,
    required this.onDeleteAccount,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final cs = Theme.of(context).colorScheme;
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', width: 32, height: 32),
            ),
            const SizedBox(width: 12),
            Text(s.myAccount),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: busy,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _AccountTile(
              icon: Icons.person_outline,
              title: name,
              subtitle: email,
              titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            _AccountTile(icon: Icons.badge_outlined, title: s.myProfile, onTap: onOpenProfile),
            _AccountTile(icon: Icons.bookmark_outline, title: s.savedJobs, onTap: onOpenSavedJobs),
            _AccountTile(icon: Icons.work_history_outlined, title: s.myApplications, onTap: onOpenApplications),
            if (canReviewJobs)
              _AccountTile(icon: Icons.fact_check_outlined, title: s.reviewJobs, onTap: onReviewJobs),
            if (canAddJobs)
              _AccountTile(icon: Icons.post_add, title: s.addJob, onTap: onAddJob),
            const SizedBox(height: 12),
            if (isPasswordUser)
              _AccountTile(icon: Icons.lock_outline, title: s.changePassword, onTap: onChangePassword),
            _AccountTile(
              icon: Icons.translate,
              title: s.language,
              subtitle: s.languageName,
              trailing: Icons.swap_horiz,
              onTap: () => locale.setLanguage(locale.isBangla ? AppLanguage.en : AppLanguage.bn),
            ),
            _AccountTile(icon: Icons.help_outline, title: s.howItWorks, onTap: onHowItWorks),
            _AccountTile(
              icon: Icons.menu_book,
              title: s.sopTitle,
              subtitle: sopUrl,
              trailing: Icons.open_in_new,
              onTap: onOpenSop,
            ),
            const SizedBox(height: 12),
            _AccountTile(
              icon: Icons.person_remove_outlined,
              title: s.deleteAccount,
              subtitle: s.deleteAccountSubtitle,
              danger: true,
              onTap: onDeleteAccount,
            ),
            const SizedBox(height: 4),
            Material(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onLogout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: cs.error),
                      const SizedBox(width: 16),
                      Text(
                        s.logout,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: cs.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (busy) const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final IconData? trailing;
  final bool danger;
  final TextStyle? titleStyle;
  final VoidCallback? onTap;

  const _AccountTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.danger = false,
    this.titleStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = danger ? cs.error : cs.primary;
    final trailingIcon = trailing ?? (onTap != null ? Icons.chevron_right : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: danger ? cs.errorContainer : cs.primary.withValues(alpha: 0.1),
                  child: Icon(icon, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: titleStyle ?? theme.textTheme.bodyLarge),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (trailingIcon != null) Icon(trailingIcon, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
