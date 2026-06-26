import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';
import 'package:pehlivan_isg/widgets/form_helpers.dart';

// ─── Sabitler ────────────────────────────────────────────────────────────────

const _tehlikeSiniflari = [
  'AZ TEHLİKELİ',
  'TEHLİKELİ',
  'ÇOK TEHLİKELİ',
];

const _tehlikeSuresi = {
  'AZ TEHLİKELİ': 8,
  'TEHLİKELİ': 12,
  'ÇOK TEHLİKELİ': 16,
};

const _sertifikaTurleri = [
  'Temel İSG Eğitimi',
  'Oryantasyon Eğitimi',
  'Acil Durum Ekibi Eğitimi',
  'İş Kazası Sonrası Eğitimi',
  'Yüksekte Çalışma Eğitimi',
  'Çalışan Temsilcisi Eğitimi',
  'Destek Elemanı Eğitimi',
];

const _ozelKonular = [
  'YÜKSEKTE GÜVENLİ ÇALIŞMA',
  'KAPALI ORTAMDA GÜVENLİ ÇALIŞMA',
  'SICAK ÇALIŞMADA İŞ GÜVENLİĞİ',
  'HİJYEN EĞİTİMİ',
  'TIBBİ ATIK EĞİTİMİ',
  'YANGINLA MÜCADELE EĞİTİMİ',
  'RİSK DEĞERLENDİRME ÇALIŞMALARI',
  'ACİL DURUM PLANLAMA EĞİTİMİ',
];

// ─── Ana Sayfa ────────────────────────────────────────────────────────────────

class SertifikaPage extends StatefulWidget {
  const SertifikaPage({super.key});

  @override
  State<SertifikaPage> createState() => _SertifikaPageState();
}

class _SertifikaPageState extends State<SertifikaPage> {
  List<Map<String, dynamic>> _sertifikalar = [];
  List<Map<String, dynamic>> _firmalar = [];
  bool _loading = true;
  int? _seciliFirmaId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final serts = await DatabaseService.getSertifikalar(firmaId: _seciliFirmaId);
    final firms = await DatabaseService.getAllFirmalar();
    if (mounted) {
      setState(() {
        _sertifikalar = serts;
        _firmalar = firms;
        _loading = false;
      });
    }
  }

  String _formatTarih(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Color _tehlikeRenk(String sinif) {
    if (sinif.startsWith('ÇOK TEHLİKELİ')) return const Color(0xFFEF4444);
    if (sinif.startsWith('TEHLİKELİ')) return const Color(0xFFF97316);
    return const Color(0xFF10B981);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sertifika Yönetimi',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: c.text, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFE8B84B)),
            tooltip: 'Yeni Sertifika',
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => _SertifikaForm(firmalar: _firmalar)));
              _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_firmalar.isNotEmpty)
            Container(
              color: c.card,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: DropdownButtonFormField<int?>(
                value: _seciliFirmaId,
                dropdownColor: c.card,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tüm firmalar',
                  hintStyle:
                      GoogleFonts.inter(color: c.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: c.bg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: c.border),
                  ),
                  prefixIcon: Icon(Icons.business_rounded,
                      color: c.textMuted, size: 18),
                ),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tüm firmalar',
                        style: GoogleFonts.inter(fontSize: 13, color: c.text)),
                  ),
                  ..._firmalar.map((f) => DropdownMenuItem<int?>(
                        value: f['id'] as int,
                        child: Text(f['isim'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: c.text)),
                      )),
                ],
                onChanged: (v) {
                  setState(() {
                    _seciliFirmaId = v;
                    _loading = true;
                  });
                  _loadData();
                },
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE8B84B)))
                : _sertifikalar.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.workspace_premium_rounded,
                        title: 'Henüz sertifika yok',
                        subtitle:
                            'Yeni sertifika eklemek için + butonuna dokunun',
                        iconColor: Color(0xFFE8B84B),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sertifikalar.length,
                        itemBuilder: (_, i) {
                          final s = _sertifikalar[i];
                          final tehlikeRenk =
                              _tehlikeRenk(s['tehlikeSinifi'] as String);
                          final tarih = s['egitimTarihi'] as DateTime;
                          final tarih2 = s['egitimTarihi2'] as DateTime?;
                          final katSayisi =
                              (s['katilimcilar'] as List).length;
                          final firma = _firmalar.firstWhere(
                            (f) => f['id'] == s['firmaId'],
                            orElse: () => {'isim': '—'},
                          );
                          final sertNo =
                              (s['sertifikaNo'] as String?) ?? '';
                          final uzman = (s['uzmanIsim'] as String?) ?? '';

                          return Card(
                            color: c.card,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color: c.border
                                        .withValues(alpha: 0.5))),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        s['sertifikaTuru'] as String,
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            color: c.text,
                                            fontSize: 14),
                                      ),
                                    ),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: tehlikeRenk
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: tehlikeRenk
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        s['tehlikeSinifi'] as String,
                                        style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: tehlikeRenk),
                                      ),
                                    ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    firma['isim'] as String,
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFFE8B84B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (sertNo.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text('No: $sertNo',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: c.textMuted)),
                                  ],
                                  if (uzman.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text('Uzman: $uzman',
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: c.textMuted)),
                                  ],
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 4,
                                    children: [
                                      _infoChip(Icons.calendar_today_rounded,
                                          _formatTarih(tarih), c),
                                      if (tarih2 != null)
                                        _infoChip(
                                            Icons.event_repeat_rounded,
                                            '2. Gün: ${_formatTarih(tarih2)}',
                                            c),
                                      _infoChip(Icons.timer_outlined,
                                          '${s['egitimSuresi']} saat', c),
                                      _infoChip(Icons.group_rounded,
                                          '$katSayisi katılımcı', c),
                                    ],
                                  ),
                                  if (s['egitimTipi'] == 'YENILEME')
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(top: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF7C3AED)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                              color: const Color(0xFF7C3AED)
                                                  .withValues(alpha: 0.3)),
                                        ),
                                        child: Text('YENİLEME',
                                            style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(
                                                    0xFF7C3AED))),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      AksiyanButon(
                                        icon: Icons.picture_as_pdf_rounded,
                                        label: 'Bireysel PDF',
                                        color: const Color(0xFFE8B84B),
                                        onTap: () => _pdfBireysel(
                                            s, firma['isim'] as String),
                                      ),
                                      AksiyanButon(
                                        icon: Icons.list_alt_rounded,
                                        label: 'Devam Listesi',
                                        color: const Color(0xFF4FC3F7),
                                        onTap: () => _pdfDevamListesi(
                                            s, firma['isim'] as String),
                                      ),
                                      AksiyanButon(
                                        icon: Icons.delete_outline_rounded,
                                        label: 'Sil',
                                        color: const Color(0xFFEF4444),
                                        onTap: () =>
                                            _silOnay(s['id'] as int),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, AppColors c) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: GoogleFonts.inter(fontSize: 11, color: c.textMuted)),
        ],
      );

  Future<void> _silOnay(int id) async {
    final c = AppColors.of(context);
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title:
            Text('Sertifika Sil', style: GoogleFonts.inter(color: c.text)),
        content: Text('Bu sertifika kaydı silinecek. Emin misiniz?',
            style: GoogleFonts.inter(color: c.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal',
                  style: GoogleFonts.inter(color: c.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (onay == true) {
      await DatabaseService.deleteSertifika(id);
      _loadData();
    }
  }

  Future<void> _pdfBireysel(
      Map<String, dynamic> s, String firmaAdi) async {
    final katilimcilar = (s['katilimcilar'] as List).cast<dynamic>();
    if (katilimcilar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Katılımcı listesi boş')),
        );
      }
      return;
    }
    final bytes = await _bireyselPdfBytes(s, firmaAdi);
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _PdfOnizleme(
                    baslik: 'Bireysel Sertifika',
                    buildPdf: (_) async => bytes,
                  )));
    }
  }

  Future<void> _pdfDevamListesi(
      Map<String, dynamic> s, String firmaAdi) async {
    final bytes = await _devamListesiBytes(s, firmaAdi);
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => _PdfOnizleme(
                    baslik: 'Devam Listesi',
                    buildPdf: (_) async => bytes,
                  )));
    }
  }
}

