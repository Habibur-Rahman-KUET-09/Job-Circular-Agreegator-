import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../utils/open_link.dart';
import 'account_view.dart';
import '../utils/safe_padding.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final steps = s.howItWorksSteps;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        title: Text(s.howItWorks),
      ),
      body: ListView(
        padding: safeBodyPadding(context, amount: 12),
        children: [
          for (var i = 0; i < steps.length; i++)
            Card(
              elevation: 0,
              color: cs.surfaceContainerLowest,
              margin: const EdgeInsets.symmetric(vertical: 5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      child: Text('${i + 1}'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(steps[i].$1, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(steps[i].$2, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => openInAppBrowser(context, sopUrl),
            icon: const Icon(Icons.menu_book),
            label: Text(s.sopTitle),
          ),
        ],
      ),
    );
  }
}
