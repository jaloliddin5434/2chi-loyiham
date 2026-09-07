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
///
/// DIQQAT (2026-08-14, real sinovda topilgan haqiqiy xato): avval bu
/// yerda `iframe.onLoad` hodisasiga tayanilardi - lekin blob: orqali
/// yuklangan PDF kontenti uchun bu hodisa ISHONCHLI EMAS ekani
/// aniqlandi (real Playwright sinovida 10 soniya kutilganda ham hech
/// qachon kelmadi), garchi `iframe.contentDocument.readyState`
/// haqiqatan "complete" holatga yetgan bo'lsa ham (Chromiumning ichki
/// PDF ko'ruvchisi buni oddiy HTML hujjatlardagidek "load" hodisasi
/// bilan xabar qilmaydi). Natijada "Chop etish" tugmasi bosilganda
/// KO'PINCHA HECH NARSA bo'lmasdi - chop etish oynasi umuman
/// ochilmasdi. Shu sabab endi `onLoad`ga tayanish o'rniga,
/// `readyState`ning o'zi DAVRIY TEKSHIRILADI (polling) - bu sinovda
/// ishonchli ravishda "complete" ko'rsatgan yagona signal.
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

  var chopEtildi = false;
  void chopEtishgaUrinish() {
    if (chopEtildi) return;
    final contentWindow = iframe.contentWindow;
    if (contentWindow == null) return;
    chopEtildi = true;
    try {
      js.JsObject.fromBrowserObject(contentWindow).callMethod('print');
    } catch (_) {}
    // Ba'zi brauzerlarda chop etish oynasi yopilgandan keyin ishonchli
    // signal (masalan afterprint) kelmasligi mumkin - shu sabab
    // zaxira sifatida vaqt chegarasi bilan tozalanadi.
    Timer(const Duration(minutes: 1), tozalash);
  }

  // `iframe.contentDocument` ham xuddi `contentWindow.print()` kabi
  // dart:html'ning IFrameElement turida ochiq emas - shu sabab bu ham
  // dart:js orqali xom JS obyekt sifatida o'qiladi.
  String? readyStateOqi() {
    try {
      final xom = js.JsObject.fromBrowserObject(iframe)['contentDocument'];
      return xom == null ? null : xom['readyState'] as String?;
    } catch (_) {
      return null;
    }
  }

  Timer? poll;
  poll = Timer.periodic(const Duration(milliseconds: 150), (t) {
    if (readyStateOqi() == 'complete') {
      t.cancel();
      chopEtishgaUrinish();
    }
  });
  // Zaxira: agar biror sababdan readyState HECH QACHON "complete"ga
  // yetmasa (masalan juda katta PDF yoki sekin qurilma), baribir
  // urinib ko'ramiz - "hech narsa bo'lmasligi"dan ko'ra, kechroq chop
  // etish afzalroq.
  Timer(const Duration(seconds: 4), () {
    poll?.cancel();
    chopEtishgaUrinish();
  });

  html.document.body?.append(iframe);
}

/// Xom HTML matnini ko'rinmas <iframe> ichida ochib, brauzerning STANDART
/// chop etish oynasini ochadi. Internet yo'q bo'lganda Nakladnoy'ni
/// mahalliy (server so'rovi va PDF baytlarisiz) chop etish uchun -
/// pdfniChopEtish() bilan bir xil iframe naqshi, faqat blob turi
/// 'text/html'. Oddiy HTML uchun `onLoad` hodisasi ishonchli (blob PDF
/// muammosi - qarang: pdfniChopEtish izohi - bu yerga tegishli emas),
/// lekin zaxira sifatida vaqt chegarasi ham qo'yiladi.
void htmlniChopEtish(String htmlMatn) {
  final blob = html.Blob([htmlMatn], 'text/html');
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

  var chopEtildi = false;
  void chopEtishgaUrinish() {
    if (chopEtildi) return;
    final contentWindow = iframe.contentWindow;
    if (contentWindow == null) return;
    chopEtildi = true;
    try {
      js.JsObject.fromBrowserObject(contentWindow).callMethod('print');
    } catch (_) {}
    Timer(const Duration(minutes: 1), tozalash);
  }

  iframe.onLoad.listen((_) => chopEtishgaUrinish());
  Timer(const Duration(seconds: 3), chopEtishgaUrinish);

  html.document.body?.append(iframe);
}