// ─── PDF Yardımcıları ─────────────────────────────────────────────────────────

String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

Future<Uint8List> _bireyselPdfBytes(
    Map<String, dynamic> s, String firmaAdi) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );
  final userName = await storage.read(key: 'user_name') ?? '';
  final userCompany = await storage.read(key: 'user_company') ?? '';
  final logoB64 = await storage.read(key: 'user_company_logo');

  final font = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final tarih = s['egitimTarihi'] as DateTime;
  final tarih2 = s['egitimTarihi2'] as DateTime?;
  final gecerlilik = s['gecerlilikTarihi'] as DateTime?;
  final gecerlilikStr = gecerlilik != null
      ? _fmt(gecerlilik)
      : '${tarih.year + 1}.${tarih.month.toString().padLeft(2, '0')}.${tarih.day.toString().padLeft(2, '0')}';

  final uzmanIsim = (s['uzmanIsim'] as String?)?.trim() ?? '';
  final uzmanUnvan = (s['uzmanUnvan'] as String?)?.trim() ?? '';
  final hekimIsim = (s['hekimIsim'] as String?)?.trim() ?? '';
  final hekimUnvan = (s['hekimUnvan'] as String?)?.trim() ?? '';
  final egitimciIsim =
      (s['egitimciIsim'] as String?)?.trim() ?? uzmanIsim;
  final egitimciUnvan =
      (s['egitimciUnvan'] as String?)?.trim() ?? uzmanUnvan;
  final sertifikaNo = (s['sertifikaNo'] as String?)?.trim() ?? '';
  final imzaPath = (s['imzaPath'] as String?)?.trim() ?? '';

  pw.MemoryImage? logoImage;
  if (logoB64 != null && logoB64.isNotEmpty) {
    try {
      logoImage = pw.MemoryImage(base64Decode(logoB64));
    } catch (_) {}
  }

  pw.MemoryImage? imzaImage;
  if (imzaPath.isNotEmpty && File(imzaPath).existsSync()) {
    try {
      imzaImage = pw.MemoryImage(File(imzaPath).readAsBytesSync());
    } catch (_) {}
  }

  final katilimcilar = (s['katilimcilar'] as List).cast<dynamic>();
  final doc = pw.Document();

  for (final kat in katilimcilar) {
    final Map<String, dynamic> k =
        Map<String, dynamic>.from(kat as Map);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (ctx) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.amber700, width: 3),
        ),
        padding: const pw.EdgeInsets.all(20),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                if (logoImage != null)
                  pw.Image(logoImage, height: 45, width: 45,
                      fit: pw.BoxFit.contain)
                else
                  pw.SizedBox(width: 45),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                          userCompany.isNotEmpty
                              ? userCompany
                              : 'PehlivanİSG',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: PdfColors.amber700)),
                      pw.SizedBox(height: 4),
                      pw.Text('EĞİTİM KATILIM SERTİFİKASI',
                          style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 18,
                              color: PdfColor.fromHex('#1a202c'))),
                      if (sertifikaNo.isNotEmpty)
                        pw.Text('Sertifika No: $sertifikaNo',
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 9,
                                color: PdfColors.grey600)),
                    ]),
                pw.SizedBox(width: 45),
              ],
            ),
            pw.Divider(color: PdfColors.amber700, thickness: 1.5),
            pw.SizedBox(height: 10),
            pw.Text(
              '${k['ad'] ?? ''} ${k['soyad'] ?? ''}',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 22,
                  color: PdfColor.fromHex('#1a202c')),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 6),
            if ((k['gorevi'] as String? ?? '').isNotEmpty)
              pw.Text(
                k['gorevi'] as String,
                style: pw.TextStyle(
                    font: font, fontSize: 12, color: PdfColors.grey700),
                textAlign: pw.TextAlign.center,
              ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber50,
                border: pw.Border.all(color: PdfColors.amber300),
                borderRadius:
                    const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(children: [
                pw.Text(firmaAdi,
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 13,
                        color: PdfColor.fromHex('#1a202c')),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 4),
                pw.Text(s['sertifikaTuru'] as String,
                    style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: PdfColors.amber800),
                    textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 2),
                pw.Text(
                    '${s['tehlikeSinifi']} — ${s['egitimSuresi']} saat',
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.grey700),
                    textAlign: pw.TextAlign.center),
              ]),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('Eğitim Tarihi: ',
                    style: pw.TextStyle(font: fontBold, fontSize: 10)),
                pw.Text(_fmt(tarih),
                    style: pw.TextStyle(font: font, fontSize: 10)),
                if (tarih2 != null) ...[
                  pw.SizedBox(width: 12),
                  pw.Text('Düzenleme Tarihi: ',
                      style: pw.TextStyle(font: fontBold, fontSize: 10)),
                  pw.Text(_fmt(tarih2),
                      style: pw.TextStyle(
                          font: font,
                          fontSize: 10,
                          color: PdfColors.blue700)),
                ],
                pw.SizedBox(width: 12),
                pw.Text('Geçerlilik: ',
                    style: pw.TextStyle(font: fontBold, fontSize: 10)),
                pw.Text(gecerlilikStr,
                    style: pw.TextStyle(
                        font: font,
                        fontSize: 10,
                        color: PdfColors.green700)),
              ],
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColors.grey300),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (imzaImage != null)
                        pw.Image(imzaImage, height: 40, width: 120,
                            fit: pw.BoxFit.contain)
                      else
                        pw.Container(
                            height: 40,
                            width: 120,
                            decoration: pw.BoxDecoration(
                                border: pw.Border(
                                    bottom: pw.BorderSide(
                                        color: PdfColors.grey400)))),
                      pw.SizedBox(height: 4),
                      pw.Text(
                          egitimciIsim.isNotEmpty
                              ? egitimciIsim
                              : (userName.isNotEmpty
                                  ? userName
                                  : 'İş Güvenliği Uzmanı'),
                          style:
                              pw.TextStyle(font: fontBold, fontSize: 9)),
                      if (egitimciUnvan.isNotEmpty)
                        pw.Text(egitimciUnvan,
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                color: PdfColors.grey700)),
                    ]),
                if (hekimIsim.isNotEmpty)
                  pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(
                            height: 40,
                            width: 120,
                            decoration: pw.BoxDecoration(
                                border: pw.Border(
                                    bottom: pw.BorderSide(
                                        color: PdfColors.grey400)))),
                        pw.SizedBox(height: 4),
                        pw.Text(hekimIsim,
                            style:
                                pw.TextStyle(font: fontBold, fontSize: 9)),
                        pw.Text(hekimUnvan,
                            style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                color: PdfColors.grey700)),
                      ]),
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                          height: 40,
                          width: 120,
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColors.grey400)))),
                      pw.SizedBox(height: 4),
                      pw.Text('Çalışan İmzası',
                          style: pw.TextStyle(font: fontBold, fontSize: 9)),
                    ]),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  return Uint8List.fromList(await doc.save());
}

