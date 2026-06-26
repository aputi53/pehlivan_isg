import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';
import 'package:pehlivan_isg/widgets/form_helpers.dart';

// ─── Sabitler ────────────────────────────────────────────────────────────────

const _egitimTurleri = [
  {'key': 'temel_isg', 'ad': 'Temel İSG Eğitimi', 'minSure': 8},
  {'key': 'oryantasyon', 'ad': 'Oryantasyon Eğitimi', 'minSure': 2},
  {'key': 'acil_durum_ekibi', 'ad': 'Acil Durum Ekibi Eğitimi', 'minSure': 4},
  {'key': 'is_kazasi_sonrasi', 'ad': 'İş Kazası Sonrası Eğitimi', 'minSure': 2},
  {'key': 'yuksekte_calisma', 'ad': 'Yüksekte Çalışma Eğitimi', 'minSure': 4},
  {'key': 'calisan_temsilci', 'ad': 'Çalışan Temsilcisi Eğitimi', 'minSure': 4},
  {'key': 'destek_elemani', 'ad': 'Destek Elemanı Eğitimi', 'minSure': 4},
];

const _tehlikeSiniflari = ['AZ TEHLİKELİ', 'TEHLİKELİ', 'ÇOK TEHLİKELİ'];

const _ozelRiskler = [
  'YÜKSEKTE GÜVENLİ ÇALIŞMA',
  'KAPALI ORTAMDA ÇALIŞMA',
  'YANGIN VE RADYASYON RİSKİNİN BULUNDUĞU ORTAMDA ÇALIŞMA',
  'İŞYERİNİN ACİL DURUM PLANI',
  'ÖZEL RİSK TAŞIYAN EKİPMAN İLE ÇALIŞMA',
  'YANGINLA MÜCADELE',
  'KAYNAKLA ÇALIŞMA',
  'RİSK DEĞERLENDİRMESİ DOKÜMANI',
  'KANSEROJEN MUTAJEN MADDELERLE ÇALIŞMA',
  'KİMYASAL VE BİYOLOJİK ETKENLERLE ÇALIŞMA',
];

const Map<String, List<String>> _egitimKonulari = {
  'Temel İSG Eğitimi': [
    'Çalışma mevzuatı ile ilgili bilgiler',
    'Çalışanların yasal hak ve sorumlulukları',
    'İşyeri temizliği ve düzeni',
    'İş kazası ve meslek hastalığından doğan hukuki sonuçlar',
    'Kimyasal, fiziksel ve ergonomik risk etmenleri',
    'Elle kaldırma ve taşıma',
    'Parlama, patlama',
    'Yangın ve yangından korunma',
    'İş ekipmanlarının güvenli kullanımı',
    'Elektrik, tehlikeleri, riskleri ve önlemleri',
    'İş kazalarının sebepleri ve korunma prensipleri',
    'Acil durumlar, tahliye ve kurtarma',
    'Sağlık ve güvenlik işaretleri',
    'Kişisel koruyucu donanım kullanımı',
    'Meslek hastalıklarının sebepleri',
    'Biyolojik ve psikolojik risk etmenleri',
    'İlkyardım',
  ],
  'Oryantasyon Eğitimi': [
    'İşyeri tanıtımı ve genel güvenlik kuralları',
    'Acil çıkışlar, toplanma noktaları ve tahliye prosedürü',
    'İşyerinin genel riskleri ve tehlikeli bölgeler',
    'Kişisel koruyucu donanımların tanıtımı ve kullanımı',
    'İşyerindeki acil durum ekibi ve iletişim bilgileri',
  ],
  'Acil Durum Ekibi Eğitimi': [
    'Acil durum kavramı ve yasal çerçeve',
    'Acil durum ekibi görev ve sorumlulukları',
    'Tahliye prosedürleri ve toplanma noktaları',
    'İlk yardım temel uygulamaları',
    'Yangın söndürme ekipmanları ve kullanımı',
    'Kurtarma ve müdahale teknikleri',
  ],
  'İş Kazası Sonrası Eğitimi': [
    'Gerçekleşen iş kazasının analizi ve kök neden',
    'Kazanın tekrar oluşmaması için alınacak önlemler',
    'İSG kurallarına uyumun önemi',
    'Güvenli çalışma prosedürlerinin tekrarı',
  ],
  'Yüksekte Çalışma Eğitimi': [
    'Yükseklik kavramı, düşme nedenleri ve güvenli çalışma ilkeleri',
    'Yüksekte çalışma esnasında alınacak teknik güvenlik önlemleri',
    'Kişisel koruyucu donanımlar ve doğru kullanımı',
    'Emniyet kemeri, ip ve lifeline sistemleri',
    'İskele ve platform güvenliği',
    'Yüksekte çalışmada acil durum prosedürleri',
  ],
  'Çalışan Temsilcisi Eğitimi': [
    'Çalışan temsilcisinin görev ve sorumlulukları',
    'İş sağlığı ve güvenliği kurulu çalışmaları',
    'Risk değerlendirme sürecine katılım',
    'Çalışanlardan gelen şikâyet ve önerilerin değerlendirilmesi',
  ],
  'Destek Elemanı Eğitimi': [
    'Destek elemanının görev ve sorumlulukları',
    'Acil durum müdahale teknikleri',
    'İlk yardım uygulamaları',
    'İletişim ve koordinasyon prosedürleri',
  ],
};

