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

/// ─────────────────────────────────────────────
/// MODEL
/// ─────────────────────────────────────────────
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

/// ─────────────────────────────────────────────
/// LİSTE
/// ─────────────────────────────────────────────
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: widget.raporlar.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined,
                      color: Colors.grey[700], size: 48),
                  const SizedBox(height: 12),
                  Text("Henüz görsel rapor yok",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
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
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push<GorselRapor>(
            context,
            MaterialPageRoute(
              builder: (_) => const RaporOlusturPage(),
            ),
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

class _RaporKarti extends StatelessWidget {
  final GorselRapor rapor;
  final VoidCallback onTap;

  const _RaporKarti({required this.rapor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            if (rapor.fotoPaths.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(rapor.fotoPaths.first),
                    width: 56, height: 56, fit: BoxFit.cover),
              )
            else
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_outlined,
                    color: Colors.amber, size: 28),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rapor.baslik,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    "${rapor.tarih.day.toString().padLeft(2, '0')}.${rapor.tarih.month.toString().padLeft(2, '0')}.${rapor.tarih.year}",
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// RAPOR OLUŞTUR
/// ─────────────────────────────────────────────
class RaporOlusturPage extends StatefulWidget {
  const RaporOlusturPage({super.key});

  @override
  State<RaporOlusturPage> createState() => _RaporOlusturPageState();
}

class _RaporOlusturPageState extends State<RaporOlusturPage> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _photos = [];
  final TextEditingController _baslik = TextEditingController();
  final TextEditingController _rapor = TextEditingController();
  bool _loading = false;

  Future<void> _kamera() async {
    final img = await _picker.pickImage(source: ImageSource.camera);
    if (img != null) setState(() => _photos.add(img.path));
  }

  Future<void> _galeri() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) {
      setState(() => _photos.addAll(imgs.map((e) => e.path)));
    }
  }

  Future<void> _analizEt() async {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("API KEY yok")));
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Fotoğraf ekle")));
      return;
    }

    setState(() => _loading = true);

    try {
      final model = GenerativeModel(model: "gemini-1.5-flash", apiKey: apiKey);

      final images = <DataPart>[];
      for (final p in _photos) {
        images.add(DataPart("image/jpeg", await File(p).readAsBytes()));
      }

      const prompt = """
Sen kıdemli bir İş Sağlığı ve Güvenliği uzmanısın.
Fotoğrafları analiz et:
- Riskler
- Tehlikeler
- Önlemler
Profesyonel rapor yaz.
""";

      final response = await model.generateContent([
        Content.multi([TextPart(prompt), ...images])
      ]);

      setState(() => _rapor.text = response.text ?? "");
    } catch (e) {
      debugPrint("AI ERROR => $e");
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("AI HATA: $e")));
      }
    }

    setState(() => _loading = false);
  }

  void _kaydet() {
    if (_rapor.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      GorselRapor(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tarih: DateTime.now(),
        fotoPaths: List.from(_photos),
        baslik: _baslik.text.isEmpty ? "İSG Raporu" : _baslik.text,
        rapor: _rapor.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Yeni Görsel Rapor"),
        backgroundColor: const Color(0xFF0D1117),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _baslik,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Başlık",
                labelStyle: TextStyle(color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFF161B22),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _aksiyon(Icons.camera_alt_outlined, "Kamera", _kamera),
                const SizedBox(width: 8),
                _aksiyon(Icons.photo_library_outlined, "Galeri", _galeri),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _analizEt,
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Icon(Icons.psychology_outlined, size: 16),
                    label: Text(_loading ? "Analiz..." : "AI Analiz"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            if (_photos.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _photos.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(p), width: 80, fit: BoxFit.cover),
                    ),
                  )).toList(),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _rapor,
                maxLines: null,
                expands: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: "AI analiz sonucu veya manuel rapor...",
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: const Color(0xFF161B22),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _kaydet,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text("Kaydet",
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aksiyon(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF161B22),
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// ─────────────────────────────────────────────
/// DETAY + PDF + PAYLAŞIM
/// ─────────────────────────────────────────────
class RaporDetayPage extends StatelessWidget {
  final GorselRapor rapor;

  const RaporDetayPage({super.key, required this.rapor});

  Future<void> _pdfPaylasVeGonder(BuildContext context) async {
    try {
      final pdf = pw.Document();

      final List<pw.Widget> icerik = [
        pw.Text(rapor.baslik,
            style: pw.TextStyle(
                fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(
          "${rapor.tarih.day.toString().padLeft(2, '0')}.${rapor.tarih.month.toString().padLeft(2, '0')}.${rapor.tarih.year}",
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Divider(),
        pw.SizedBox(height: 8),
        pw.Text(rapor.rapor, style: const pw.TextStyle(fontSize: 12)),
      ];

      for (final path in rapor.fotoPaths) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final img = pw.MemoryImage(bytes);
          icerik.add(pw.SizedBox(height: 12));
          icerik.add(pw.Image(img, height: 200));
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (_) => icerik,
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/isg_rapor_${rapor.id}.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: rapor.baslik);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("PDF hatası: $e")),
        );
      }
    }
  }

  Future<void> _yazdir(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(rapor.baslik,
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(rapor.rapor, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(rapor.baslik),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.amber),
            tooltip: "Yazdır",
            onPressed: () => _yazdir(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.amber),
            tooltip: "PDF Paylaş",
            onPressed: () => _pdfPaylasVeGonder(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rapor.fotoPaths.isNotEmpty) ...[
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rapor.fotoPaths.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(File(rapor.fotoPaths[i]),
                          width: 220, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.2)),
              ),
              child: Text(
                rapor.rapor,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _pdfPaylasVeGonder(context),
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text("PDF Oluştur & Paylaş",
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