Future<Uint8List> _devamListesiBytes(
    Map<String, dynamic> s, String firmaAdi) async {
  final font = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final tarih = s['egitimTarihi'] as DateTime;
  final tarih2 = s['egitimTarihi2'] as DateTime?;
  final uzmanIsim = (s['uzmanIsim'] as String?)?.trim() ??
      (s['egitimciIsim'] as String?)?.trim() ?? '';
  final uzmanUnvan = (s['uzmanUnvan'] as String?)?.trim() ??
      (s['egitimciUnvan'] as String?)?.trim() ?? '';
  final hekimIsim = (s['hekimIsim'] as String?)?.trim() ?? '';
  final hekimUnvan = (s['hekimUnvan'] as String?)?.trim() ?? '';
  final sertifikaNo = (s['sertifikaNo'] as String?)?.trim() ?? '';
  final imzaPath = (s['imzaPath'] as String?)?.trim() ?? '';

  pw.MemoryImage? imzaImage;
  if (imzaPath.isNotEmpty && File(imzaPath).existsSync()) {
    try {
      imzaImage = pw.MemoryImage(File(imzaPath).readAsBytesSync());
    } catch (_) {}
  }

  final katilimcilar = (s['katilimcilar'] as List).cast<dynamic>();

  final doc = pw.Document();
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.all(20),
    build: (ctx) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(
          child: pw.Text('EĞİTİM KATILIM TUTANAĞI',
              style: pw.TextStyle(font: fontBold, fontSize: 16)),
        ),
        if (sertifikaNo.isNotEmpty)
          pw.Center(
            child: pw.Text('Sertifika No: $sertifikaNo',
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey600)),
          ),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          pw.Text('Firma: ',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Text(firmaAdi,
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(width: 16),
          pw.Text('1. Gün: ',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Text(_fmt(tarih),
              style: pw.TextStyle(font: font, fontSize: 10)),
          if (tarih2 != null) ...[
            pw.SizedBox(width: 10),
            pw.Text('2. Gün: ',
                style: pw.TextStyle(font: fontBold, fontSize: 10)),
            pw.Text(_fmt(tarih2),
                style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ]),
        pw.Row(children: [
          pw.Text('Eğitim Türü: ',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Text(s['sertifikaTuru'] as String,
              style: pw.TextStyle(font: font, fontSize: 10)),
          pw.SizedBox(width: 16),
          pw.Text('Süre: ',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Text('${s['egitimSuresi']} saat',
              style: pw.TextStyle(font: font, fontSize: 10)),
        ]),
        pw.Row(children: [
          pw.Text('Tehlike Sınıfı: ',
              style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Text(s['tehlikeSinifi'] as String,
              style: pw.TextStyle(font: font, fontSize: 10)),
        ]),
        if (uzmanIsim.isNotEmpty)
          pw.Row(children: [
            pw.Text('İGU: ',
                style: pw.TextStyle(font: fontBold, fontSize: 10)),
            pw.Text('$uzmanIsim${uzmanUnvan.isNotEmpty ? ' — $uzmanUnvan' : ''}',
                style: pw.TextStyle(font: font, fontSize: 10)),
          ]),
        if (hekimIsim.isNotEmpty)
          pw.Row(children: [
            pw.Text('Hekim: ',
                style: pw.TextStyle(font: fontBold, fontSize: 10)),
            pw.Text('$hekimIsim${hekimUnvan.isNotEmpty ? ' — $hekimUnvan' : ''}',
                style: pw.TextStyle(font: font, fontSize: 10)),
          ]),
        pw.SizedBox(height: 10),
        pw.Divider(),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(30),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2.5),
          },
          children: [
            pw.TableRow(
              decoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tCell('No', fontBold, center: true),
                _tCell('Ad Soyad', fontBold),
                _tCell('Görevi', fontBold),
                _tCell('İmza', fontBold, center: true),
              ],
            ),
            ...List.generate(katilimcilar.length, (i) {
              final k =
                  Map<String, dynamic>.from(katilimcilar[i] as Map);
              return pw.TableRow(children: [
                _tCell('${i + 1}', font, center: true),
                _tCell('${k['ad'] ?? ''} ${k['soyad'] ?? ''}', font),
                _tCell(k['gorevi'] as String? ?? '', font),
                _tCell('', font),
              ]);
            }),
          ],
        ),
        pw.Spacer(),
        pw.Divider(),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (uzmanIsim.isNotEmpty)
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (imzaImage != null)
                      pw.Image(imzaImage, height: 35, width: 120,
                          fit: pw.BoxFit.contain)
                    else
                      pw.Container(
                          height: 35,
                          width: 120,
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColors.grey400)))),
                    pw.SizedBox(height: 2),
                    pw.Text(uzmanIsim,
                        style: pw.TextStyle(font: fontBold, fontSize: 8)),
                    if (uzmanUnvan.isNotEmpty)
                      pw.Text(uzmanUnvan,
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 7,
                              color: PdfColors.grey700)),
                  ]),
            if (hekimIsim.isNotEmpty)
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                        height: 35,
                        width: 120,
                        decoration: pw.BoxDecoration(
                            border: pw.Border(
                                bottom: pw.BorderSide(
                                    color: PdfColors.grey400)))),
                    pw.SizedBox(height: 2),
                    pw.Text(hekimIsim,
                        style: pw.TextStyle(font: fontBold, fontSize: 8)),
                    if (hekimUnvan.isNotEmpty)
                      pw.Text(hekimUnvan,
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 7,
                              color: PdfColors.grey700)),
                  ]),
          ],
        ),
      ],
    ),
  ));

  return Uint8List.fromList(await doc.save());
}