String _turAdi(String key) {
  final tur = _egitimTurleri.firstWhere(
    (t) => t['key'] == key,
    orElse: () => {'ad': key},
  );
  return tur['ad'] as String;
}

// ─── Ana Sayfa ────────────────────────────────────────────────────────────────

class EgitimKatilimPage extends StatefulWidget {
  const EgitimKatilimPage({super.key});

  @override
  State<EgitimKatilimPage> createState() => _EgitimKatilimPageState();
}

class _EgitimKatilimPageState extends State<EgitimKatilimPage> {
  List<Map<String, dynamic>> _kayitlar = [];
  List<Map<String, dynamic>> _firmalar = [];
  bool _loading = true;
  int? _seciliFirmaId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final kayitlar =
        await DatabaseService.getEgitimKatilimlar(firmaId: _seciliFirmaId);
    final firms = await DatabaseService.getAllFirmalar();
    if (mounted) {
      setState(() {
        _kayitlar = kayitlar;
        _firmalar = firms;
        _loading = false;
      });
    }
  }

  String _formatTarih(DateTime d) =>
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
          icon: Icon(Icons.arrow_back_rounded, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Eğitim Katılım Tutanağı',
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: c.text, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFE8B84B)),
            tooltip: 'Yeni Tutanak',
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          _EgitimKatilimForm(firmalar: _firmalar)));
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: c.border)),
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
                : _kayitlar.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.assignment_rounded,
                        title: 'Henüz tutanak yok',
                        subtitle:
                            'Yeni tutanak eklemek için + butonuna dokunun',
                        iconColor: Color(0xFFE8B84B),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _kayitlar.length,
                        itemBuilder: (_, i) {
                          final k = _kayitlar[i];
                          final tarih = k['egitimTarihi'] as DateTime;
                          final katSayisi =
                              (k['katilimcilar'] as List).length;
                          final firma = _firmalar.firstWhere(
                            (f) => f['id'] == k['firmaId'],
                            orElse: () => {'isim': '—'},
                          );
                          final tehlike =
                              k['tehlikeSinifi'] as String? ?? '';

                          return Card(
                            color: c.card,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                    color:
                                        c.border.withValues(alpha: 0.5))),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        _turAdi(k['egitimTuru'] as String),
                                        style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            color: c.text,
                                            fontSize: 14),
                                      ),
                                    ),
                                    if (tehlike.isNotEmpty)
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8B84B)
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color:
                                                  const Color(0xFFE8B84B)
                                                      .withValues(
                                                          alpha: 0.4)),
                                        ),
                                        child: Text(tehlike,
                                            style: GoogleFonts.inter(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(
                                                    0xFFE8B84B))),
                                      ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(
                                    firma['isim'] as String,
                                    style: GoogleFonts.inter(
                                        color: const Color(0xFFE8B84B),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(children: [
                                    Icon(Icons.calendar_today_rounded,
                                        size: 12, color: c.textMuted),
                                    const SizedBox(width: 4),
                                    Text(_formatTarih(tarih),
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: c.textMuted)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.timer_outlined,
                                        size: 12, color: c.textMuted),
                                    const SizedBox(width: 4),
                                    Text('${k['egitimSuresi']} saat',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: c.textMuted)),
                                    const SizedBox(width: 12),
                                    Icon(Icons.group_rounded,
                                        size: 12, color: c.textMuted),
                                    const SizedBox(width: 4),
                                    Text('$katSayisi kişi',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: c.textMuted)),
                                  ]),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      AksiyanButon(
                                        icon: Icons.picture_as_pdf_rounded,
                                        label: 'Devam Listesi PDF',
                                        color: const Color(0xFF4FC3F7),
                                        onTap: () => _pdfDevamListesi(
                                            k, firma['isim'] as String),
                                      ),
                                      const SizedBox(width: 8),
                                      AksiyanButon(
                                        icon: Icons.delete_outline_rounded,
                                        label: 'Sil',
                                        color: const Color(0xFFEF4444),
                                        onTap: () =>
                                            _silOnay(k['id'] as int),
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

  Future<void> _silOnay(int id) async {
    final c = AppColors.of(context);
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Tutanak Sil',
            style: GoogleFonts.inter(color: c.text)),
        content: Text('Bu eğitim tutanağı silinecek. Emin misiniz?',
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
      await DatabaseService.deleteEgitimKatilim(id);
      _loadData();
    }
  }

  Future<void> _pdfDevamListesi(
      Map<String, dynamic> k, String firmaAdi) async {
    final katilimcilar = (k['katilimcilar'] as List).cast<dynamic>();
    final ozelRisklerList =
        (k['ozelRiskler'] as List).cast<String>();

    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final tarih = k['egitimTarihi'] as DateTime;
    final tarihStr =
        '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';
    final turAdi = _turAdi(k['egitimTuru'] as String);
    final konular = _egitimKonulari[turAdi] ?? [];

    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Column(children: [
              pw.Text('EĞİTİM KATILIM TUTANAĞI',
                  style: pw.TextStyle(font: fontBold, fontSize: 15)),
              pw.SizedBox(height: 4),
              pw.Text(turAdi.toUpperCase(),
                  style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: PdfColors.amber700)),
            ]),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(thickness: 1),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Text('Firma: ',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
            pw.Text(firmaAdi,
                style: pw.TextStyle(font: font, fontSize: 9)),
            pw.SizedBox(width: 12),
            pw.Text('Tarih: ',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
            pw.Text(tarihStr,
                style: pw.TextStyle(font: font, fontSize: 9)),
            pw.SizedBox(width: 12),
            pw.Text('Süre: ',
                style: pw.TextStyle(font: fontBold, fontSize: 9)),
            pw.Text('${k['egitimSuresi']} saat',
                style: pw.TextStyle(font: font, fontSize: 9)),
          ]),
          if (k['tehlikeSinifi'] != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Row(children: [
                pw.Text('Tehlike Sınıfı: ',
                    style: pw.TextStyle(font: fontBold, fontSize: 9)),
                pw.Text(k['tehlikeSinifi'] as String,
                    style: pw.TextStyle(font: font, fontSize: 9)),
              ]),
            ),
          if (ozelRisklerList.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Özel Riskler: ',
                      style: pw.TextStyle(font: fontBold, fontSize: 9)),
                  pw.Expanded(
                    child: pw.Text(ozelRisklerList.join(', '),
                        style: pw.TextStyle(
                            font: font,
                            fontSize: 8,
                            color: PdfColors.grey700)),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 6),
          if (konular.isNotEmpty) ...[
            pw.Text('EĞİTİM KONULARI:',
                style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 8,
                    color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            ...konular
                .map((konu) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 1),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ',
                              style:
                                  pw.TextStyle(font: font, fontSize: 7)),
                          pw.Expanded(
                            child: pw.Text(konu,
                                style: pw.TextStyle(
                                    font: font, fontSize: 7)),
                          ),
                        ],
                      ),
                    ))
                ,
            pw.SizedBox(height: 6),
          ],
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 4),
          pw.Text('KATILIMCILAR:',
              style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 8,
                  color: PdfColors.grey700)),
          pw.SizedBox(height: 4),
          pw.Table(
            border:
                pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: {
              0: const pw.FixedColumnWidth(25),
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
                final kat =
                    Map<String, dynamic>.from(katilimcilar[i] as Map);
                return pw.TableRow(children: [
                  _tCell('${i + 1}', font, center: true),
                  _tCell(
                      '${kat['ad'] ?? ''} ${kat['soyad'] ?? ''}', font),
                  _tCell(kat['gorevi'] as String? ?? '', font),
                  _tCell('', font),
                ]);
              }),
            ],
          ),
          pw.Spacer(),
          pw.Divider(thickness: 0.5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              if (k['egitimciIsim'] != null &&
                  (k['egitimciIsim'] as String).isNotEmpty)
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                          height: 30,
                          width: 110,
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColors.grey400)))),
                      pw.SizedBox(height: 2),
                      pw.Text(k['egitimciIsim'] as String,
                          style:
                              pw.TextStyle(font: fontBold, fontSize: 7)),
                      pw.Text(k['egitimciUnvan'] as String? ?? '',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 6,
                              color: PdfColors.grey700)),
                    ]),
              if (k['hekimIsim'] != null &&
                  (k['hekimIsim'] as String).isNotEmpty)
                pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                          height: 30,
                          width: 110,
                          decoration: pw.BoxDecoration(
                              border: pw.Border(
                                  bottom: pw.BorderSide(
                                      color: PdfColors.grey400)))),
                      pw.SizedBox(height: 2),
                      pw.Text(k['hekimIsim'] as String,
                          style:
                              pw.TextStyle(font: fontBold, fontSize: 7)),
                      pw.Text(k['hekimUnvan'] as String? ?? '',
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 6,
                              color: PdfColors.grey700)),
                    ]),
            ],
          ),
        ],
      ),
    ));

    final bytes = await doc.save();
    final dir = await getTemporaryDirectory();
    final dosya = File('${dir.path}/EgitimKatilim_$firmaAdi.pdf');
    await dosya.writeAsBytes(bytes);

    await Share.shareXFiles([XFile(dosya.path)],
        text: '$firmaAdi — Eğitim Katılım Tutanağı');
  }
}

