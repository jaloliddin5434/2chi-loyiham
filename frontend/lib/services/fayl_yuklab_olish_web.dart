import 'dart:html' as html;

/// Xom baytlarni brauzerda to'g'ridan-to'g'ri faylga yuklab beradi
/// (Blob + vaqtinchalik <a download> + click) - yangi oyna/tab OCHILMAYDI.
/// Excel eksport va Nakladnoy PDF yuklab olish ikkalasi ham shu bitta
/// funksiyani ishlatadi.
void faylniYuklabOl(List<int> baytlar, String faylNomi, String mimeTuri) {
  final blob = html.Blob([baytlar], mimeTuri);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', faylNomi)
    ..click();
  html.Url.revokeObjectUrl(url);
}
