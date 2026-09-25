import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/scraper_source.dart';

/// One job as the scraper would read it; shown before a source is saved.
class PreviewJob {
  final String title;
  final String company;
  final String location;
  final String deadline;
  final String link;

  const PreviewJob({
    required this.title,
    this.company = '',
    this.location = '',
    this.deadline = '',
    this.link = '',
  });
}

/// Raised with a message the admin can act on (bad URL, bad selector...).
class PreviewException implements Exception {
  final String message;
  const PreviewException(this.message);

  @override
  String toString() => message;
}

typedef PageFetcher = Future<String> Function(Uri url);

const _maxItems = 150;

Future<String> fetchPage(Uri url, {http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final response = await c.get(url, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    }).timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw PreviewException('HTTP ${response.statusCode}');
    }
    return response.body;
  } finally {
    if (client == null) c.close();
  }
}

/// Same rules as scrapers/selector_scraper.py so the preview matches what
/// the scheduled run stores.
List<PreviewJob> previewJobs(String pageHtml, Uri pageUrl, ScraperSource source) {
  final document = html_parser.parse(pageHtml);
  final List<Element> items;
  try {
    items = document.querySelectorAll(source.itemSelector.trim());
  } catch (e) {
    throw PreviewException('Invalid selector: ${source.itemSelector}');
  }

  final jobs = <PreviewJob>[];
  final seen = <String>{};
  for (final item in items.take(_maxItems)) {
    String field(String selector) {
      if (selector.trim().isEmpty) return '';
      final el = _selectOne(item, selector);
      return el == null ? '' : _clean(el.text);
    }

    var title = field(source.titleSelector);
    if (source.titleSelector.trim().isEmpty) {
      final anchor = item.localName == 'a' ? item : item.querySelector('a');
      title = anchor == null ? '' : _clean(anchor.text);
    }

    final linkSelector = source.linkSelector.trim().isNotEmpty ? source.linkSelector : source.titleSelector;
    Element? linkEl = linkSelector.trim().isEmpty ? null : _selectOne(item, linkSelector);
    if (linkEl == null || (linkEl.attributes['href'] ?? '').isEmpty) {
      linkEl = item.localName == 'a' && item.attributes['href'] != null ? item : item.querySelector('a[href]');
    }
    final href = (linkEl?.attributes['href'] ?? '').trim();
    final link = href.isEmpty || href.startsWith('javascript:') || href.startsWith('#')
        ? ''
        : pageUrl.resolve(href).toString();

    final key = link.isNotEmpty ? link : title;
    if (title.isEmpty || !seen.add(key)) continue;
    jobs.add(PreviewJob(
      title: title,
      company: field(source.companySelector),
      location: field(source.locationSelector),
      deadline: field(source.deadlineSelector),
      link: link,
    ));
  }
  return jobs;
}

Element? _selectOne(Element item, String selector) {
  try {
    return item.querySelector(selector.trim());
  } catch (e) {
    throw PreviewException('Invalid selector: $selector');
  }
}

String _clean(String text) => text.replaceAll(RegExp(r'\s+'), ' ').trim();

final _plainClass = RegExp(r'^[A-Za-z_][A-Za-z0-9_-]*$');

/// Guesses the selector for one job: the classed element that most often
/// wraps a link with a job-like title. Null when nothing repeats.
String? suggestItemSelector(String pageHtml) {
  final document = html_parser.parse(pageHtml);
  final counts = <String, Set<Element>>{};
  for (final anchor in document.querySelectorAll('a[href]')) {
    if (_clean(anchor.text).length < 8) continue;
    Element? el = anchor;
    for (var depth = 0; depth < 5 && el != null && el.localName != 'body'; depth++) {
      final classes = el.classes.where(_plainClass.hasMatch).toList();
      if (classes.isNotEmpty) {
        final signature = '${el.localName}.${classes.first}';
        counts.putIfAbsent(signature, () => <Element>{}).add(el);
      }
      el = el.parent;
    }
  }
  String? best;
  var bestCount = 0;
  counts.forEach((signature, elements) {
    // Ties go to the outer element (added later), which also holds the
    // company, location and deadline next to the link.
    if (elements.length >= 3 && elements.length >= bestCount) {
      best = signature;
      bestCount = elements.length;
    }
  });
  return best;
}
