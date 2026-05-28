import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

// Kategori tanımları
const _kategoriTurler = {
  'egitim': ['Sertifika', 'Eğitim Belgesi'],
  'muayene': ['Ek-2 Muayene', 'Periyodik Muayene'],
  'katip': ['Katip Sözleşmesi'],
  'diger': ['Risk Analizi', 'Acil Durum Planı', 'Diğer'],
};

const _kategoriLabel = {
  'egitim': 'Eğitimler',
  'muayene': 'Muayeneler',
  'katip': 'Katip Sözleşmeleri',
  'diger': 'Diğer Evraklar',
};

const _kategoriIkon = {
  'egitim': Icons.school_outlined,
  'muayene': Icons.medical_services_outlined,
  'katip': Icons.assignment_outlined,
  'diger': Icons.folder_outlined,
};

const _kategoriRenk = {
  'egitim': Color(0xFF4FC3F7),
  'muayene': Color(0xFF81C784),
  'katip': Color(0xFFFFB74D),
  'diger': Color(0xFFCE93D8),
};

const _turler = [
  'Sertifika',
  'Eğitim Belgesi',
  'Ek-2 Muayene',
  'Periyodik Muayene',
  'Katip Sözleşmesi',
  'Risk Analizi',
  'Acil Durum Planı',
  'Diğer',
];

