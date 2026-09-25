import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/utils/open_link.dart';

void main() {
  test('isWebLink accepts only http(s) URLs with a host', () {
    expect(isWebLink('https://jobs.bdjobs.com/jobdetails.asp?id=1537117'), isTrue);
    expect(isWebLink('http://example.com'), isTrue);
    expect(isWebLink('  https://example.com  '), isTrue);
    expect(isWebLink('Newspaper - prothomalo (Page 3)'), isFalse);
    expect(isWebLink('mailto:hr@example.com'), isFalse);
    expect(isWebLink(''), isFalse);
    expect(isWebLink(null), isFalse);
  });

  testWidgets('LinkText shows the URL as a tappable link', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: LinkText('https://example.com/job/1')),
    ));
    expect(find.text('https://example.com/job/1'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
  });
}
