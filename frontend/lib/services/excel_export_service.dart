import 'dart:html' as html;
import 'package:excel/excel.dart' hide Border;
import 'api_service.dart';

/// Hujjatlar ro'yxatini Excel faylga eksport qilish - admin va operator
/// panellari tomonidan birgalikda ishlatiladi.
///
/// MUHIM: eksport backenddan sana/mahsulot filtri bo'yicha TO'LIQ
/// (paginatsiyasiz) ro'yxatni oladi - ekranda hozircha yuklangan
/// (sahifalangan) ro'yxatga EMAS, shu bilan filtrga mos barcha yozuvlar
/// kafolatlanadi.
class ExcelExportService {
  static String mahsulotNomi(dynamic id) {
    switch (id) {
      case 1:
        return 'Chigit';
      case 2:
        return 'Chiganoq';
      case 3:
        return "Chiganoq po'chog'i";
      case 4:
        return 'Patoz';
      default:
        return '—';
    }
  }

  static String holatNomi(dynamic holat) {
    switch (holat) {
      case 'jarayon':
        return 'Jarayon';
      case 'tugallandi':
        return 'Tugallandi';
      case 'bekor':
        return 'Bekor qilindi';
      default:
        return (holat ?? '—').toString();
    }
  }

  /// [qoshimchaFiltr] - sana/mahsulot bo'yicha backend filtridan TASHQARI,
  /// ekranda mavjud boshqa (masalan matnli qidiruv, firma, holat) mahalliy
  /// filtrlarni qo'llash uchun. Natijada nechta qator eksport qilinganini
  /// qaytaradi (0 bo'lsa - mos yozuv topilmadi degani).
  static Future<int> hujjatlarniEksportQil({
    int? mahsulotId,
    String? sanaDan,
    String? sanaGacha,
    bool Function(Map<String, dynamic> h)? qoshimchaFiltr,
  }) async {
    final birinchi = await ApiService.getHujjatlar(
      mahsulotId: mahsulotId,
      sanaDan: sanaDan,
      sanaGacha: sanaGacha,
      sahifa: 1,
      sahifaHajmi: 1,
    );
    final jami = (birinchi['jami'] ?? 0) as int;

    List<dynamic> royxat = [];
    if (jami > 0) {
      final hammasi = await ApiService.getHujjatlar(
        mahsulotId: mahsulotId,
        sanaDan: sanaDan,
        sanaGacha: sanaGacha,
        sahifa: 1,
        sahifaHajmi: jami,
      );
      royxat = (hammasi['natijalar'] ?? []) as List<dynamic>;
    }

    if (qoshimchaFiltr != null) {
      royxat = royxat
          .map((h) => Map<String, dynamic>.from(h as Map))
          .where(qoshimchaFiltr)
          .toList();
    }

    final excel = Excel.createExcel();
    final sheet = excel['Hujjatlar'];
    // `Excel.createExcel()` avtomatik ravishda bo'sh "Sheet1"ni yaratadi -
    // bu o'chirilmasa va standart sheet qilib belgilanmasa, fayl
    // ochilganda AYNAN shu BO'SH sheet ko'rinadi (haqiqiy ma'lumot esa
    // pastdagi "Hujjatlar" tabida yashirin qoladi).
    excel.delete('Sheet1');
    excel.setDefaultSheet('Hujjatlar');
    sheet.appendRow([
      TextCellValue('Hujjat №'),
      TextCellValue('Sana'),
      TextCellValue('Firma'),
      TextCellValue('Mashina'),
      TextCellValue('Shofyor'),
      TextCellValue('Tara (kg)'),
      TextCellValue('Brutto (kg)'),
      TextCellValue('Netto (kg)'),
      TextCellValue('Konditsion (kg)'),
      TextCellValue('Tiket №'),
      TextCellValue('Klass'),
      TextCellValue('Sinf'),
      TextCellValue('Seleksiya navi'),
      TextCellValue('Terim turi'),
      TextCellValue('Namlik %'),
      TextCellValue('Ifloslik %'),
      TextCellValue('Holat'),
      TextCellValue('Mahsulot'),
    ]);
    for (final h in royxat) {
      sheet.appendRow([
        TextCellValue((h['raqam'] ?? '—').toString()),
        TextCellValue(
            (h['created_at']?.toString().substring(0, 10)) ?? '—'),
        TextCellValue((h['firma'] ?? '—').toString()),
        TextCellValue((h['mashina_raqami'] ?? '—').toString()),
        TextCellValue((h['shofyor'] ?? '—').toString()),
        DoubleCellValue((h['tara'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((h['brutto'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((h['netto'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((h['konditsion'] as num?)?.toDouble() ?? 0),
        TextCellValue((h['tiket_raqam'] ?? '—').toString()),
        TextCellValue((h['klass'] ?? '—').toString()),
        TextCellValue((h['sinf'] ?? '—').toString()),
        TextCellValue((h['seleksiya_navi'] ?? '—').toString()),
        TextCellValue((h['terim_turi'] ?? '—').toString()),
        DoubleCellValue((h['namlik'] as num?)?.toDouble() ?? 0),
        DoubleCellValue((h['ifloslik'] as num?)?.toDouble() ?? 0),
        TextCellValue(holatNomi(h['holat'])),
        TextCellValue(mahsulotNomi(h['mahsulot_id'])),
      ]);
    }

    final bytes = excel.encode()!;
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'hujjatlar.xlsx')
      ..click();
    html.Url.revokeObjectUrl(url);
    return royxat.length;
  }
}
