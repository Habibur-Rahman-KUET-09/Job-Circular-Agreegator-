import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/job.dart';
import '../models/job_filter.dart';
import '../utils/safe_padding.dart';

/// Opens the filter sheet; returns the chosen filter, or null if dismissed.
Future<JobFilter?> showJobFilterSheet(BuildContext context, {required JobFilter filter, required List<Job> jobs}) {
  return showModalBottomSheet<JobFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) => JobFilterSheet(initial: filter, jobs: jobs, scrollController: controller),
    ),
  );
}

class JobFilterSheet extends StatefulWidget {
  final JobFilter initial;
  final List<Job> jobs;
  final ScrollController? scrollController;

  const JobFilterSheet({super.key, required this.initial, required this.jobs, this.scrollController});

  @override
  State<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends State<JobFilterSheet> {
  late JobFilter _filter = widget.initial;
  late final _locations = JobFilter.locationSuggestions(widget.jobs);

  void _update(JobFilter filter) => setState(() => _filter = filter);

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final count = _filter.apply(widget.jobs).length;

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(text, style: theme.textTheme.titleSmall),
        );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: Text(s.filters, style: theme.textTheme.titleLarge)),
              TextButton(
                onPressed: _filter.sheetFilterCount == 0 ? null : () => _update(_filter.clearSheet()),
                child: Text(s.clearAll),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              heading(s.sortBy),
              SegmentedButton<JobSort>(
                segments: [
                  ButtonSegment(value: JobSort.newest, label: Text(s.sortNewest), icon: const Icon(Icons.schedule)),
                  ButtonSegment(value: JobSort.deadlineSoon, label: Text(s.sortDeadline), icon: const Icon(Icons.alarm)),
                ],
                selected: {_filter.sort},
                onSelectionChanged: (v) => _update(_filter.copyWith(sort: v.first)),
              ),
              heading(s.jobTypeLabelText),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final type in JobType.values)
                    FilterChip(
                      label: Text(s.jobTypeLabel(type)),
                      selected: _filter.jobTypes.contains(type),
                      onSelected: (on) {
                        final types = {..._filter.jobTypes};
                        on ? types.add(type) : types.remove(type);
                        _update(_filter.copyWith(jobTypes: types));
                      },
                    ),
                ],
              ),
              heading(s.location),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _filter.location),
                optionsBuilder: (value) {
                  final q = value.text.trim().toLowerCase();
                  if (q.isEmpty) return const [];
                  return _locations.where((l) => l.toLowerCase().contains(q)).take(8);
                },
                onSelected: (value) => _update(_filter.copyWith(location: value)),
                fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: s.locationHint,
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: _filter.location.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              _update(_filter.copyWith(location: ''));
                            },
                          ),
                  ),
                  onChanged: (value) => _update(_filter.copyWith(location: value)),
                ),
              ),
              heading(s.experienceFilter),
              _Choices<int?>(
                value: _filter.maxExperience,
                options: {null: s.anyOption, 0: s.fresher, 2: s.upToYears(2), 5: s.upToYears(5)},
                onChanged: (v) => _update(_filter.copyWith(maxExperience: () => v)),
              ),
              heading(s.postedWithin),
              _Choices<int?>(
                value: _filter.postedWithinDays,
                options: {null: s.anyOption, 1: s.postedToday, 3: s.lastDays(3), 7: s.lastDays(7)},
                onChanged: (v) => _update(_filter.copyWith(postedWithinDays: () => v)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.closingSoon),
                value: _filter.closingSoon,
                onChanged: (v) => _update(_filter.copyWith(closingSoon: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.salaryMentioned),
                value: _filter.salaryMentioned,
                onChanged: (v) => _update(_filter.copyWith(salaryMentioned: v)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(s.showExpired),
                value: !_filter.hideExpired,
                onChanged: (v) => _update(_filter.copyWith(hideExpired: !v)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        Padding(
          padding: safeBodyPadding(context, amount: 16).copyWith(top: 8),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(_filter),
              child: Text(s.showJobs(count)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Choices<T> extends StatelessWidget {
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _Choices({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final entry in options.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: entry.key == value,
            onSelected: (_) => onChanged(entry.key),
          ),
      ],
    );
  }
}
