import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────
class GorselRapor {
  final String id;
  final DateTime olusturmaTarihi;
  final List<String> fotoPaths;
  String raporMetni;
  String baslik;

  GorselRapor({
    required this.id,
    required this.olusturmaTarihi,
    required this.fotoPaths,
    required this.raporMetni,
    required this.baslik,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// RAPOR LİSTESİ SAYFASI
// ─────────────────────────────────────────────────────────────────────────────
class GorselRaporPage extends StatefulWidget {
  final String firmaAdi;
  final List<GorselRapor> raporlar;

  const GorselRaporPage({
    super.key,
    required this.firmaAdi,
    required this.raporlar,
  });

  @override
  State<GorselRaporPage> createState() => _GorselRaporPageState();
}

class _GorselRaporPageState extends State<GorselRaporPage> {
  void _yeniRaporOlustur() async {
    final yeniRapor = await Navigator.push<GorselRapor>(
      context,
      MaterialPageRoute(
        builder: (_) => RaporOlusturPage(firmaAdi: widget.firmaAdi),
      ),
    );
    if (yeniRapor != null) {
      setState(() => widget.raporlar.add(yeniRapor));
    }
  }

  void _raporAc(GorselRapor rapor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RaporDetayPage(
          rapor: rapor,
          firmaAdi: widget.firmaAdi,
          onGuncelle: () => setState(() {}),
        ),
      ),
    );
  }

  String _formatTarih(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}  ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GÖRSEL RAPORLAR',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                    color: Color(0xFFE8B84B))),
            Text(widget.firmaAdi,
                style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _yeniRaporOlustur,
        backgroundColor: const Color(0xFFE8B84B),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Yeni Rapor', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: widget.raporlar.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.document_scanner_outlined, color: Colors.white12, size: 64),
            const SizedBox(height: 16),
            const Text('Henüz rapor yok',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 8),
            const Text('Yeni Rapor butonuna basarak başlayın',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: widget.raporlar.length,
        itemBuilder: (_, i) {
          final r = widget.raporlar[i];
          return GestureDetector(
            onTap: () => _raporAc(r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10151F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  if (r.fotoPaths.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(r.fotoPaths.first),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B84B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: Color(0xFFE8B84B), size: 28),
                    ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.baslik,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(_formatTarih(r.olusturmaTarihi),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('${r.fotoPaths.length} fotoğraf',
                            style: TextStyle(
                                color: const Color(0xFFE8B84B).withOpacity(0.7),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

  // ─────────────────────────────────────────────────────────────────────────────
  // RAPOR OLUŞTUR SAYFASI
  // ─────────────────────────────────────────────────────────────────────────────
  class RaporOlusturPage extends StatefulWidget {
    final String firmaAdi;

    const RaporOlusturPage({super.key, required this.firmaAdi});

    @override
    State<RaporOlusturPage> createState() => _RaporOlusturPageState();
  }

  class _RaporOlusturPageState extends State<RaporOlusturPage> {
    final ImagePicker _picker = ImagePicker();
    final List<String> _fotoPaths = [];
    bool _yukleniyor = false;
    String? _analizSonucu;
    final TextEditingController _raporCtrl = TextEditingController();
    final TextEditingController _baslikCtrl = TextEditingController();

    @override
    void dispose() {
      _raporCtrl.dispose();
      _baslikCtrl.dispose();
      super.dispose();
    }

    Future<void> _fotoEkle(ImageSource source) async {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      if (picked.isNotEmpty) {
        setState(() {
          for (var p in picked) {
            if (!_fotoPaths.contains(p.path)) _fotoPaths.add(p.path);
          }
        });
      }
    }

  Future<void> _kameraAc() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked != null && !_fotoPaths.contains(picked.path)) {
      setState(() => _fotoPaths.add(picked.path));
    }
  }

  void _fotoEkleSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2333),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFE8B84B)),
              title: const Text('Kamera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _kameraAc();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE8B84B)),
              title: const Text('Galeriden Seç', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _fotoEkle(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

    Future<void> _analizEt() async {
      if (_fotoPaths.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen en az bir fotoğraf ekleyin')),
        );
        return;
      }

      setState(() => _yukleniyor = true);

      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

        if (apiKey.isEmpty) {
          throw Exception("API KEY bulunamadı");
        }

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
        );

        const promptText = '''
Sen bir İş Sağlığı ve Güvenliği (İSG) uzmanısın.

Fotoğrafları analiz et ve profesyonel rapor oluştur.

Format:
## GENEL DEĞERLENDİRME
## UYGUNSUZLUKLAR
## OLUMLU DURUMLAR
## ÖNERİLER
## SONUÇ

Türkçe, net ve profesyonel yaz.
''';

        final List<Map<String, dynamic>> parts = [];

        parts.add({
          "text": promptText,
        });

        for (final path in _fotoPaths) {
          final bytes = await File(path).readAsBytes();
          final base64Image = base64Encode(bytes);

          parts.add({
            "inlineData": {
              "mimeType": "image/jpeg",
              "data": base64Image
            }
          });
        }

        final requestBody = {
          "contents": [
            {
              "role": "user",
              "parts": parts
            }
          ]
        };

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode != 200) {
          throw Exception("API HATASI: ${response.body}");
        }

        final data = jsonDecode(response.body);

        final candidates = data["candidates"];

        if (candidates == null || candidates.isEmpty) {
          throw Exception("Boş cevap geldi");
        }

        final content = candidates[0]["content"];
        final respParts = content["parts"];

        if (respParts == null || respParts.isEmpty) {
          throw Exception("İçerik boş geldi");
        }

        final result = respParts[0]["text"] ?? "Sonuç üretilemedi";

        setState(() {
          _analizSonucu = result;
          _raporCtrl.text = result;

          if (_baslikCtrl.text.isEmpty) {
            _baslikCtrl.text =
            'İSG Raporu - ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}';
          }

          _yukleniyor = false;
        });
      } catch (e) {
        setState(() => _yukleniyor = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  void _kaydet() {
    if (_raporCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor içeriği boş olamaz')),
      );
      return;
    }

    final rapor = GorselRapor(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      olusturmaTarihi: DateTime.now(),
      fotoPaths: List.from(_fotoPaths),
      raporMetni: _raporCtrl.text,
      baslik: _baslikCtrl.text.isEmpty
          ? 'İSG Raporu - ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}'
          : _baslikCtrl.text,
    );

    Navigator.pop(context, rapor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('YENİ RAPOR',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Color(0xFFE8B84B))),
        actions: [
          if (_analizSonucu != null)
            TextButton(
              onPressed: _kaydet,
              child: const Text('KAYDET',
                  style: TextStyle(
                      color: Color(0xFFE8B84B), fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIK
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10151F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: TextField(
                controller: _baslikCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Rapor başlığı...',
                  hintStyle: TextStyle(color: Colors.white38),
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.title, color: Color(0xFFE8B84B), size: 20),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // FOTOĞRAFLAR
            const Text('FOTOĞRAFLAR',
                style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2)),
            const SizedBox(height: 10),

            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _fotoEkleSheet,
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10151F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE8B84B).withOpacity(0.3),
                            style: BorderStyle.solid),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined,
                              color: Color(0xFFE8B84B), size: 28),
                          SizedBox(height: 4),
                          Text('Ekle',
                              style: TextStyle(
                                  color: Color(0xFFE8B84B), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  ..._fotoPaths.map((path) => Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(File(path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 14,
                        child: GestureDetector(
                          onTap: () => setState(() => _fotoPaths.remove(path)),
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
                  )),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ANALİZ BUTONU
            if (_analizSonucu == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _yukleniyor ? null : _analizEt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: _yukleniyor
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black),
                  )
                      : const Icon(Icons.auto_awesome, size: 20),
                  label: Text(
                    _yukleniyor ? 'Yapay Zeka Analiz Ediyor...' : 'Yapay Zeka ile Analiz Et',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),

            // RAPOR METNİ
            if (_analizSonucu != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('RAPOR İÇERİĞİ',
                      style: TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _analizEt,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8B84B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE8B84B).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh, color: Color(0xFFE8B84B), size: 14),
                          SizedBox(width: 4),
                          Text('Yeniden Analiz',
                              style: TextStyle(
                                  color: Color(0xFFE8B84B), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF10151F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: TextField(
                  controller: _raporCtrl,
                  maxLines: null,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.6),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(16),
                    border: InputBorder.none,
                    hintText: 'Rapor içeriğini düzenleyebilirsiniz...',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _kaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.save_outlined, size: 20),
                  label: const Text('Raporu Kaydet',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RAPOR DETAY SAYFASI
// ─────────────────────────────────────────────────────────────────────────────
class RaporDetayPage extends StatefulWidget {
  final GorselRapor rapor;
  final String firmaAdi;
  final VoidCallback onGuncelle;

  const RaporDetayPage({
    super.key,
    required this.rapor,
    required this.firmaAdi,
    required this.onGuncelle,
  });

  @override
  State<RaporDetayPage> createState() => _RaporDetayPageState();
}

class _RaporDetayPageState extends State<RaporDetayPage> {
  late TextEditingController _raporCtrl;
  bool _duzenleMode = false;
  bool _pdfYukleniyor = false;

  @override
  void initState() {
    super.initState();
    _raporCtrl = TextEditingController(text: widget.rapor.raporMetni);
  }

  @override
  void dispose() {
    _raporCtrl.dispose();
    super.dispose();
  }

  Future<void> _pdfOlusturVePaylas() async {
    setState(() => _pdfYukleniyor = true);

    try {
      final pdf = pw.Document();
      final tarih =
          '${widget.rapor.olusturmaTarihi.day.toString().padLeft(2, '0')}.${widget.rapor.olusturmaTarihi.month.toString().padLeft(2, '0')}.${widget.rapor.olusturmaTarihi.year}';

      // Fotoğrafları yükle
      final List<pw.Widget> fotoWidgets = [];
      for (final path in widget.rapor.fotoPaths) {
        final bytes = await File(path).readAsBytes();
        final image = pw.MemoryImage(bytes);
        fotoWidgets.add(
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Image(image, height: 200, fit: pw.BoxFit.cover),
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            // BAŞLIK
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey900,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('PEHLİVAN İSG',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.amber)),
                  pw.Text('İSG DENETİM RAPORU',
                      style: pw.TextStyle(
                          fontSize: 13, color: PdfColors.grey400)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // BİLGİLER
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Firma: ${widget.firmaAdi}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Tarih: $tarih'),
                  ],
                ),
                pw.Text(widget.rapor.baslik,
                    style: pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey600)),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),

            // FOTOĞRAFLAR
            if (fotoWidgets.isNotEmpty) ...[
              pw.Text('FOTOĞRAFLAR',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.SizedBox(height: 8),
              ...fotoWidgets,
              pw.SizedBox(height: 16),
            ],

            // RAPOR
            pw.Text('RAPOR İÇERİĞİ',
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
            pw.SizedBox(height: 8),
            pw.Text(widget.rapor.raporMetni,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 4)),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/isg_raporu_${widget.rapor.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      setState(() => _pdfYukleniyor = false);

      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1C2333),
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.print_outlined, color: Color(0xFFE8B84B)),
                  title: const Text('Yazdır / PDF Görüntüle',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Printing.layoutPdf(
                        onLayout: (_) async => await pdf.save());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Color(0xFFE8B84B)),
                  title: const Text('Paylaş / Mail Gönder',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await Share.shareXFiles(
                      [XFile(file.path)],
                      subject: '${widget.firmaAdi} - İSG Denetim Raporu',
                      text: widget.rapor.baslik,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _pdfYukleniyor = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF hatası: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarih =
        '${widget.rapor.olusturmaTarihi.day.toString().padLeft(2, '0')}.${widget.rapor.olusturmaTarihi.month.toString().padLeft(2, '0')}.${widget.rapor.olusturmaTarihi.year}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('RAPOR DETAYI',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: Color(0xFFE8B84B))),
        actions: [
          IconButton(
            icon: Icon(
              _duzenleMode ? Icons.save_outlined : Icons.edit_outlined,
              color: const Color(0xFFE8B84B),
            ),
            onPressed: () {
              if (_duzenleMode) {
                widget.rapor.raporMetni = _raporCtrl.text;
                widget.onGuncelle();
              }
              setState(() => _duzenleMode = !_duzenleMode);
            },
          ),
          IconButton(
            icon: _pdfYukleniyor
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFE8B84B)),
            )
                : const Icon(Icons.ios_share_outlined, color: Color(0xFFE8B84B)),
            onPressed: _pdfYukleniyor ? null : _pdfOlusturVePaylas,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BİLGİ KARTI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10151F),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.rapor.baslik,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Color(0xFFE8B84B), size: 13),
                      const SizedBox(width: 6),
                      Text(tarih,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(width: 16),
                      const Icon(Icons.photo_outlined,
                          color: Color(0xFFE8B84B), size: 13),
                      const SizedBox(width: 6),
                      Text('${widget.rapor.fotoPaths.length} fotoğraf',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // FOTOĞRAFLAR
            if (widget.rapor.fotoPaths.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('FOTOĞRAFLAR',
                  style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 10),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.rapor.fotoPaths.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(backgroundColor: Colors.black),
                          body: Center(
                            child: InteractiveViewer(
                              child: Image.file(
                                  File(widget.rapor.fotoPaths[i])),
                            ),
                          ),
                        ),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: FileImage(File(widget.rapor.fotoPaths[i])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // RAPOR METNİ
            Row(
              children: [
                const Text('RAPOR İÇERİĞİ',
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2)),
                if (_duzenleMode) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8B84B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Düzenleniyor',
                        style: TextStyle(
                            color: Color(0xFFE8B84B), fontSize: 10)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10151F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _duzenleMode
                      ? const Color(0xFFE8B84B).withOpacity(0.3)
                      : Colors.white.withOpacity(0.06),
                ),
              ),
              child: TextField(
                controller: _raporCtrl,
                maxLines: null,
                readOnly: !_duzenleMode,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.7),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // PDF / PAYLAŞ BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _pdfYukleniyor ? null : _pdfOlusturVePaylas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8B84B),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _pdfYukleniyor
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black),
                )
                    : const Icon(Icons.picture_as_pdf_outlined, size: 20),
                label: const Text('PDF Oluştur / Paylaş',
                    style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}