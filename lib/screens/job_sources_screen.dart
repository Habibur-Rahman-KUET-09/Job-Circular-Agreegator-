import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/scraper_source.dart';
import '../services/scraper_source_service.dart';
import '../services/source_preview.dart';
import '../utils/bangla_utils.dart';
import '../utils/safe_padding.dart';
import '../widgets/empty_state.dart';
import 'job_source_form_screen.dart';

/// Admin list of websites the scraper collects jobs from.
class JobSourcesScreen extends StatelessWidget {
  final ScraperSourceService service;
  final String uid;
  final PageFetcher pageFetcher;

  const JobSourcesScreen({
    super.key,
    required this.service,
    required this.uid,
    this.pageFetcher = fetchPage,
  });

  void _openForm(BuildContext context, [ScraperSource? source]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JobSourceFormScreen(service: service, uid: uid, source: source, pageFetcher: pageFetcher),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.jobSources)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(s.addJobSource),
      ),
      body: StreamBuilder<List<ScraperSource>>(
        stream: service.watchSources(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sources = snapshot.data!;
          return ListView(
            padding: safeBodyPadding(context, amount: 12, fab: true),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(s.jobSourcesIntro),
                ),
              ),
              if (sources.isEmpty)
                EmptyState(icon: Icons.travel_explore, message: s.noJobSources)
              else
                for (final source in sources)
                  _SourceTile(
                    source: source,
                    onTap: () => _openForm(context, source),
                    onEnabledChanged: (value) => service.setEnabled(source.id!, value),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final ScraperSource source;
  final VoidCallback onTap;
  final ValueChanged<bool> onEnabledChanged;

  const _SourceTile({required this.source, required this.onTap, required this.onEnabledChanged});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final run = source.lastRunAt;
    final status = run == null
        ? s.notRunYet
        : s.lastRun(_formatDateTime(run.toLocal()), source.lastJobCount ?? 0);
    final error = source.lastError;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: const CircleAvatar(child: Icon(Icons.language)),
        title: Text(source.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(source.listUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(status, style: theme.textTheme.bodySmall),
            if (error != null && error.isNotEmpty)
              Text(error, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
        ),
        isThreeLine: true,
        trailing: Switch(value: source.enabled, onChanged: onEnabledChanged),
      ),
    );
  }

  static String _formatDateTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final text = '${t.day}/${t.month}/${t.year} ${two(t.hour)}:${two(t.minute)}';
    return BanglaMonths.useBangla ? _banglaDigits(text) : text;
  }

  static String _banglaDigits(String text) =>
      text.replaceAllMapped(RegExp(r'\d'), (m) => BanglaMonths.toBanglaDigits(int.parse(m[0]!)));
}
