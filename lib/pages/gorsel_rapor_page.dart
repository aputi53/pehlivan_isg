import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pehlivan_isg/utils/platform_utils.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:pehlivan_isg/services/database_service.dart';

// ─────────────────────────────────────────────
// RAPOR TİPİ
// ─────────────────────────────────────────────
enum RaporTipi { hizli, detayli }

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class GorselRapor {
  final String id;
  final DateTime tarih;
  final List<String> fotoPaths;
  final String baslik;
  final String rapor;
  final String firmaAdi;

  GorselRapor({
    required this.id,
    required this.tarih,
    required this.fotoPaths,
    required this.baslik,
    required this.rapor,
    this.firmaAdi = '',
  });
}

// ─────────────────────────────────────────────
// PDF YARDIMCI FONKSİYONLARI
// ─────────────────────────────────────────────
pw.TableRow _pdfTableRow(
    pw.Font fontBold, pw.Font font, String label, String value) {
  return pw.TableRow(
    children: [
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(label, style: pw.TextStyle(font: fontBold, fontSize: 10)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Text(':', style: pw.TextStyle(font: fontBold, fontSize: 10)),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5, left: 4),
        child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 10)),
      ),
    ],
  );
}

String _pdfFileName(String firmaAdi, String id) {
  final s = firmaAdi
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .trim();
  return s.isNotEmpty ? '${s}_ISG_Raporu.pdf' : 'ISG_Raporu_$id.pdf';
}

Future<pw.Document> _buildPdfDoc(GorselRapor rapor) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );
  final userName = await storage.read(key: 'user_name') ?? '';
  final userCert = await storage.read(key: 'user_cert') ?? '';
  final userCompany = await storage.read(key: 'user_company') ?? '';
  final logoB64 = await storage.read(key: 'user_company_logo');

  final font = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final tarihStr =
      "${rapor.tarih.day.toString().padLeft(2, '0')}.${rapor.tarih.month.toString().padLeft(2, '0')}.${rapor.tarih.year}";

  final List<pw.MemoryImage> fotoImages = [];
  for (final path in rapor.fotoPaths.take(3)) {
    final file = File(path);
    if (await file.exists()) {
      fotoImages.add(pw.MemoryImage(await file.readAsBytes()));
    }
  }

  pw.MemoryImage? logoImage;
  if (logoB64 != null && logoB64.isNotEmpty) {
    try {
      logoImage = pw.MemoryImage(base64Decode(logoB64));
    } catch (_) {}
  }

  const accentColor = PdfColor(0.91, 0.72, 0.29);

  // ── Başlık alanı (logo sol üst)
  final titleWidget = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (logoImage != null) ...[
        pw.SizedBox(
          width: 50,
          height: 50,
          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
        ),
        pw.SizedBox(width: 12),
      ],
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: logoImage != null
              ? pw.CrossAxisAlignment.start
              : pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'İş Güvenliği Tespit ve Öneri Raporu',
              style: pw.TextStyle(font: fontBold, fontSize: 14),
              textAlign: logoImage != null
                  ? pw.TextAlign.left
                  : pw.TextAlign.center,
            ),
            if (userCompany.isNotEmpty) ...[
              pw.SizedBox(height: 3),
              pw.Text(
                userCompany,
                style: pw.TextStyle(
                    font: font, fontSize: 9, color: PdfColors.grey700),
                textAlign: logoImage != null
                    ? pw.TextAlign.left
                    : pw.TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ],
  );

  // ── Sol bilgi tablosu (hizalı iki nokta)
  final infoRows = <pw.TableRow>[
    if (rapor.firmaAdi.isNotEmpty)
      _pdfTableRow(fontBold, font, 'Firma Ünvanı', rapor.firmaAdi),
    _pdfTableRow(fontBold, font, 'Rapor Adı', rapor.baslik),
    _pdfTableRow(fontBold, font, 'Tarih', tarihStr),
    if (userName.isNotEmpty)
      _pdfTableRow(
        fontBold,
        font,
        'Düzenleyen',
        userCert.isNotEmpty
            ? '$userName  —  $userCert İş Güvenliği Uzmanı'
            : userName,
      ),
  ];

  final infoTable = pw.Table(
    columnWidths: const {
      0: pw.FixedColumnWidth(82),
      1: pw.FixedColumnWidth(8),
      2: pw.FlexColumnWidth(),
    },
    defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
    children: infoRows,
  );

  final headerSection = fotoImages.isNotEmpty
      ? pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(flex: 3, child: infoTable),
            pw.SizedBox(width: 12),
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                children: fotoImages
                    .map((img) => pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 4),
                          child: pw.Image(img,
                              height: 70, fit: pw.BoxFit.cover),
                        ))
                    .toList(),
              ),
            ),
          ],
        )
      : infoTable;

  final List<pw.Widget> icerik = [
    titleWidget,
    pw.SizedBox(height: 6),
    pw.Divider(thickness: 1.5, color: accentColor),
    pw.SizedBox(height: 12),
    headerSection,
    pw.SizedBox(height: 12),
    pw.Divider(thickness: 0.5),
    pw.SizedBox(height: 8),
    ...rapor.rapor.split('\n').map(
          (satir) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              satir.isEmpty ? ' ' : satir,
              style: pw.TextStyle(font: font, fontSize: 11),
            ),
          ),
        ),
  ];

  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => icerik,
    ),
  );

  return pdf;
}

