/// A job website an admin added from the app. The scheduled scraper
/// (scrapers/selector_scraper.py) reads every enabled source and uses its
/// CSS selectors to pull jobs from [listUrl].
class ScraperSource {
  final String? id;
  final String name;
  final String listUrl;

  /// Matches every job on the page; the other selectors run inside it.
  final String itemSelector;
  final String titleSelector;
  final String companySelector;
  final String locationSelector;
  final String deadlineSelector;
  final String linkSelector;
  final bool enabled;
  final String? createdBy;

  // Written by the scraper after each run.
  final DateTime? lastRunAt;
  final int? lastJobCount;
  final String? lastError;

  const ScraperSource({
    this.id,
    required this.name,
    required this.listUrl,
    required this.itemSelector,
    this.titleSelector = '',
    this.companySelector = '',
    this.locationSelector = '',
    this.deadlineSelector = '',
    this.linkSelector = '',
    this.enabled = true,
    this.createdBy,
    this.lastRunAt,
    this.lastJobCount,
    this.lastError,
  });

  factory ScraperSource.fromMap(String id, Map<String, dynamic> map) {
    String text(String key) => (map[key] as String?) ?? '';
    final lastRun = map['lastRunAt'];
    return ScraperSource(
      id: id,
      name: text('name'),
      listUrl: text('listUrl'),
      itemSelector: text('itemSelector'),
      titleSelector: text('titleSelector'),
      companySelector: text('companySelector'),
      locationSelector: text('locationSelector'),
      deadlineSelector: text('deadlineSelector'),
      linkSelector: text('linkSelector'),
      enabled: map['enabled'] as bool? ?? false,
      createdBy: map['createdBy'] as String?,
      lastRunAt: lastRun is String ? DateTime.tryParse(lastRun) : null,
      lastJobCount: (map['lastJobCount'] as num?)?.toInt(),
      lastError: map['lastError'] as String?,
    );
  }

  /// Fields the app edits; run results are left to the scraper.
  Map<String, dynamic> toMap() => {
        'name': name.trim(),
        'listUrl': listUrl.trim(),
        'itemSelector': itemSelector.trim(),
        'titleSelector': titleSelector.trim(),
        'companySelector': companySelector.trim(),
        'locationSelector': locationSelector.trim(),
        'deadlineSelector': deadlineSelector.trim(),
        'linkSelector': linkSelector.trim(),
        'enabled': enabled,
        if (createdBy != null) 'createdBy': createdBy,
      };

  ScraperSource copyWith({bool? enabled}) => ScraperSource(
        id: id,
        name: name,
        listUrl: listUrl,
        itemSelector: itemSelector,
        titleSelector: titleSelector,
        companySelector: companySelector,
        locationSelector: locationSelector,
        deadlineSelector: deadlineSelector,
        linkSelector: linkSelector,
        enabled: enabled ?? this.enabled,
        createdBy: createdBy,
        lastRunAt: lastRunAt,
        lastJobCount: lastJobCount,
        lastError: lastError,
      );
}
