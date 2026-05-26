import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;

class BelgelerWidget extends StatefulWidget {
  final int firmaId;
  final List<Map<String, dynamic>> belgeler;

  const BelgelerWidget({
    super.key,
    required this.firmaId,
    required this.belgeler,
  });

  @override
  State<BelgelerWidget> createState() => _BelgelerWidgetState();
}

class _BelgelerWidgetState extends State<BelgelerWidget> {
  final ImagePicker _picker = ImagePicker();

  static const _turler = [
    "Sertifika",
    "Risk Analizi",
    "Eğitim Belgesi",
    "Ek-2 Muayene",
    "Acil Durum Planı",
    "Diğer",
  ];

  void _belgeSilOnay(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Belgeyi Sil"),
        content: const Text("Bu belge silinsin mi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = widget.belgeler[index]['id'] as int;
              await DatabaseService.deleteBelge(id);
              setState(() => widget.belgeler.removeAt(index));
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  Future<void> _belgeEkleSheet() async {
    String? secilenTur = _turler.first;
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
          return Column(
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
              const Text("Belge Ekle",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
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
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setM(() => secilenTur = v),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: gecerlilikTarihi ?? DateTime.now(),
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
                  if (picked != null) setM(() => gecerlilikTarihi = picked);
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
              Row(
                children: [
                  Expanded(
                    child: _kaynakButon(
                      icon: Icons.camera_alt_outlined,
                      label: "Kamera",
                      onTap: () async {
                        final img = await _picker.pickImage(
                            source: ImageSource.camera, imageQuality: 85);
                        if (img != null) {
                          final id = await DatabaseService.insertBelge(
                            firmaId: widget.firmaId,
                            baslik: baslikCtrl.text.isEmpty
                                ? secilenTur ?? "Belge"
                                : baslikCtrl.text,
                            dosyaYolu: img.path,
                            tur: secilenTur ?? "Diğer",
                            gecerlilikTarihi: gecerlilikTarihi,
                          );
                          setState(() {
                            widget.belgeler.add({
                              'id': id,
                              'firmaId': widget.firmaId,
                              'baslik': baslikCtrl.text.isEmpty
                                  ? secilenTur
                                  : baslikCtrl.text,
                              'dosyaYolu': img.path,
                              'tur': secilenTur,
                              'eklemeTarihi': DateTime.now(),
                              'gecerlilikTarihi': gecerlilikTarihi,
                            });
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _kaynakButon(
                      icon: Icons.photo_library_outlined,
                      label: "Galeri",
                      onTap: () async {
                        final imgs = await _picker.pickMultiImage(
                            imageQuality: 85);
                        for (final img in imgs) {
                          final id = await DatabaseService.insertBelge(
                            firmaId: widget.firmaId,
                            baslik: baslikCtrl.text.isEmpty
                                ? secilenTur ?? "Belge"
                                : baslikCtrl.text,
                            dosyaYolu: img.path,
                            tur: secilenTur ?? "Diğer",
                            gecerlilikTarihi: gecerlilikTarihi,
                          );
                          setState(() {
                            widget.belgeler.add({
                              'id': id,
                              'firmaId': widget.firmaId,
                              'baslik': baslikCtrl.text.isEmpty
                                  ? secilenTur
                                  : baslikCtrl.text,
                              'dosyaYolu': img.path,
                              'tur': secilenTur,
                              'eklemeTarihi': DateTime.now(),
                              'gecerlilikTarihi': gecerlilikTarihi,
                            });
                          });
                        }
                        if (ctx.mounted && imgs.isNotEmpty) {
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _kaynakButon(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: Colors.amber.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.amber, size: 24),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.amber, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.belgeler.isEmpty
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
                      Text("Aşağıdan belge ekleyin",
                          style: TextStyle(
                              color: Colors.grey[700], fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: widget.belgeler.length,
                  itemBuilder: (_, i) {
                    final b = widget.belgeler[i];
                    final dosya = b['dosyaYolu'] as String;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.07)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _belgeTamEkran(context, dosya),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: File(dosya).existsSync()
                                  ? Image.file(File(dosya),
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover)
                                  : Container(
                                      width: 52,
                                      height: 52,
                                      color: const Color(0xFF1C2333),
                                      child: const Icon(
                                          Icons.insert_drive_file_outlined,
                                          color: Colors.amber,
                                          size: 26),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(b['baslik']?.toString() ?? "-",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13)),
                                const SizedBox(height: 2),
                                Text(b['tur']?.toString() ?? "-",
                                    style: TextStyle(
                                        color: Colors.amber
                                            .withValues(alpha: 0.7),
                                        fontSize: 11)),
                                Text(
                                  _formatTarih(b['eklemeTarihi'] is DateTime
                                      ? b['eklemeTarihi'] as DateTime
                                      : DateTime.now()),
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
                          IconButton(
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.blueAccent, size: 18),
                            onPressed: () async {
                              await Share.shareXFiles([XFile(dosya)]);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 18),
                            onPressed: () => _belgeSilOnay(i),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2333),
            border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
          ),
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _belgeEkleSheet,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Belge Ekle",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _belgeTamEkran(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
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
