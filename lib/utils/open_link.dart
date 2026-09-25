import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';

bool isWebLink(String? url) {
  final uri = Uri.tryParse(url?.trim() ?? '');
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
}

/// Opens [url] in an in-app browser tab (Chrome Custom Tabs), falling back to
/// the external browser, and shows a snackbar if neither works.
Future<void> openInAppBrowser(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final s = Strings.read(context);
  final uri = Uri.tryParse(url.trim());
  var opened = false;
  if (uri != null && uri.hasScheme) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      opened = false;
    }
    if (!opened) {
      try {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        opened = false;
      }
    }
  }
  if (!opened) {
    messenger.showSnackBar(SnackBar(content: Text(s.couldNotLaunchUrl)));
  }
}

/// A tappable, link-styled URL.
class LinkText extends StatelessWidget {
  final String url;
  final TextStyle? style;

  const LinkText(this.url, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: () => openInAppBrowser(context, url),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                url,
                style: (style ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
                  color: color,
                  decoration: TextDecoration.underline,
                  decorationColor: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
