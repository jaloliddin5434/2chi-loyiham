import 'dart:html' as html;

/// Tayyor nakladnoy HTML'ini yangi brauzer tab'ida ochadi (chop etish/
/// ko'rish uchun).
void nakladnoyHtmlniOch(String htmlContent) {
  final blob = html.Blob([htmlContent], 'text/html');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  html.Url.revokeObjectUrl(url);
}
