import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

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

/// PDF baytlarini ko'rinmas <iframe> ichida yuklab, brauzerning STANDART
/// chop etish oynasini ochadi (printer tanlash bilan) - foydalanuvchi
/// baribir "Chop etish" tugmasini bosishi kerak, avtomatik/sokin chop
/// etish emas.
///
/// <iframe> - window.open() dan farqli o'laroq - HECH QACHON brauzer
/// popup-blocker tomonidan bloklanmaydi (chunki u yangi oyna/tab emas,
/// joriy sahifaning bir qismi). Shu sabab bu yerda asinxron so'rovdan
/// keyin chaqirilishi ham (avvalgi window.open muammosidagidek) hech
/// qanday xavf tug'dirmaydi.
///
/// `contentWindow.print()`: dart:html'ning WindowBase turi print()
/// metodini ochiq qo'ymagani uchun (cross-origin xavfsizlik sababli
/// qisqartirilgan interfeys), dart:js orqali xom JS metodini
/// chaqiramiz - bu haqiqiy Window obyektida mavjud, faqat Dart
/// tomonidan tiplanmagan.
void pdfniChopEtish(List<int> baytlar) {
  final blob = html.Blob([baytlar], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final iframe = html.IFrameElement()
    ..style.position = 'fixed'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = 'none'
    ..src = url;

  var tozalandi = false;
  void tozalash() {
    if (tozalandi) return;
    tozalandi = true;
    iframe.remove();
    html.Url.revokeObjectUrl(url);
  }

  iframe.onLoad.listen((_) {
    final contentWindow = iframe.contentWindow;
    if (contentWindow != null) {
      try {
        js.JsObject.fromBrowserObject(contentWindow).callMethod('print');
      } catch (_) {}
    }
    // Ba'zi brauzerlarda chop etish oynasi yopilgandan keyin ishonchli
    // signal (masalan afterprint) kelmasligi mumkin - shu sabab
    // zaxira sifatida vaqt chegarasi bilan tozalanadi.
    Timer(const Duration(minutes: 1), tozalash);
  });
  html.document.body?.append(iframe);
}
