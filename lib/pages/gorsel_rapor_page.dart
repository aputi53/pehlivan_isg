import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:path_provider/path_provider.dart';

import 'package:pehlivan_isg/services/database_service.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────
class GorselRapor {
  final String id;
  final DateTime tarih;
  final List<String> fotoPaths;
  final String baslik;
  final String rapor;

  GorselRapor({
    required this.id,
    required this.tarih,
    required this.fotoPaths,
    required this.baslik,
    required this.rapor,
  });
}

// ─────────────────────────────────────────────
// PDF YARDIMCI FONKSİYONLARI
// ─────────────────────────────────────────────
Future<pw.Document> _buildPdfDoc(GorselRapor rapor) async {
  final pdf = pw.Document();

  final List<pw.Widget> icerik = [
    pw.Text(
      rapor.baslik,
      style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 6),
    pw.Text(
      "Tarih: ${rapor.tarih.day.toString().padLeft(2, '0')}.${rapor.tarih.month.toString().padLeft(2, '0')}.${rapor.tarih.year}",
      style: const pw.TextStyle(fontSize: 11),
    ),
    pw.SizedBox(height: 2),
    pw.Text(
      "İş Sağlığı ve Güvenliği Görsel Denetim Raporu",
      style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
    ),
    pw.Divider(),
    pw.SizedBox(height: 8),
    pw.Text(rapor.rapor, style: const pw.TextStyle(fontSize: 11)),
  ];

  for (final path in rapor.fotoPaths) {
    final file = File(path);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      icerik.add(pw.SizedBox(height: 12));
      icerik.add(pw.Image(pw.MemoryImage(bytes), height: 180));
    }
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (_) => icerik,
    ),
  );

  return pdf;
}

Future<File?> _pdfDosyasiOlustur(GorselRapor rapor) async {
  try {
    final pdf = await _buildPdfDoc(rapor);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/isg_rapor_${rapor.id}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
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
        onPressed: () async {
          final result = await Navigator.push<GorselRapor>(
            context,
            MaterialPageRoute(builder: (_) => const RaporOlusturPage()),
          );

          if (result != null) {
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

  Future<void> _pdfPaylas() async {
    setState(() {
      _loading = true;
      _loadingMsg = 'PDF oluşturuluyor...';
    });
    final file = await _pdfDosyasiOlustur(widget.rapor);
    if (!mounted) return;
    Navigator.pop(context);
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.rapor.baslik,
      );
    } else {
      _showHata('PDF oluşturulamadı');
    }
  }

  Future<void> _emailGonder() async {
    setState(() {
      _loading = true;
      _loadingMsg = 'PDF hazırlanıyor...';
    });
    final file = await _pdfDosyasiOlustur(widget.rapor);
    if (!mounted) return;
    Navigator.pop(context);
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: widget.rapor.baslik,
        text: 'İSG Görsel Denetim Raporu: ${widget.rapor.baslik}',
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
      final pdf = await _buildPdfDoc(widget.rapor);
      final bytes = await pdf.save();
      if (!mounted) return;
      Navigator.pop(context);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: widget.rapor.baslik,
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
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
              baslik: 'PDF Oluştur & Paylaş',
              aciklama: 'PDF dosyası oluşturulur, uygulama seçebilirsiniz',
              onTap: _pdfPaylas,
            ),
            const Divider(height: 1, color: Color(0xFF2A2F3A), indent: 56),
            _IslemSatiri(
              icon: Icons.mail_outline,
              renk: Colors.blueAccent,
              baslik: 'E-posta ile Gönder',
              aciklama: 'PDF eklenmiş e-posta uygulaması açılır',
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
            "Henüz Görsel Rapor Yok",
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
            style: TextStyle(color: Colors.amber.withValues(alpha: 0.6), fontSize: 12),
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
            "Toplam $raporSayisi Görsel Rapor",
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

            // İşlem menüsü butonu
            GestureDetector(
              onTap: onMenuTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
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
  const RaporOlusturPage({super.key});

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

      const prompt = '''
Sen kıdemli bir İş Sağlığı ve Güvenliği (İSG) Uzmanısın. Görselleri titizlikle analiz ederek aşağıdaki formatta kapsamlı ve profesyonel bir saha denetim raporu hazırla:

**GENEL DEĞERLENDİRME**
Fotoğraflarda görünen çalışma ortamını ve genel durumu kısaca açıkla.

**TESPİT EDİLEN UYGUNSUZLUKLAR VE TEHLİKELER**
Her tehlikeyi ayrı olarak numaralandır ve şu bilgileri ver:
• Tehlike/Uygunsuzluk Adı
• Açıklama ve gözlem
• Risk Seviyesi: Düşük / Orta / Yüksek / Kritik
• İlgili Mevzuat veya Standart (varsa, örn: İş Sağlığı ve Güvenliği Kanunu 6331, OHSAS 18001)

**RİSK DERECELENDİRMESİ**
Tespit edilen tehlikeleri risk seviyelerine göre sırala.

**ACİL ALINMASI GEREKEN ÖNLEMLER**
Kritik ve yüksek riskler için derhal uygulanması gereken düzeltici faaliyetleri listele.

**UZUN VADELİ İYİLEŞTİRME ÖNERİLERİ**
Sistemsel ve kalıcı iyileştirmeler için öneriler sun.

**SONUÇ VE GENEL RİSK PUANI**
Genel risk durumunu değerlendir ve özet bir sonuç yaz.

Raporu yalnızca Türkçe yaz. Teknik, resmi ve profesyonel bir dil kullan. Eğer fotoğraflarda herhangi bir uygunsuzluk tespit edilemiyorsa bunu da açıkça belirt.
''';

      setState(() => _loadingText = 'Rapor hazırlanıyor...');

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), ...images])
      ]);

      final raporMetni = response.text ?? '';

      setState(() {
        _rapor.text = raporMetni;
        if (_baslik.text.isEmpty) {
          _baslik.text = 'İSG Görsel Denetim Raporu';
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
            ? 'İSG Görsel Raporu'
            : _baslik.text.trim(),
        rapor: _rapor.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hazir = _photos.isNotEmpty && !_loading;
    final bool analizTamam = _rapor.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yeni Görsel Rapor',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'İSG Yapay Zeka Analizi',
              style: TextStyle(fontSize: 11, color: Colors.amber),
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
                      _FotoButon(
                          icon: Icons.camera_alt_outlined,
                          label: 'Kamera',
                          onTap: _kamera),
                      const SizedBox(width: 8),
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
                                      Colors.amber,
                                      Colors.amber.shade700
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
                                          Colors.amber.withValues(alpha: 0.35),
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
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
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
    final file = await _pdfDosyasiOlustur(widget.rapor);
    if (!mounted) return;
    setState(() => _pdfYukleniyor = false);
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: widget.rapor.baslik,
      );
    } else {
      _showSnack('PDF oluşturulamadı');
    }
  }

  Future<void> _yazdir() async {
    setState(() => _pdfYukleniyor = true);
    try {
      final pdf = await _buildPdfDoc(widget.rapor);
      final bytes = await pdf.save();
      if (!mounted) return;
      setState(() => _pdfYukleniyor = false);
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
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
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
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
                        style: const TextStyle(fontWeight: FontWeight.w700)),
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