Future<Uint8List?> _pdfBytesOlustur(GorselRapor rapor) async {
  try {
    final pdf = await _buildPdfDoc(rapor);
    return pdf.save();
  } catch (e) {
    debugPrint('PDF oluşturma hatası: $e');
    return null;
  }
}

// ─────────────────────────────────────────────
// LİSTE SAYFASI
// ─────────────────────────────────────────────
class GorselRaporPage extends StatefulWidget {
  final String firmaAdi;
  final int firmaId;
  final List<GorselRapor> raporlar;

  const GorselRaporPage({
    super.key,
    required this.firmaAdi,
    required this.firmaId,
    required this.raporlar,
  });

  @override
  State<GorselRaporPage> createState() => _GorselRaporPageState();
}

class _GorselRaporPageState extends State<GorselRaporPage> {
  void _showRaporIslemleri(GorselRapor rapor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _RaporIslemleriSheet(rapor: rapor),
    );
  }

  void _yeniAnalizSec() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RaporTipiSecSheet(
        onSecim: (tip) async {
          Navigator.pop(context);
          final result = await Navigator.push<GorselRapor>(
            context,
            MaterialPageRoute(
              builder: (_) => RaporOlusturPage(
                firmaAdi: widget.firmaAdi,
                raporTipi: tip,
              ),
            ),
          );
          if (result != null && mounted) {
            await DatabaseService.insertGorselRapor(
              id: result.id,
              firmaId: widget.firmaId,
              baslik: result.baslik,
              rapor: result.rapor,
              tarih: result.tarih,
              fotoPaths: result.fotoPaths,
            );
            setState(() => widget.raporlar.add(result));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.raporlar.isEmpty
          ? const _EmptyState()
          : Column(
              children: [
                _StatsBar(raporSayisi: widget.raporlar.length),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: widget.raporlar.length,
                    itemBuilder: (_, i) {
                      final r = widget.raporlar[i];
                      return _RaporKarti(
                        rapor: r,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RaporDetayPage(rapor: r),
                          ),
                        ),
                        onMenuTap: () => _showRaporIslemleri(r),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text(
          "Yeni Analiz",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _yeniAnalizSec,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RAPOR TİPİ SEÇİM SHEET
// ─────────────────────────────────────────────
class RaporTipiSecSheet extends StatelessWidget {
  final void Function(RaporTipi) onSecim;
  const RaporTipiSecSheet({required this.onSecim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Rapor Tipi Seçin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'İhtiyacınıza göre analiz derinliğini belirleyin',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
          const SizedBox(height: 20),
          _TipKarti(
            icon: Icons.bolt_rounded,
            renk: Colors.orange,
            baslik: 'Hızlı Rapor',
            aciklama: 'Uygunsuzluklar maddeler hâlinde; tespit ve öneriler',
            onTap: () => onSecim(RaporTipi.hizli),
          ),
          const SizedBox(height: 12),
          _TipKarti(
            icon: Icons.assignment_outlined,
            renk: Colors.amber,
            baslik: 'Detaylı Rapor',
            aciklama: 'Tespit, olması gereken ve mevzuat referansları',
            onTap: () => onSecim(RaporTipi.detayli),
          ),
        ],
      ),
    );
  }
}

class _TipKarti extends StatelessWidget {
  final IconData icon;
  final Color renk;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _TipKarti({
    required this.icon,
    required this.renk,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1117),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: renk.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: renk, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    aciklama,
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: renk.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RAPOR İŞLEMLERİ BOTTOM SHEET
// ─────────────────────────────────────────────
class _RaporIslemleriSheet extends StatefulWidget {
  final GorselRapor rapor;
  const _RaporIslemleriSheet({required this.rapor});

  @override
  State<_RaporIslemleriSheet> createState() => _RaporIslemleriSheetState();
}

class _RaporIslemleriSheetState extends State<_RaporIslemleriSheet> {
  bool _loading = false;
  String _loadingMsg = '';

  Future<void> _pdfIndir() async {
    setState(() {
      _loading = true;
      _loadingMsg = 'PDF kaydediliyor...';
    });
    final bytes = await _pdfBytesOlustur(widget.rapor);
    if (!mounted) return;

    if (bytes == null) {
      Navigator.pop(context);
      _showHata('PDF oluşturulamadı');
      return;
    }

    try {
      // Public Downloads dizinine yaz (/storage/emulated/0/Download/)
      // Android 10+ üzerinde de çalışır (hedef SDK kısıtlaması yoksa)
      Directory saveDir = Directory('/storage/emulated/0/Download');
      bool usedPublic = false;

      try {
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
        // Yazma iznini test et
        final test = File('${saveDir.path}/.perm_test');
        await test.writeAsBytes([0]);
        await test.delete();
        usedPublic = true;
      } catch (_) {
        // Public Downloads'a yazılamadı → uygulama harici depolama
        final extDir = await getExternalStorageDirectory();
        saveDir = extDir ?? await getApplicationDocumentsDirectory();
        if (!await saveDir.exists()) await saveDir.create(recursive: true);
      }

      final ts = DateTime.now();
      final dateTag = '${ts.day.toString().padLeft(2, "0")}${ts.month.toString().padLeft(2, "0")}${ts.year}';
      final baseName = _pdfFileName(widget.rapor.firmaAdi, widget.rapor.id)
          .replaceAll('.pdf', '');
      final fileName = '${baseName}_$dateTag.pdf';
      final file = File('${saveDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  usedPublic
                      ? 'PDF İndirilenler klasörüne kaydedildi\n$fileName'
                      : 'PDF kaydedildi (Dosya Yöneticisi → Android → data)\n$fileName',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showHata('Kayıt hatası: $e');
    }
  }

  Future<void> _emailGonder() async {
    setState(() {
      _loading = true;
      _loadingMsg = 'PDF hazırlanıyor...';
    });
    final bytes = await _pdfBytesOlustur(widget.rapor);
    if (!mounted) return;
    Navigator.pop(context);
    if (bytes != null) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName(widget.rapor.firmaAdi, widget.rapor.id),
      );
    } else {
      _showHata('PDF oluşturulamadı');
    }
  }

  Future<void> _yazdir() async {
    setState(() {
      _loading = true;
      _loadingMsg = 'Yazdırma hazırlanıyor...';
    });
    try {
      if (!mounted) return;
      Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (_) async {
          final bytes = await _pdfBytesOlustur(widget.rapor);
          return bytes ?? Uint8List(0);
        },
        name: widget.rapor.baslik,
      );
    } catch (e) {
      if (mounted) {
        _showHata('Yazdırma hatası: $e');
      }
    }
  }

  void _showHata(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[700],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          if (_loading) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _loadingMsg,
              style: const TextStyle(color: Colors.amber, fontSize: 13),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.rapor.baslik,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "${widget.rapor.tarih.day.toString().padLeft(2, '0')}.${widget.rapor.tarih.month.toString().padLeft(2, '0')}.${widget.rapor.tarih.year}",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFF2A2F3A)),
            _IslemSatiri(
              icon: Icons.picture_as_pdf_outlined,
              renk: Colors.amber,
              baslik: 'PDF İndir',
              aciklama: 'PDF oluşturulur, uygulama seçerek indirebilirsiniz',
              onTap: _pdfIndir,
            ),
            const Divider(height: 1, color: Color(0xFF2A2F3A), indent: 56),
            _IslemSatiri(
              icon: Icons.mail_outline,
              renk: Colors.blueAccent,
              baslik: 'E-posta ile Gönder',
              aciklama: 'PDF eklenmiş paylaşım ekranı açılır',
              onTap: _emailGonder,
            ),
            const Divider(height: 1, color: Color(0xFF2A2F3A), indent: 56),
            _IslemSatiri(
              icon: Icons.print_outlined,
              renk: Colors.green,
              baslik: 'Çıktı Al',
              aciklama: 'Bağlı yazıcıdan çıktı alabilirsiniz',
              onTap: _yazdir,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _IslemSatiri extends StatelessWidget {
  final IconData icon;
  final Color renk;
  final String baslik;
  final String aciklama;
  final VoidCallback onTap;

  const _IslemSatiri({
    required this.icon,
    required this.renk,
    required this.baslik,
    required this.aciklama,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: renk, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baslik,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    aciklama,
                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[700], size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Colors.amber,
              size: 38,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Henüz AI Rapor Yok",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Fotoğraf ekleyerek yapay zeka destekli\nİSG analizi başlatın",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Aşağıdaki butona dokunun →",
            style: TextStyle(
                color: Colors.amber.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// STATS BAR
// ─────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final int raporSayisi;
  const _StatsBar({required this.raporSayisi});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: Colors.amber, size: 18),
          const SizedBox(width: 10),
          Text(
            "Toplam $raporSayisi AI Rapor",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.psychology_rounded, color: Colors.amber, size: 11),
                SizedBox(width: 4),
                Text(
                  "AI Destekli",
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RAPOR KARTI
// ─────────────────────────────────────────────
class _RaporKarti extends StatelessWidget {
  final GorselRapor rapor;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const _RaporKarti({
    required this.rapor,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onMenuTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: rapor.fotoPaths.isNotEmpty
                  ? Image.file(
                      File(rapor.fotoPaths.first),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 88,
                      height: 88,
                      color: Colors.amber.withValues(alpha: 0.08),
                      child: const Icon(Icons.image_outlined,
                          color: Colors.amber, size: 32),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rapor.baslik,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            color: Colors.grey[600], size: 10),
                        const SizedBox(width: 3),
                        Text(
                          "${rapor.tarih.day.toString().padLeft(2, '0')}.${rapor.tarih.month.toString().padLeft(2, '0')}.${rapor.tarih.year}",
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                        if (rapor.fotoPaths.length > 1) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.photo_library_outlined,
                              color: Colors.grey[600], size: 10),
                          const SizedBox(width: 3),
                          Text(
                            "${rapor.fotoPaths.length} fotoğraf",
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.25)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology_outlined,
                              color: Colors.amber, size: 10),
                          SizedBox(width: 3),
                          Text(
                            "AI İSG Analiz",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            GestureDetector(
              onTap: onMenuTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                child: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RAPOR OLUŞTUR SAYFASI
// ─────────────────────────────────────────────
class RaporOlusturPage extends StatefulWidget {
  final String firmaAdi;
  final RaporTipi raporTipi;

  const RaporOlusturPage({
    super.key,
    required this.firmaAdi,
    required this.raporTipi,
  });

  @override
  State<RaporOlusturPage> createState() => _RaporOlusturPageState();
}

class _RaporOlusturPageState extends State<RaporOlusturPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<String> _photos = [];
  final TextEditingController _baslik = TextEditingController();
  final TextEditingController _rapor = TextEditingController();
  bool _loading = false;
  String _loadingText = 'Analiz ediliyor...';

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _rapor.addListener(() => setState(() {}));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _baslik.dispose();
    _rapor.dispose();
    super.dispose();
  }

  Future<void> _kamera() async {
    final img =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (img != null) setState(() => _photos.add(img.path));
  }

  Future<void> _galeri() async {
    final imgs = await _picker.pickMultiImage(imageQuality: 85);
    if (imgs.isNotEmpty) {
      setState(() => _photos.addAll(imgs.map((e) => e.path)));
    }
  }

  String get _prompt {
    if (widget.raporTipi == RaporTipi.hizli) {
      return '''
Sen kıdemli bir A sınıfı İş Güvenliği Uzmanısın. Görseldeki çalışma ortamını incele.

Tespit ettiğin uygunsuzlukları önem sırasına göre listele. Her uygunsuzluk için:

• [Uygunsuzluk Başlığı]
  Tespit: [ne gözlemlendiği]
  Olması Gereken: [nasıl olması gerektiği]

Yalnızca Türkçe yaz. Kısa ve net yaz. Risk seviyesi, puan veya genel değerlendirme bölümü ekleme. Uygunsuzluk yoksa bunu açıkça belirt.
''';
    } else {
      return '''
Sen kıdemli bir A sınıfı İş Güvenliği Uzmanısın ve sahada resmi denetim yapıyorsun. Görseldeki çalışma ortamını profesyonel bir İSG uzmanı gözüyle titizlikle analiz et.

Tespit ettiğin uygunsuzlukları önem sırasına göre numaralandırarak raporla. Her uygunsuzluk için şu formatı kullan:

[Numara]. [Uygunsuzluk Başlığı]
Tespit: [ne gözlemlendiği, somut ve teknik olarak]
Olması Gereken: [mevzuata ve iyi uygulamalara göre nasıl olması gerektiği]
Mevzuat: [ilgili kanun, yönetmelik veya standart; örn: 6331 sayılı İSG Kanunu, İş Ekipmanlarının Kullanımında Sağlık ve Güvenlik Şartları Yönetmeliği, vb.]

Yalnızca Türkçe yaz. Resmi ve profesyonel bir üslup kullan; yapay zeka dili değil, deneyimli bir uzman gibi yaz. Risk seviyesi bölümü, genel değerlendirme puanı veya özet ekleme. Uygunsuzluk yoksa bunu açıkça belirt.
''';
    }
  }

  Future<void> _analizEt() async {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    if (apiKey.isEmpty) {
      _showSnack('API anahtarı bulunamadı (.env dosyasını kontrol edin)');
      return;
    }

    if (_photos.isEmpty) {
      _showSnack('Lütfen en az bir fotoğraf ekleyin');
      return;
    }

    setState(() {
      _loading = true;
      _loadingText = 'Fotoğraflar yükleniyor...';
    });

    try {
      final model =
          GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      final images = <DataPart>[];
      for (final p in _photos) {
        images.add(DataPart('image/jpeg', await File(p).readAsBytes()));
      }

      setState(() => _loadingText = 'Yapay zeka analiz yapıyor...');

      final response = await model.generateContent([
        Content.multi([TextPart(_prompt), ...images])
      ]);

      final raporMetni = response.text ?? '';

      setState(() {
        _rapor.text = raporMetni;
        if (_baslik.text.isEmpty) {
          _baslik.text = widget.raporTipi == RaporTipi.hizli
              ? 'Hızlı İSG Analiz Raporu'
              : 'Detaylı İSG Denetim Raporu';
        }
      });
    } catch (e) {
      debugPrint('AI ERROR => $e');
      if (mounted) {
        _showSnack('Analiz hatası: ${e.toString().split(':').first}');
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1F2937),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _kaydet() {
    if (_rapor.text.trim().isEmpty) {
      _showSnack('Rapor içeriği boş olamaz');
      return;
    }
    Navigator.pop(
      context,
      GorselRapor(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tarih: DateTime.now(),
        fotoPaths: List.from(_photos),
        baslik: _baslik.text.trim().isEmpty
            ? (widget.raporTipi == RaporTipi.hizli
                ? 'Hızlı İSG Analiz Raporu'
                : 'Detaylı İSG Denetim Raporu')
            : _baslik.text.trim(),
        rapor: _rapor.text,
        firmaAdi: widget.firmaAdi,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hazir = _photos.isNotEmpty && !_loading;
    final bool analizTamam = _rapor.text.trim().isNotEmpty;
    final isHizli = widget.raporTipi == RaporTipi.hizli;
    final tipRenk = isHizli ? Colors.orange : Colors.amber;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni AI Rapor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(
                  isHizli ? Icons.bolt_rounded : Icons.assignment_outlined,
                  color: tipRenk,
                  size: 11,
                ),
                const SizedBox(width: 3),
                Text(
                  isHizli ? 'Hızlı Rapor' : 'Detaylı Rapor',
                  style: TextStyle(fontSize: 11, color: tipRenk),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _baslik,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      labelText: 'Rapor Başlığı',
                      labelStyle:
                          TextStyle(color: Colors.grey[500], fontSize: 13),
                      prefixIcon: const Icon(Icons.title,
                          color: Colors.amber, size: 18),
                      filled: true,
                      fillColor: const Color(0xFF161B22),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _BolumBasligi(
                      icon: Icons.photo_camera_outlined,
                      baslik: 'FOTOĞRAFLAR'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      if (hasCameraSupport) ...[
                        _FotoButon(
                            icon: Icons.camera_alt_outlined,
                            label: 'Kamera',
                            onTap: _kamera),
                        const SizedBox(width: 8),
                      ],
                      _FotoButon(
                          icon: Icons.photo_library_outlined,
                          label: 'Galeri',
                          onTap: _galeri),
                      if (_photos.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${_photos.length} fotoğraf',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        itemBuilder: (_, i) => Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(File(_photos[i])),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 12,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  if (_loading)
                    _LoadingKart(text: _loadingText)
                  else
                    ScaleTransition(
                      scale: hazir
                          ? _pulseAnim
                          : const AlwaysStoppedAnimation(1.0),
                      child: GestureDetector(
                        onTap: hazir ? _analizEt : null,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            gradient: hazir
                                ? LinearGradient(
                                    colors: [
                                      tipRenk,
                                      tipRenk.withValues(alpha: 0.75),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: hazir ? null : const Color(0xFF161B22),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hazir
                                  ? Colors.transparent
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            boxShadow: hazir
                                ? [
                                    BoxShadow(
                                      color:
                                          tipRenk.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_rounded,
                                color: hazir ? Colors.black : Colors.grey[600],
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                hazir
                                    ? 'AI İSG Analizi Başlat'
                                    : 'Fotoğraf ekleyerek analizi başlatın',
                                style: TextStyle(
                                  color: hazir
                                      ? Colors.black
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (analizTamam && !_loading) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 15),
                        const SizedBox(width: 6),
                        const Text(
                          'ANALİZ TAMAMLANDI',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _analizEt,
                          child: Text(
                            'Yeniden Analiz Et',
                            style: TextStyle(
                              color: Colors.amber.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.25)),
                      ),
                      child: TextField(
                        controller: _rapor,
                        maxLines: null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.65,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Analiz sonucu...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ] else if (!_loading) ...[
                    const SizedBox(height: 20),
                    _BolumBasligi(
                        icon: Icons.edit_note_outlined,
                        baslik: 'VEYA MANUEL RAPOR GİR'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 140),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: TextField(
                        controller: _rapor,
                        maxLines: null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Manuel rapor metni girebilirsiniz...',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          contentPadding: const EdgeInsets.all(14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.06))),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: analizTamam && !_loading ? _kaydet : null,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text(
                  'Raporu Kaydet',
                  style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: const Color(0xFF161B22),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  final IconData icon;
  final String baslik;

  const _BolumBasligi({required this.icon, required this.baslik});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 13),
        const SizedBox(width: 6),
        Text(
          baslik,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _FotoButon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FotoButon(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LoadingKart extends StatelessWidget {
  final String text;
  const _LoadingKart({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.amber,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bu işlem birkaç saniye sürebilir',
            style: TextStyle(color: Colors.grey[600], fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DETAY SAYFASI
// ─────────────────────────────────────────────
class RaporDetayPage extends StatefulWidget {
  final GorselRapor rapor;

  const RaporDetayPage({super.key, required this.rapor});

  @override
  State<RaporDetayPage> createState() => _RaporDetayPageState();
}

class _RaporDetayPageState extends State<RaporDetayPage> {
  bool _pdfYukleniyor = false;

  Future<void> _pdfPaylas() async {
    setState(() => _pdfYukleniyor = true);
    final bytes = await _pdfBytesOlustur(widget.rapor);
    if (!mounted) return;
    setState(() => _pdfYukleniyor = false);
    if (bytes != null) {
      await Printing.sharePdf(
        bytes: bytes,
        filename: _pdfFileName(widget.rapor.firmaAdi, widget.rapor.id),
      );
    } else {
      _showSnack('PDF oluşturulamadı');
    }
  }

  Future<void> _yazdir() async {
    setState(() => _pdfYukleniyor = true);
    try {
      if (!mounted) return;
      setState(() => _pdfYukleniyor = false);
      await Printing.layoutPdf(
        onLayout: (_) async {
          final bytes = await _pdfBytesOlustur(widget.rapor);
          return bytes ?? Uint8List(0);
        },
        name: widget.rapor.baslik,
      );
    } catch (e) {
      if (mounted) {
        setState(() => _pdfYukleniyor = false);
        _showSnack('Yazdırma hatası: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.rapor.baslik,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "${widget.rapor.tarih.day.toString().padLeft(2, '0')}.${widget.rapor.tarih.month.toString().padLeft(2, '0')}.${widget.rapor.tarih.year}",
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
        actions: [
          if (_pdfYukleniyor)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.amber),
              ),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.print_outlined, color: Colors.amber),
              tooltip: 'Yazdır',
              onPressed: _yazdir,
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  color: Colors.amber),
              tooltip: 'PDF Paylaş',
              onPressed: _pdfPaylas,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.rapor.fotoPaths.isNotEmpty) ...[
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.rapor.fotoPaths.length,
                  itemBuilder: (_, i) {
                    return GestureDetector(
                      onTap: () =>
                          _fotoBuyut(context, widget.rapor.fotoPaths[i]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: widget.rapor.fotoPaths.length == 1
                            ? MediaQuery.of(context).size.width - 32
                            : 270,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          image: DecorationImage(
                            image: FileImage(
                                File(widget.rapor.fotoPaths[i])),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black38,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_out_map,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_rounded,
                      color: Colors.amber, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Yapay Zeka İSG Analiz Raporu',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: SelectableText(
                widget.rapor.rapor,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pdfYukleniyor ? null : _yazdir,
                    icon: const Icon(Icons.print_outlined, size: 17),
                    label: const Text('Yazdır',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF161B22),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _pdfYukleniyor ? null : _pdfPaylas,
                    icon: _pdfYukleniyor
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined,
                            size: 17),
                    label: Text(
                        _pdfYukleniyor
                            ? 'Hazırlanıyor...'
                            : 'PDF Oluştur & Paylaş',
                        style:
                            const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                          Colors.amber.withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.black54,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _fotoBuyut(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }
}