String _turdenKategori(String? tur) {
  if (tur == null) return 'diger';
  for (final entry in _kategoriTurler.entries) {
    if (entry.value.contains(tur)) return entry.key;
  }
  return 'diger';
}

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
  String _secilenKategori = 'egitim';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final belgeler = await DatabaseService.getBelgeler(widget.firmaId);
    final calisanlar =
        await DatabaseService.getCalisanlar(widget.firmaId);
    if (mounted) {
      setState(() {
        _belgeler = belgeler;
        _calisanlar = calisanlar;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtreliBelgeler {
    final turler = _kategoriTurler[_secilenKategori] ?? [];
    if (_secilenKategori == 'diger') {
      final digerDisi = [
        'Sertifika',
        'Eğitim Belgesi',
        'Ek-2 Muayene',
        'Periyodik Muayene',
        'Katip Sözleşmesi',
      ];
      return _belgeler
          .where((b) => !digerDisi.contains(b['tur']))
          .toList();
    }
    return _belgeler
        .where((b) => turler.contains(b['tur']))
        .toList();
  }

  int _kategoriSayisi(String k) {
    final turler = _kategoriTurler[k] ?? [];
    if (k == 'diger') {
      final digerDisi = [
        'Sertifika',
        'Eğitim Belgesi',
        'Ek-2 Muayene',
        'Periyodik Muayene',
        'Katip Sözleşmesi',
      ];
      return _belgeler
          .where((b) => !digerDisi.contains(b['tur']))
          .length;
    }
    return _belgeler.where((b) => turler.contains(b['tur'])).length;
  }

  // ─── TOPLU PDF ─────────────────────────────────────

  Future<void> _topluPdfYukle() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    int eslesenCount = 0;
    final defaultTur = _kategoriTurler[_secilenKategori]?.first ?? 'Diğer';

    for (final file in result.files) {
      final path = file.path;
      if (path == null) continue;

      final calisanId = _eslestirCalisan(file.name);
      if (calisanId != null) eslesenCount++;

      await DatabaseService.insertBelge(
        firmaId: widget.firmaId,
        baslik: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
        dosyaYolu: path,
        tur: defaultTur,
        calisanId: calisanId,
      );
    }

    await _loadData();

    if (!mounted) return;
    final total = result.files.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eslesenCount > 0
              ? '$total belge eklendi, $eslesenCount çalışanla eşleştirildi.'
              : '$total belge eklendi.',
        ),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final c = AppColors.of(context);
    String? secilenTur =
        _kategoriTurler[_secilenKategori]?.first ?? _turler.first;
    int? secilenCalisanId;
    DateTime? gecerlilikTarihi;
    final baslikCtrl = TextEditingController();

    // Mevcut kategorinin tur listesi
    final kategorininTurleri =
        _secilenKategori == 'diger' ? _turler : (_kategoriTurler[_secilenKategori] ?? _turler);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setM) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
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
                Text(
                  "Belge Ekle — ${_kategoriLabel[_secilenKategori]}",
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baslikCtrl,
                  decoration: InputDecoration(
                    labelText: "Belge Adı",
                    filled: true,
                    fillColor: c.input,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: secilenTur,
                  dropdownColor: c.card,
                  decoration: InputDecoration(
                    labelText: "Belge Türü",
                    filled: true,
                    fillColor: c.input,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  items: kategorininTurleri
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setM(() => secilenTur = v),
                ),
                const SizedBox(height: 10),
                if (_calisanlar.isNotEmpty)
                  DropdownButtonFormField<int?>(
                    key: ValueKey(secilenCalisanId),
                    initialValue: secilenCalisanId,
                    isExpanded: true,
                    dropdownColor: c.card,
                    decoration: InputDecoration(
                      labelText: "Çalışana Bağla (opsiyonel)",
                      filled: true,
                      fillColor: c.input,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                          value: null,
                          child: Text("— Firma Geneli —")),
                      ..._calisanlar.map((c) =>
                          DropdownMenuItem<int?>(
                            value: c['id'] as int,
                            child: Text(c['ad'] as String),
                          )),
                    ],
                    onChanged: (v) =>
                        setM(() => secilenCalisanId = v),
                  ),
                if (_calisanlar.isNotEmpty)
                  const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate:
                          gecerlilikTarihi ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2040),
                      builder: (_, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: c.accent,
                            surface: c.card,
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
                      color: c.input,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            Icons.calendar_today_outlined,
                            color: c.accent,
                            size: 16),
                        const SizedBox(width: 8),
                        Text(
                          gecerlilikTarihi != null
                              ? "Geçerlilik: ${_fmt(gecerlilikTarihi!)}"
                              : "Geçerlilik Tarihi (opsiyonel)",
                          style: TextStyle(
                            color: gecerlilikTarihi != null
                                ? c.text
                                : Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                            await DatabaseService.insertBelge(
                              firmaId: widget.firmaId,
                              baslik: baslikCtrl.text.isEmpty
                                  ? r.files.first.name
                                      .replaceAll('.pdf', '')
                                  : baslikCtrl.text,
                              dosyaYolu: path,
                              tur: secilenTur ?? 'Diğer',
                              gecerlilikTarihi:
                                  gecerlilikTarihi,
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
                              gecerlilikTarihi:
                                  gecerlilikTarihi,
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
                              gecerlilikTarihi:
                                  gecerlilikTarihi,
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
          ),
        ),
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
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  void _belgeSil(Map<String, dynamic> belge) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
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
          content: Text(
              "Dosya açılamadı. PDF görüntüleyici gerekli."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isPdf(String path) =>
      path.toLowerCase().endsWith('.pdf');

  String _fmt(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_loading) {
      return Center(
          child: CircularProgressIndicator(color: c.accent));
    }

    return Column(
      children: [
        // ── 4 KATEGORİ BUTONLARI ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: ['egitim', 'muayene', 'katip', 'diger']
                .map((k) {
              final selected = _secilenKategori == k;
              final color = _kategoriRenk[k]!;
              final count = _kategoriSayisi(k);
              return GestureDetector(
                onTap: () =>
                    setState(() => _secilenKategori = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: 0.18)
                        : c.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? color
                          : c.border,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _kategoriIkon[k],
                        color: selected
                            ? color
                            : Colors.grey[500],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _kategoriLabel[k]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? color
                                : Colors.grey[400],
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? color.withValues(alpha: 0.25)
                              : c.border,
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: selected
                                ? color
                                : Colors.grey[500],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ── FİLTRELİ BELGE LİSTESİ ───────────────────
        Expanded(
          child: _filtreliBelgeler.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _kategoriIkon[_secilenKategori],
                        color: Colors.grey[700],
                        size: 44,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${_kategoriLabel[_secilenKategori]} belge yok",
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "PDF yükleyin veya belge ekleyin",
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  itemCount: _filtreliBelgeler.length,
                  itemBuilder: (_, i) {
                    final b = _filtreliBelgeler[i];
                    final dosya = b['dosyaYolu'] as String? ?? '';
                    final isPdf = _isPdf(dosya);
                    final calisanAd = b['calisanAd'] as String?;
                    final color = _kategoriRenk[_secilenKategori]!;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => dosya.isNotEmpty
                                ? _acDosya(dosya)
                                : null,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: (isPdf
                                        ? Colors.red
                                        : color)
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                              child: isPdf
                                  ? const Icon(
                                      Icons
                                          .picture_as_pdf_outlined,
                                      color: Colors.red,
                                      size: 24)
                                  : (dosya.isNotEmpty &&
                                          File(dosya).existsSync()
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(8),
                                          child: Image.file(
                                              File(dosya),
                                              width: 46,
                                              height: 46,
                                              fit: BoxFit.cover),
                                        )
                                      : Icon(
                                          _kategoriIkon[
                                              _secilenKategori]!,
                                          color: color,
                                          size: 22)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b['baslik']?.toString() ?? '-',
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      b['tur']?.toString() ??
                                          '-',
                                      style: TextStyle(
                                        color: color.withValues(
                                            alpha: 0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                    if (calisanAd != null) ...[
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Container(
                                          padding:
                                              const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 5,
                                                  vertical: 1),
                                          decoration: BoxDecoration(
                                            color: Colors.teal
                                                .withValues(
                                                    alpha: 0.2),
                                            borderRadius:
                                                BorderRadius
                                                    .circular(4),
                                          ),
                                          child: Text(
                                            calisanAd,
                                            style: const TextStyle(
                                                color:
                                                    Colors.teal,
                                                fontSize: 10),
                                            maxLines: 1,
                                            overflow: TextOverflow
                                                .ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (b['gecerlilikTarihi'] != null)
                                  Text(
                                    "Son: ${_fmt(b['gecerlilikTarihi'] as DateTime)}",
                                    style: TextStyle(
                                        color: Colors.orange
                                            .withValues(
                                                alpha: 0.8),
                                        fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
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
                                () => _belgeSil(b),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // ── ALT BAR ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: c.cardDark,
            border: Border(
                top: BorderSide(color: c.border)),
          ),
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _topluPdfYukle,
                  icon:
                      const Icon(Icons.upload_file, size: 15),
                  label: const Text("Toplu PDF",
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[300],
                    side: BorderSide(color: Colors.red[300]!),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _belgeEkleSheet,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    "Ekle — ${_kategoriLabel[_secilenKategori]}",
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