pw.Widget _tCell(String text, pw.Font font, {bool center = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 9),
          textAlign:
              center ? pw.TextAlign.center : pw.TextAlign.left),
    );

// ─── PDF Önizleme ─────────────────────────────────────────────────────────────

class _PdfOnizleme extends StatelessWidget {
  final String baslik;
  final Future<Uint8List> Function(PdfPageFormat) buildPdf;

  const _PdfOnizleme({required this.baslik, required this.buildPdf});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(baslik,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.of(context).card,
        foregroundColor: AppColors.of(context).text,
        elevation: 0,
      ),
      body: PdfPreview(
        build: buildPdf,
        allowPrinting: false,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: '$baslik.pdf',
      ),
    );
  }
}

// ─── Form ──────────────────────────────────────────────────────────────────

class _SertifikaForm extends StatefulWidget {
  final List<Map<String, dynamic>> firmalar;
  const _SertifikaForm({required this.firmalar});

  @override
  State<_SertifikaForm> createState() => _SertifikaFormState();
}

class _SertifikaFormState extends State<_SertifikaForm> {
  int? _firmaId;
  String _sertifikaTuru = _sertifikaTurleri.first;
  String _tehlikeSinifi = 'TEHLİKELİ';
  String? _ozelKonu;
  String _egitimTipi = 'ILK';
  DateTime _egitimTarihi = DateTime.now();
  DateTime? _egitimTarihi2;
  DateTime? _gecerlilikTarihi;
  int _egitimSuresi = 12;

