import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

class BelgelerWidget extends StatefulWidget {
  final int firmaId;

  const BelgelerWidget({super.key, required this.firmaId});

  @override
  State<BelgelerWidget> createState() => _BelgelerWidgetState();
}

class _BelgelerWidgetState extends State<BelgelerWidget> {
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _belgeler = [];
  List<Map<String, dynamic>> _calisanlar = [];
  bool _loading = true;

  static const _turler = [
    "Sertifika",
    "Eğitim Belgesi",
    "Ek-2 Muayene",
    "Risk Analizi",
    "Acil Durum Planı",
    "Diğer",
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final belgeler = await DatabaseService.getBelgeler(widget.firmaId);
    final calisanlar = await DatabaseService.getCalisanlar(widget.firmaId);
    if (mounted) {
      setState(() {
        _belgeler = belgeler;
        _calisanlar = calisanlar;
        _loading = false;
      });
    }
  }

  // ─── TOPLU PDF YÜKLEME ─────────────────────────────

  Future<void> _topluPdfYukle() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    int eslesenCount = 0;
    final List<String> uyarilar = [];

    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;

      final dosyaAdi = file.name;
      final calisanId = _eslestirCalisan(dosyaAdi);
      if (calisanId != null) eslesenCount++;

      await DatabaseService.insertBelge(
        firmaId: widget.firmaId,
        baslik: dosyaAdi.replaceAll(RegExp(r'\.[^.]+$'), ''),
        dosyaYolu: path,
        tur: 'Diğer',
        calisanId: calisanId,
      );

