/// Fayl-yuklab-olish (brauzer Blob+anchor) faqat veb'da mavjud tushuncha -
/// mobil/desktop uchun xavfsiz zaxira (fallback), amalda bu ekranlar
/// (Excel/Nakladnoy) faqat veb'da ochiladi.
void faylniYuklabOl(List<int> baytlar, String faylNomi, String mimeTuri) {}

/// Chop etish (iframe+print) ham faqat veb'da mavjud tushuncha - mobil/
/// desktop uchun xavfsiz zaxira (fallback).
void pdfniChopEtish(List<int> baytlar) {}

/// HTML matnini chop etish (offline Nakladnoy uchun - server so'rovsiz) -
/// ham faqat veb'da mavjud, mobil/desktop uchun xavfsiz zaxira.
void htmlniChopEtish(String htmlMatn) {}