  final _sertifikaNoCtrl = TextEditingController();

  // Uzman ve hekim — dropdown seçim ID veya null (manuel)
  int? _uzmanId;
  int? _hekimId;
  final _uzmanIsimCtrl = TextEditingController();
  final _uzmanUnvanCtrl = TextEditingController();
  final _hekimIsimCtrl = TextEditingController();
  final _hekimUnvanCtrl = TextEditingController();

  // Eğitimci (bireysel sertifikada gösterilen ad)
  final _egitimciIsimCtrl = TextEditingController();
  final _egitimciUnvanCtrl = TextEditingController();

  // İmza
  String? _imzaPath;

  // Personel havuzu
  List<Map<String, dynamic>> _uzmanlar = [];
  List<Map<String, dynamic>> _hekimler = [];

  // Katılımcılar
  final List<Map<String, dynamic>> _katilimcilar = [];
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _goreviCtrl = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPersonelHavuzu();
  }

  Future<void> _loadPersonelHavuzu() async {
    final uzmanlar =
        await DatabaseService.getPersonelHavuzu(tip: 'UZMAN');
    final hekimler =
        await DatabaseService.getPersonelHavuzu(tip: 'HEKIM');
    if (mounted) {
      setState(() {
        _uzmanlar = uzmanlar;
        _hekimler = hekimler;
      });
    }
  }

  void _firmaSecildi(int? id) {
    if (id == null) {
      setState(() => _firmaId = null);
      return;
    }
    final firma = widget.firmalar.firstWhere(
      (f) => f['id'] == id,
      orElse: () => {},
    );
    setState(() {
      _firmaId = id;
      // Firma'nın ISG-Katip bilgilerini ön doldur
      final fUzman = (firma['uzmanIsim'] as String?) ?? '';
      final fUzmanUnvan = (firma['uzmanUnvan'] as String?) ?? '';
      final fHekim = (firma['hekimIsim'] as String?) ?? '';
      final fHekimUnvan = (firma['hekimUnvan'] as String?) ?? '';
      if (fUzman.isNotEmpty) {
        _uzmanIsimCtrl.text = fUzman;
        _uzmanUnvanCtrl.text = fUzmanUnvan;
        _egitimciIsimCtrl.text = fUzman;
        _egitimciUnvanCtrl.text = fUzmanUnvan;
      }
      if (fHekim.isNotEmpty) {
        _hekimIsimCtrl.text = fHekim;
        _hekimUnvanCtrl.text = fHekimUnvan;
      }
    });
  }

  void _tehlikeSecildi(String sinif) {
    setState(() {
      _tehlikeSinifi = sinif;
      _egitimSuresi = _tehlikeSuresi[sinif] ?? 12;
    });
  }

  Future<void> _tarihSec({bool ikinci = false}) async {
    final initial = ikinci ? (_egitimTarihi2 ?? _egitimTarihi) : _egitimTarihi;
    final secilen = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (secilen == null) return;
    setState(() {
      if (ikinci) {
        _egitimTarihi2 = secilen;
      } else {
        _egitimTarihi = secilen;
        _gecerlilikTarihi =
            DateTime(secilen.year + 1, secilen.month, secilen.day);
      }
    });
  }

  Future<void> _imzaSec() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _imzaPath = picked.path);
    }
  }

  void _uzmanSecildi(int? id) {
    setState(() {
      _uzmanId = id;
      if (id == null) {
        _uzmanIsimCtrl.clear();
        _uzmanUnvanCtrl.clear();
        return;
      }
      final p = _uzmanlar.firstWhere((u) => u['id'] == id);
      final isim = p['isim'] as String? ?? '';
      final unvan = p['unvan'] as String? ?? '';
      final belgeNo = p['belgeNo'] as String? ?? '';
      _uzmanIsimCtrl.text = isim;
      _uzmanUnvanCtrl.text =
          '$unvan${belgeNo.isNotEmpty ? ' — Belge No: $belgeNo' : ''}';
      _egitimciIsimCtrl.text = isim;
      _egitimciUnvanCtrl.text =
          '$unvan${belgeNo.isNotEmpty ? ' — Belge No: $belgeNo' : ''}';
    });
  }

  void _hekimSecildi(int? id) {
    setState(() {
      _hekimId = id;
      if (id == null) {
        _hekimIsimCtrl.clear();
        _hekimUnvanCtrl.clear();
        return;
      }
      final p = _hekimler.firstWhere((h) => h['id'] == id);
      final isim = p['isim'] as String? ?? '';
      final unvan = p['unvan'] as String? ?? '';
      final belgeNo = p['belgeNo'] as String? ?? '';
      _hekimIsimCtrl.text = isim;
      _hekimUnvanCtrl.text =
          '$unvan${belgeNo.isNotEmpty ? ' — Belge No: $belgeNo' : ''}';
    });
  }

  void _katilimciEkle() {
    final ad = _adCtrl.text.trim();
    final soyad = _soyadCtrl.text.trim();
    if (ad.isEmpty && soyad.isEmpty) return;
    setState(() {
      _katilimcilar.add({
        'ad': ad,
        'soyad': soyad,
        'gorevi': _goreviCtrl.text.trim(),
      });
      _adCtrl.clear();
      _soyadCtrl.clear();
      _goreviCtrl.clear();
    });
  }

  Future<void> _kaydet() async {
    if (_firmaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firma seçmelisiniz')),
      );
      return;
    }
    setState(() => _saving = true);

    final id = await DatabaseService.insertSertifika(
      firmaId: _firmaId!,
      sertifikaTuru: _sertifikaTuru,
      tehlikeSinifi: _tehlikeSinifi,
      ozelKonu: _ozelKonu,
      egitimTarihi: _egitimTarihi,
      egitimTarihi2: _egitimTarihi2,
      egitimSuresi: _egitimSuresi,
      egitimTipi: _egitimTipi,
      egitimciIsim: _egitimciIsimCtrl.text.trim().isNotEmpty
          ? _egitimciIsimCtrl.text.trim()
          : null,
      egitimciUnvan: _egitimciUnvanCtrl.text.trim().isNotEmpty
          ? _egitimciUnvanCtrl.text.trim()
          : null,
      uzmanIsim: _uzmanIsimCtrl.text.trim().isNotEmpty
          ? _uzmanIsimCtrl.text.trim()
          : null,
      uzmanUnvan: _uzmanUnvanCtrl.text.trim().isNotEmpty
          ? _uzmanUnvanCtrl.text.trim()
          : null,
      hekimIsim: _hekimIsimCtrl.text.trim().isNotEmpty
          ? _hekimIsimCtrl.text.trim()
          : null,
      hekimUnvan: _hekimUnvanCtrl.text.trim().isNotEmpty
          ? _hekimUnvanCtrl.text.trim()
          : null,
      sertifikaNo: _sertifikaNoCtrl.text.trim().isNotEmpty
          ? _sertifikaNoCtrl.text.trim()
          : null,
      imzaPath: _imzaPath,
      gecerlilikTarihi: _gecerlilikTarihi,
      katilimcilar: _katilimcilar,
    );

    // Kaydedilen sertifikayı geri al (PDF için)
    final sertList = await DatabaseService.getSertifikalar(
        firmaId: _firmaId);
    final sert = sertList.firstWhere(
      (s) => s['id'] == id,
      orElse: () => {
        'sertifikaTuru': _sertifikaTuru,
        'tehlikeSinifi': _tehlikeSinifi,
        'egitimTarihi': _egitimTarihi,
        'egitimTarihi2': _egitimTarihi2,
        'egitimSuresi': _egitimSuresi,
        'egitimTipi': _egitimTipi,
        'egitimciIsim': _egitimciIsimCtrl.text.trim(),
        'egitimciUnvan': _egitimciUnvanCtrl.text.trim(),
        'uzmanIsim': _uzmanIsimCtrl.text.trim(),
        'uzmanUnvan': _uzmanUnvanCtrl.text.trim(),
        'hekimIsim': _hekimIsimCtrl.text.trim(),
        'hekimUnvan': _hekimUnvanCtrl.text.trim(),
        'sertifikaNo': _sertifikaNoCtrl.text.trim(),
        'imzaPath': _imzaPath,
        'gecerlilikTarihi': _gecerlilikTarihi,
        'katilimcilar': _katilimcilar,
        'firmaId': _firmaId,
      },
    );

    final firma = widget.firmalar.firstWhere(
      (f) => f['id'] == _firmaId,
      orElse: () => {'isim': ''},
    );
    final firmaAdi = firma['isim'] as String;

    // Her katılımcı için bireysel PDF oluştur ve belgeler'e kaydet
    if (_katilimcilar.isNotEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final sertDir =
            Directory(p.join(appDir.path, 'sertifikalar', '$_firmaId'));
        if (!sertDir.existsSync()) sertDir.createSync(recursive: true);

        final bytes = await _bireyselPdfBytes(sert, firmaAdi);
        for (int i = 0; i < _katilimcilar.length; i++) {
          final k = _katilimcilar[i];
          final ad = '${k['ad'] ?? ''}_${k['soyad'] ?? ''}'.replaceAll(' ', '_');
          final dosyaYolu = p.join(sertDir.path, '${ad}_$id.pdf');
          File(dosyaYolu).writeAsBytesSync(bytes);
          await DatabaseService.insertBelge(
            firmaId: _firmaId!,
            baslik:
                'Sertifika — ${k['ad'] ?? ''} ${k['soyad'] ?? ''}',
            dosyaYolu: dosyaYolu,
            tur: 'Sertifika',
            gecerlilikTarihi: _gecerlilikTarihi,
          );
        }
      } catch (_) {}
    }

    if (!mounted) return;

    // PDF önizleme göster
    final previewSert = sert;
    final previewFirmaAdi = firmaAdi;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => _PdfOnizleme(
                baslik: 'Devam Listesi — $firmaAdi',
                buildPdf: (_) async =>
                    _devamListesiBytes(previewSert, previewFirmaAdi),
              )),
    );
  }

  @override
  void dispose() {
    _sertifikaNoCtrl.dispose();
    _uzmanIsimCtrl.dispose();
    _uzmanUnvanCtrl.dispose();
    _hekimIsimCtrl.dispose();
    _hekimUnvanCtrl.dispose();
    _egitimciIsimCtrl.dispose();
    _egitimciUnvanCtrl.dispose();
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _goreviCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Yeni Sertifika',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: c.text, fontSize: 17)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _kaydet,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFFE8B84B)))
                : Text('Kaydet & Önizle',
                    style: GoogleFonts.inter(
                        color: const Color(0xFFE8B84B),
                        fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── FİRMA ───────────────────────────────────────
            FormSection(title: 'FİRMA', c: c, children: [
              DropdownButtonFormField<int>(
                value: _firmaId,
                dropdownColor: c.card,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                hint: Text('Firma seçin *',
                    style: GoogleFonts.inter(
                        color: c.textMuted, fontSize: 13)),
                decoration: buildInputDecoration(c, 'Firma'),
                items: widget.firmalar
                    .map((f) => DropdownMenuItem<int>(
                          value: f['id'] as int,
                          child: Text(f['isim'] as String,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: c.text)),
                        ))
                    .toList(),
                onChanged: _firmaSecildi,
              ),
            ]),
            const SizedBox(height: 12),

            // ── EĞİTİM BİLGİLERİ ───────────────────────────
            FormSection(title: 'EĞİTİM BİLGİLERİ', c: c, children: [
              TextFormField(
                controller: _sertifikaNoCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration:
                    buildInputDecoration(c, 'Sertifika Numarası (opsiyonel)'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _sertifikaTuru,
                dropdownColor: c.card,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(c, 'Sertifika Türü'),
                items: _sertifikaTurleri
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: c.text)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _sertifikaTuru = v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _tehlikeSinifi,
                dropdownColor: c.card,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(c, 'Tehlike Sınıfı *'),
                items: _tehlikeSiniflari
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: c.text)),
                        ))
                    .toList(),
                onChanged: (v) => _tehlikeSecildi(v!),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: _ozelKonu,
                dropdownColor: c.card,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration:
                    buildInputDecoration(c, 'Özel Konu (opsiyonel)'),
                items: [
                  DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Yok',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: c.textMuted))),
                  ..._ozelKonular.map((k) => DropdownMenuItem<String?>(
                        value: k,
                        child: Text(k,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: c.text)),
                      )),
                ],
                onChanged: (v) => setState(() => _ozelKonu = v),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _egitimTipi,
                    dropdownColor: c.card,
                    style: GoogleFonts.inter(color: c.text, fontSize: 13),
                    decoration: buildInputDecoration(c, 'Eğitim Tipi'),
                    items: [
                      DropdownMenuItem(
                          value: 'ILK',
                          child: Text('İLK EĞİTİM',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: c.text))),
                      DropdownMenuItem(
                          value: 'YENILEME',
                          child: Text('YENİLEME',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: c.text))),
                    ],
                    onChanged: (v) => setState(() => _egitimTipi = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: _egitimSuresi.toString(),
                    style: GoogleFonts.inter(color: c.text, fontSize: 13),
                    decoration: buildInputDecoration(c, 'Süre (saat)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(
                        () =>
                            _egitimSuresi = int.tryParse(v) ?? _egitimSuresi),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              // 1. Eğitim Tarihi
              InkWell(
                onTap: () => _tarihSec(ikinci: false),
                child: InputDecorator(
                  decoration: buildInputDecoration(c, '1. Eğitim Tarihi *'),
                  child: Row(children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: c.textMuted),
                    const SizedBox(width: 8),
                    Text(_fmtDate(_egitimTarihi),
                        style: GoogleFonts.inter(
                            color: c.text, fontSize: 13)),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              // 2. Eğitim Tarihi / Düzenleme Tarihi
              InkWell(
                onTap: () => _tarihSec(ikinci: true),
                child: InputDecorator(
                  decoration: buildInputDecoration(
                      c, '2. Eğitim Tarihi / Düzenleme Tarihi (opsiyonel)'),
                  child: Row(children: [
                    Icon(Icons.event_repeat_rounded,
                        size: 14, color: c.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      _egitimTarihi2 != null
                          ? _fmtDate(_egitimTarihi2!)
                          : 'Seçmek için dokunun',
                      style: GoogleFonts.inter(
                          color: _egitimTarihi2 != null
                              ? c.text
                              : c.textMuted,
                          fontSize: 13),
                    ),
                    if (_egitimTarihi2 != null) ...[
                      const Spacer(),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _egitimTarihi2 = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: c.textMuted),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 12),

            // ── UZMAN ───────────────────────────────────────
            FormSection(title: 'İŞ GÜVENLİĞİ UZMANI', c: c, children: [
              if (_uzmanlar.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: _uzmanId,
                  dropdownColor: c.card,
                  style: GoogleFonts.inter(color: c.text, fontSize: 13),
                  decoration:
                      buildInputDecoration(c, 'Havuzdan Seç (opsiyonel)'),
                  items: [
                    DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Manuel giriş',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: c.textMuted))),
                    ..._uzmanlar.map((u) => DropdownMenuItem<int?>(
                          value: u['id'] as int,
                          child: Text(
                              '${u['isim']}${(u['unvan'] as String?)?.isNotEmpty == true ? ' — ${u['unvan']}' : ''}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: c.text)),
                        )),
                  ],
                  onChanged: _uzmanSecildi,
                ),
              if (_uzmanlar.isNotEmpty) const SizedBox(height: 10),
              TextFormField(
                controller: _uzmanIsimCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(c, 'Uzman Ad Soyad'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _uzmanUnvanCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration:
                    buildInputDecoration(c, 'Unvan / Sınıf / Belge No'),
              ),
            ]),
            const SizedBox(height: 12),

            // ── HEKİM ───────────────────────────────────────
            FormSection(title: 'İŞYERİ HEKİMİ', c: c, children: [
              if (_hekimler.isNotEmpty)
                DropdownButtonFormField<int?>(
                  value: _hekimId,
                  dropdownColor: c.card,
                  style: GoogleFonts.inter(color: c.text, fontSize: 13),
                  decoration:
                      buildInputDecoration(c, 'Havuzdan Seç (opsiyonel)'),
                  items: [
                    DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Manuel giriş',
                            style: GoogleFonts.inter(
                                fontSize: 13, color: c.textMuted))),
                    ..._hekimler.map((h) => DropdownMenuItem<int?>(
                          value: h['id'] as int,
                          child: Text(
                              '${h['isim']}${(h['unvan'] as String?)?.isNotEmpty == true ? ' — ${h['unvan']}' : ''}',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: c.text)),
                        )),
                  ],
                  onChanged: _hekimSecildi,
                ),
              if (_hekimler.isNotEmpty) const SizedBox(height: 10),
              TextFormField(
                controller: _hekimIsimCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(c, 'Hekim Ad Soyad'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _hekimUnvanCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(
                    c, 'Unvan / Diploma-Tescil / Belge No'),
              ),
            ]),
            const SizedBox(height: 12),

            // ── EĞİTİMCİ (Sertifikada Görünür) ─────────────
            FormSection(
                title: 'EĞİTİMCİ (SERTİFİKADA GÖRÜNÜR)',
                c: c,
                children: [
                  TextFormField(
                    controller: _egitimciIsimCtrl,
                    style: GoogleFonts.inter(color: c.text, fontSize: 13),
                    decoration:
                        buildInputDecoration(c, 'Eğitimci Ad Soyad'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _egitimciUnvanCtrl,
                    style: GoogleFonts.inter(color: c.text, fontSize: 13),
                    decoration:
                        buildInputDecoration(c, 'Unvan / Belge No'),
                  ),
                ]),
            const SizedBox(height: 12),

            // ── İMZA ────────────────────────────────────────
            FormSection(title: 'İMZA (PDF\'DE GÖRÜNÜR)', c: c, children: [
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _imzaSec,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: _imzaPath != null
                                ? const Color(0xFFE8B84B)
                                : c.border),
                      ),
                      child: _imzaPath != null &&
                              File(_imzaPath!).existsSync()
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(_imzaPath!),
                                  fit: BoxFit.contain),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.draw_rounded,
                                    color: c.textMuted, size: 24),
                                const SizedBox(height: 4),
                                Text('İmza görseli seç',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: c.textMuted)),
                              ],
                            ),
                    ),
                  ),
                ),
                if (_imzaPath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444)),
                    onPressed: () => setState(() => _imzaPath = null),
                  ),
                ],
              ]),
            ]),
            const SizedBox(height: 12),

            // ── KATILIMCILAR ─────────────────────────────────
            FormSection(
                title: 'KATILIMCILAR (${_katilimcilar.length})',
                c: c,
                children: [
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _adCtrl,
                        style: GoogleFonts.inter(
                            color: c.text, fontSize: 13),
                        decoration: buildInputDecoration(c, 'Ad'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _soyadCtrl,
                        style: GoogleFonts.inter(
                            color: c.text, fontSize: 13),
                        decoration: buildInputDecoration(c, 'Soyad'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _goreviCtrl,
                        style: GoogleFonts.inter(
                            color: c.text, fontSize: 13),
                        decoration:
                            buildInputDecoration(c, 'Görevi (opsiyonel)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _katilimciEkle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8B84B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Icon(Icons.add_rounded),
                    ),
                  ]),
                  if (_katilimcilar.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...List.generate(_katilimcilar.length, (i) {
                      final k = _katilimcilar[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: c.bg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8B84B)
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Text('${i + 1}',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE8B84B))),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('${k['ad']} ${k['soyad']}',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: c.text)),
                                if ((k['gorevi'] as String).isNotEmpty)
                                  Text(k['gorevi'] as String,
                                      style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: c.textMuted)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                                Icons.remove_circle_outline_rounded,
                                color: const Color(0xFFEF4444),
                                size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => setState(
                                () => _katilimcilar.removeAt(i)),
                          ),
                        ]),
                      );
                    }),
                  ],
                ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