      if (calisanId == null) uyarilar.add(dosyaAdi);
    }

    await _loadData();

    if (!mounted) return;

    final total = result.files.length;
    final msg = eslesenCount > 0
        ? '$total belge eklendi. $eslesenCount çalışanla otomatik eşleştirildi.'
        : '$total belge eklendi. Çalışan ismiyle eşleşme bulunamadı.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            eslesenCount > 0 ? Colors.green[800] : const Color(0xFF1F2937),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  int? _eslestirCalisan(String dosyaAdi) {
    String norm(String s) => s
        .toLowerCase()
        .replaceAll('ş', 's')
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ı', 'i')
        .replaceAll(RegExp(r'[^a-z0-9]'), ' ')
        .replaceAll(RegExp(r' +'), ' ')
        .trim();

    final nd = norm(dosyaAdi);

    for (final c in _calisanlar) {
      final parts = norm(c['ad'] as String)
          .split(' ')
          .where((p) => p.length > 1)
          .toList();
      if (parts.isEmpty) continue;
      if (parts.every((p) => nd.contains(p))) {
        return c['id'] as int;
      }
    }
    return null;
  }

  // ─── TEK BELGE EKLE ────────────────────────────────

  Future<void> _belgeEkleSheet() async {
    String? secilenTur = _turler.first;
    int? secilenCalisanId;
    DateTime? gecerlilikTarihi;
    final baslikCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(builder: (_, setM) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text("Belge / Dosya Ekle",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Belge adı
                TextField(
                  controller: baslikCtrl,
                  decoration: InputDecoration(
                    labelText: "Belge Adı",
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),

                // Tür
                DropdownButtonFormField<String>(
                  initialValue: secilenTur,
                  dropdownColor: const Color(0xFF161B22),
                  decoration: InputDecoration(
                    labelText: "Belge Türü",
                    filled: true,
                    fillColor: const Color(0xFF0D1117),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: _turler
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setM(() => secilenTur = v),
                ),
                const SizedBox(height: 10),

                // Çalışana bağla
                if (_calisanlar.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    key: ValueKey(secilenCalisanId),
                    initialValue: secilenCalisanId,
                    dropdownColor: const Color(0xFF161B22),
                    decoration: InputDecoration(
                      labelText: "Çalışana Bağla (opsiyonel)",
                      filled: true,
                      fillColor: const Color(0xFF0D1117),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null, child: Text("— Firma Geneli —")),
                      ..._calisanlar.map((c) => DropdownMenuItem<int?>(
                            value: c['id'] as int,
                            child: Text(c['ad'] as String),
                          )),
                    ],
                    onChanged: (v) => setM(() => secilenCalisanId = v),
                  ),
                if (_calisanlar.isNotEmpty) const SizedBox(height: 10),

                // Geçerlilik tarihi
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          gecerlilikTarihi ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (c, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.amber,
                            surface: Color(0xFF161B22),
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setM(() => gecerlilikTarihi = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          gecerlilikTarihi != null
                              ? "Geçerlilik: ${_formatTarih(gecerlilikTarihi!)}"
                              : "Geçerlilik Tarihi (opsiyonel)",
                          style: TextStyle(
                            color: gecerlilikTarihi != null
                                ? Colors.white
                                : Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Dosya kaynağı seçimi
                Row(
                  children: [
                    Expanded(
                      child: _kaynakButon(
                        icon: Icons.picture_as_pdf_outlined,
                        label: "PDF Seç",
                        color: Colors.red[300]!,
                        onTap: () async {
                          final r =
                              await FilePicker.platform.pickFiles(
                            allowMultiple: false,
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (r != null &&
                              r.files.first.path != null) {
                            final path = r.files.first.path!;
                            final id = await DatabaseService
                                .insertBelge(
                              firmaId: widget.firmaId,
                              baslik: baslikCtrl.text.isEmpty
                                  ? r.files.first.name
                                      .replaceAll('.pdf', '')
                                  : baslikCtrl.text,
                              dosyaYolu: path,
                              tur: secilenTur ?? 'Diğer',
                              gecerlilikTarihi: gecerlilikTarihi,
                              calisanId: secilenCalisanId,
                            );
                            await _loadData();
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _kaynakButon(
                        icon: Icons.camera_alt_outlined,
                        label: "Kamera",
                        color: Colors.amber,
                        onTap: () async {
                          final img = await _picker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 85);
                          if (img != null) {
                            await DatabaseService.insertBelge(
                              firmaId: widget.firmaId,
                              baslik: baslikCtrl.text.isEmpty
                                  ? secilenTur ?? "Belge"
                                  : baslikCtrl.text,
                              dosyaYolu: img.path,
                              tur: secilenTur ?? 'Diğer',
                              gecerlilikTarihi: gecerlilikTarihi,
                              calisanId: secilenCalisanId,
                            );
                            await _loadData();
                            if (ctx.mounted) Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _kaynakButon(
                        icon: Icons.photo_library_outlined,
                        label: "Galeri",
                        color: Colors.blue[300]!,
                        onTap: () async {
                          final imgs = await _picker
                              .pickMultiImage(imageQuality: 85);
                          for (final img in imgs) {
                            await DatabaseService.insertBelge(
                              firmaId: widget.firmaId,
                              baslik: baslikCtrl.text.isEmpty
                                  ? secilenTur ?? "Belge"
                                  : baslikCtrl.text,
                              dosyaYolu: img.path,
                              tur: secilenTur ?? 'Diğer',
                              gecerlilikTarihi: gecerlilikTarihi,
                              calisanId: secilenCalisanId,
                            );
                          }
                          await _loadData();
                          if (ctx.mounted && imgs.isNotEmpty) {
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _kaynakButon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _belgeSil(int index) {
    final belge = _belgeler[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Belgeyi Sil"),
        content:
            Text("${belge['baslik'] ?? 'Bu belge'} silinsin mi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteBelge(belge['id'] as int);
              await _loadData();
              if (context.mounted) Navigator.pop(context);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  Future<void> _acDosya(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Dosya açılamadı. PDF görüntüleyici yüklü olduğundan emin olun."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isPdf(String path) =>
      path.toLowerCase().endsWith('.pdf');

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.amber));
    }

    return Column(
      children: [
        Expanded(
          child: _belgeler.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_outlined,
                          color: Colors.grey[700], size: 48),
                      const SizedBox(height: 12),
                      Text("Henüz belge yok",
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                          "PDF yükleyin veya kameradan belge ekleyin",
                          style: TextStyle(
                              color: Colors.grey[700], fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: _belgeler.length,
                  itemBuilder: (_, i) {
                    final b = _belgeler[i];
                    final dosya = b['dosyaYolu'] as String? ?? '';
                    final isPdf = _isPdf(dosya);
                    final calisanAd = b['calisanAd'] as String?;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white
                                .withValues(alpha: 0.07)),
                      ),
                      child: Row(
                        children: [
                          // Dosya ikonu/önizleme
                          GestureDetector(
                            onTap: () => dosya.isNotEmpty
                                ? _acDosya(dosya)
                                : null,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isPdf
                                    ? Colors.red
                                        .withValues(alpha: 0.12)
                                    : Colors.amber
                                        .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: isPdf
                                  ? const Icon(
                                      Icons
                                          .picture_as_pdf_outlined,
                                      color: Colors.red,
                                      size: 28)
                                  : (dosya.isNotEmpty &&
                                          File(dosya).existsSync()
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                          child: Image.file(
                                              File(dosya),
                                              width: 52,
                                              height: 52,
                                              fit: BoxFit.cover),
                                        )
                                      : const Icon(
                                          Icons
                                              .insert_drive_file_outlined,
                                          color: Colors.amber,
                                          size: 26)),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Bilgi
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['baslik']?.toString() ?? "-",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      b['tur']?.toString() ?? "-",
                                      style: TextStyle(
                                        color: Colors.amber
                                            .withValues(alpha: 0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                    if (calisanAd != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.teal
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          calisanAd,
                                          style: const TextStyle(
                                              color: Colors.teal,
                                              fontSize: 10),
                                          maxLines: 1,
                                          overflow:
                                              TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _formatTarih(
                                      b['eklemeTarihi'] as DateTime),
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11),
                                ),
                                if (b['gecerlilikTarihi'] != null)
                                  Text(
                                    "Son: ${_formatTarih(b['gecerlilikTarihi'] as DateTime)}",
                                    style: TextStyle(
                                        color: Colors.orange
                                            .withValues(alpha: 0.8),
                                        fontSize: 10),
                                  ),
                              ],
                            ),
                          ),

                          // Eylemler
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (dosya.isNotEmpty) ...[
                                _aksiyon(
                                  isPdf
                                      ? Icons.open_in_new
                                      : Icons.visibility_outlined,
                                  Colors.blueAccent,
                                  () => _acDosya(dosya),
                                ),
                                const SizedBox(height: 4),
                                _aksiyon(
                                  Icons.share_outlined,
                                  Colors.green,
                                  () => Share.shareXFiles(
                                      [XFile(dosya)]),
                                ),
                                const SizedBox(height: 4),
                              ],
                              _aksiyon(
                                Icons.delete_outline,
                                Colors.red,
                                () => _belgeSil(i),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Alt bar
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2333),
            border: Border(
                top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08))),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _topluPdfYukle,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text("Toplu PDF"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[300],
                    side: BorderSide(color: Colors.red[300]!),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _belgeEkleSheet,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Belge Ekle"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _aksiyon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }
}