pw.Widget _tCell(String text, pw.Font font, {bool center = false}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      child: pw.Text(text,
          style: pw.TextStyle(font: font, fontSize: 8),
          textAlign:
              center ? pw.TextAlign.center : pw.TextAlign.left),
    );

// ─── Form ──────────────────────────────────────────────────────────────────

class _EgitimKatilimForm extends StatefulWidget {
  final List<Map<String, dynamic>> firmalar;
  const _EgitimKatilimForm({required this.firmalar});

  @override
  State<_EgitimKatilimForm> createState() => _EgitimKatilimFormState();
}

class _EgitimKatilimFormState extends State<_EgitimKatilimForm> {
  int? _firmaId;
  String _egitimTuru = 'temel_isg';
  String? _tehlikeSinifi;
  final Set<String> _ozelRisklerSec = {};
  DateTime _egitimTarihi = DateTime.now();
  int _egitimSuresi = 8;

  final _egitimciIsimCtrl = TextEditingController();
  final _egitimciUnvanCtrl = TextEditingController();
  final _hekimIsimCtrl = TextEditingController();
  final _hekimUnvanCtrl = TextEditingController();

  final List<Map<String, dynamic>> _katilimcilar = [];
  final _adCtrl = TextEditingController();
  final _soyadCtrl = TextEditingController();
  final _goreviCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _egitimciIsimCtrl.dispose();
    _egitimciUnvanCtrl.dispose();
    _hekimIsimCtrl.dispose();
    _hekimUnvanCtrl.dispose();
    _adCtrl.dispose();
    _soyadCtrl.dispose();
    _goreviCtrl.dispose();
    super.dispose();
  }

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      initialDate: _egitimTarihi,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (secilen != null) setState(() => _egitimTarihi = secilen);
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
    await DatabaseService.insertEgitimKatilim(
      firmaId: _firmaId!,
      egitimTuru: _egitimTuru,
      tehlikeSinifi: _tehlikeSinifi,
      ozelRiskler: _ozelRisklerSec.toList(),
      egitimTarihi: _egitimTarihi,
      egitimSuresi: _egitimSuresi,
      egitimciIsim: _egitimciIsimCtrl.text.trim().isNotEmpty
          ? _egitimciIsimCtrl.text.trim()
          : null,
      egitimciUnvan: _egitimciUnvanCtrl.text.trim().isNotEmpty
          ? _egitimciUnvanCtrl.text.trim()
          : null,
      hekimIsim: _hekimIsimCtrl.text.trim().isNotEmpty
          ? _hekimIsimCtrl.text.trim()
          : null,
      hekimUnvan: _hekimUnvanCtrl.text.trim().isNotEmpty
          ? _hekimUnvanCtrl.text.trim()
          : null,
      katilimcilar: _katilimcilar,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final tarihStr =
        '${_egitimTarihi.day.toString().padLeft(2, '0')}.${_egitimTarihi.month.toString().padLeft(2, '0')}.${_egitimTarihi.year}';

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: c.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Yeni Eğitim Tutanağı',
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
                : Text('Kaydet',
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
            // Firma
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
                onChanged: (v) => setState(() => _firmaId = v),
              ),
            ]),
            const SizedBox(height: 12),
            // Eğitim türü grid
            FormSection(title: 'EĞİTİM TÜRÜ', c: c, children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 2.4,
                children: _egitimTurleri.map((t) {
                  final secili = _egitimTuru == t['key'];
                  return GestureDetector(
                    onTap: () => setState(() {
                      _egitimTuru = t['key'] as String;
                      _egitimSuresi = (t['minSure'] as int?) ?? 4;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: secili
                            ? const Color(0xFFE8B84B)
                                .withValues(alpha: 0.15)
                            : c.bg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: secili
                              ? const Color(0xFFE8B84B)
                              : c.border,
                          width: secili ? 1.5 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          t['ad'] as String,
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: secili
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: secili
                                  ? const Color(0xFFE8B84B)
                                  : c.textMuted),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 12),
            // Eğitim detayları
            FormSection(title: 'EĞİTİM DETAYLARI', c: c, children: [
              DropdownButtonFormField<String?>(
                value: _tehlikeSinifi,
                dropdownColor: c.card,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(c, 'Tehlike Sınıfı'),
                items: [
                  DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Seçilmedi',
                          style: GoogleFonts.inter(
                              color: c.textMuted, fontSize: 13))),
                  ..._tehlikeSiniflari.map((t) => DropdownMenuItem<String?>(
                        value: t,
                        child: Text(t,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: c.text)),
                      )),
                ],
                onChanged: (v) => setState(() => _tehlikeSinifi = v),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _egitimSuresi.toString(),
                    style: GoogleFonts.inter(color: c.text, fontSize: 13),
                    decoration: buildInputDecoration(c, 'Süre (saat)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() =>
                        _egitimSuresi = int.tryParse(v) ?? _egitimSuresi),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _tarihSec,
                    child: InputDecorator(
                      decoration:
                          buildInputDecoration(c, 'Eğitim Tarihi'),
                      child: Row(children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 14, color: c.textMuted),
                        const SizedBox(width: 6),
                        Text(tarihStr,
                            style: GoogleFonts.inter(
                                color: c.text, fontSize: 13)),
                      ]),
                    ),
                  ),
                ),
              ]),
            ]),
            const SizedBox(height: 12),
            // Özel riskler
            FormSection(
                title: 'ÖZEL RİSKLER (opsiyonel)',
                c: c,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _ozelRiskler.map((r) {
                      final secili = _ozelRisklerSec.contains(r);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (secili) {
                            _ozelRisklerSec.remove(r);
                          } else {
                            _ozelRisklerSec.add(r);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: secili
                                ? const Color(0xFFE8B84B)
                                    .withValues(alpha: 0.15)
                                : c.bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: secili
                                  ? const Color(0xFFE8B84B)
                                  : c.border,
                            ),
                          ),
                          child: Text(r,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: secili
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: secili
                                      ? const Color(0xFFE8B84B)
                                      : c.textMuted)),
                        ),
                      );
                    }).toList(),
                  ),
                ]),
            const SizedBox(height: 12),
            // Eğitimciler
            FormSection(title: 'EĞİTİMCİLER', c: c, children: [
              TextFormField(
                controller: _egitimciIsimCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(
                    c, 'İş Güvenliği Uzmanı - Ad Soyad'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _egitimciUnvanCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration:
                    buildInputDecoration(c, 'Uzman Unvan / Belge No'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hekimIsimCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration: buildInputDecoration(
                    c, 'İşyeri Hekimi - Ad Soyad (opsiyonel)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hekimUnvanCtrl,
                style: GoogleFonts.inter(color: c.text, fontSize: 13),
                decoration:
                    buildInputDecoration(c, 'Hekim Unvan / Diploma No'),
              ),
            ]),
            const SizedBox(height: 12),
            // Katılımcılar
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
                        decoration: buildInputDecoration(
                            c, 'Görevi (opsiyonel)'),
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
                      final kat = _katilimcilar[i];
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
                                Text(
                                    '${kat['ad']} ${kat['soyad']}',
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: c.text)),
                                if ((kat['gorevi'] as String).isNotEmpty)
                                  Text(kat['gorevi'] as String,
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
