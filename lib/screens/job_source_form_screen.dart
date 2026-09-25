import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/scraper_source.dart';
import '../services/scraper_source_service.dart';
import '../services/source_preview.dart';
import '../utils/open_link.dart';
import '../utils/safe_padding.dart';
import '../widgets/confirm_dialog.dart';

/// Add or edit a job website. The admin tests the selectors against the
/// live page here, so the scheduled scraper gets a source that works.
class JobSourceFormScreen extends StatefulWidget {
  final ScraperSourceService service;
  final String uid;
  final ScraperSource? source;
  final PageFetcher pageFetcher;

  const JobSourceFormScreen({
    super.key,
    required this.service,
    required this.uid,
    this.source,
    this.pageFetcher = fetchPage,
  });

  @override
  State<JobSourceFormScreen> createState() => _JobSourceFormScreenState();
}

class _JobSourceFormScreenState extends State<JobSourceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.source?.name);
  late final _url = TextEditingController(text: widget.source?.listUrl);
  late final _item = TextEditingController(text: widget.source?.itemSelector);
  late final _title = TextEditingController(text: widget.source?.titleSelector);
  late final _company = TextEditingController(text: widget.source?.companySelector);
  late final _location = TextEditingController(text: widget.source?.locationSelector);
  late final _deadline = TextEditingController(text: widget.source?.deadlineSelector);
  late final _link = TextEditingController(text: widget.source?.linkSelector);
  late bool _enabled = widget.source?.enabled ?? true;

  bool _loading = false;
  String? _message;
  bool _messageIsError = false;
  List<PreviewJob>? _preview;

  // The page is fetched once per URL; Detect and Test reuse it.
  String? _pageUrl;
  String? _pageHtml;

  List<TextEditingController> get _selectorFields => [_item, _title, _company, _location, _deadline, _link];

  @override
  void initState() {
    super.initState();
    // Any change to what the scraper would read makes the last test stale.
    for (final c in [_url, ..._selectorFields]) {
      c.addListener(_clearPreview);
    }
  }

  void _clearPreview() {
    if (_preview != null) setState(() => _preview = null);
  }

  @override
  void dispose() {
    for (final c in [_name, _url, ..._selectorFields]) {
      c.dispose();
    }
    super.dispose();
  }

  ScraperSource _current() => ScraperSource(
        id: widget.source?.id,
        name: _name.text,
        listUrl: _url.text,
        itemSelector: _item.text,
        titleSelector: _title.text,
        companySelector: _company.text,
        locationSelector: _location.text,
        deadlineSelector: _deadline.text,
        linkSelector: _link.text,
        enabled: _enabled,
        createdBy: widget.source?.createdBy ?? widget.uid,
      );

  Future<String?> _loadPage(Strings s) async {
    final url = _url.text.trim();
    if (!isWebLink(url)) {
      _showMessage(s.enterValidLink, error: true);
      return null;
    }
    if (_pageUrl == url && _pageHtml != null) return _pageHtml;
    try {
      final html = await widget.pageFetcher(Uri.parse(url));
      _pageUrl = url;
      _pageHtml = html;
      return html;
    } catch (e) {
      _showMessage(s.previewFailed('$e'), error: true);
      return null;
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  Future<void> _detect() async {
    final s = Strings.read(context);
    setState(() => _loading = true);
    final html = await _loadPage(s);
    if (html != null) {
      final selector = suggestItemSelector(html);
      if (selector == null) {
        _showMessage(s.selectorNotDetected, error: true);
      } else {
        _item.text = selector;
        _showMessage(s.selectorDetected(selector));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _test() async {
    final s = Strings.read(context);
    if (_item.text.trim().isEmpty) {
      _formKey.currentState!.validate();
      return;
    }
    setState(() => _loading = true);
    final html = await _loadPage(s);
    if (html != null) {
      try {
        final jobs = previewJobs(html, Uri.parse(_url.text.trim()), _current());
        setState(() => _preview = jobs);
        _showMessage(jobs.isEmpty ? s.previewEmpty : s.previewCount(jobs.length), error: jobs.isEmpty);
      } on PreviewException catch (e) {
        _showMessage(s.previewFailed(e.message), error: true);
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final s = Strings.read(context);
    if (!_formKey.currentState!.validate()) return;
    if (_preview == null || _preview!.isEmpty) {
      _showMessage(s.testBeforeSaving, error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.service.save(_current());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.sourceSaved)));
      Navigator.of(context).pop();
    } catch (e) {
      _showMessage('$e', error: true);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final s = Strings.read(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.deleteSourceTitle,
      message: s.deleteSourceMessage,
      confirmLabel: s.delete,
    );
    if (!confirmed || !mounted) return;
    await widget.service.delete(widget.source!.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    String? required(String? v) => (v == null || v.trim().isEmpty) ? s.requiredField : null;

    Widget selectorField(TextEditingController c, String label, {String? helper, bool isRequired = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          decoration: InputDecoration(labelText: label, helperText: helper, border: const OutlineInputBorder()),
          style: const TextStyle(fontFamily: 'monospace'),
          autocorrect: false,
          validator: isRequired ? required : null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.source == null ? s.addJobSource : s.editJobSource),
        actions: [
          if (widget.source != null)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: s.delete, onPressed: _loading ? null : _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: safeBodyPadding(context, amount: 16),
          children: [
            TextFormField(
              controller: _name,
              decoration: InputDecoration(labelText: s.sourceNameLabel, border: const OutlineInputBorder()),
              validator: required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              decoration: InputDecoration(
                labelText: s.sourceListUrlLabel,
                hintText: 'https://',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (v) => isWebLink(v?.trim()) ? null : s.enterValidLink,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: selectorField(_item, s.itemSelectorLabel, helper: s.itemSelectorHelp, isRequired: true),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _detect,
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text(s.detectSelector),
                  ),
                ),
              ],
            ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(s.optionalSelectors),
              subtitle: Text(s.optionalSelectorsHelp, style: theme.textTheme.bodySmall),
              initiallyExpanded: widget.source != null &&
                  [_title, _company, _location, _deadline, _link].any((c) => c.text.isNotEmpty),
              children: [
                selectorField(_title, s.titleSelectorLabel, helper: 'h3 a'),
                selectorField(_company, s.companySelectorLabel, helper: '.company'),
                selectorField(_location, s.locationSelectorLabel, helper: '.location'),
                selectorField(_deadline, s.deadlineSelectorLabel, helper: '.deadline'),
                selectorField(_link, s.linkSelectorLabel, helper: 'a.apply'),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.sourceEnabled),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            if (_loading) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _message!,
                  style: TextStyle(color: _messageIsError ? theme.colorScheme.error : theme.colorScheme.primary),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _test,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(s.testSource),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _save,
                    icon: const Icon(Icons.save),
                    label: Text(s.save),
                  ),
                ),
              ],
            ),
            if (_preview != null && _preview!.isNotEmpty) ...[
              const SizedBox(height: 16),
              for (final job in _preview!.take(10)) _PreviewCard(job: job),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final PreviewJob job;

  const _PreviewCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [job.company, job.location, job.deadline].where((t) => t.isNotEmpty).join(' · ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: theme.textTheme.titleSmall),
            if (details.isNotEmpty) Text(details, style: theme.textTheme.bodySmall),
            if (job.link.isNotEmpty) LinkText(job.link),
          ],
        ),
      ),
    );
  }
}
