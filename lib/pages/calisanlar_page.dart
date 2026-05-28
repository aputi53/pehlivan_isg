import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pehlivan_isg/services/database_service.dart';

class CalisanlarPage extends StatefulWidget {
  final int firmaId;
  final Map<String, dynamic> firma;

  const CalisanlarPage({
    super.key,
    required this.firmaId,
    required this.firma,
  });

  @override
  State<CalisanlarPage> createState() => _CalisanlarPageState();
}

class _CalisanlarPageState extends State<CalisanlarPage> {
  List<Map<String, dynamic>> _calisanlar = [];
  Map<String, dynamic> _firma = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _firma = widget.firma;
    _loadData();
  }

  @override
  void didUpdateWidget(CalisanlarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _firma = widget.firma;
  }

  Future<void> _loadData() async {
    final calisanlar = await DatabaseService.getCalisanlar(widget.firmaId);
    final firma = await DatabaseService.getFirmaById(widget.firmaId);
    if (!mounted) return;
    setState(() {
      _calisanlar = calisanlar;
      if (firma != null) _firma = firma;
      _loading = false;
    });
  }

  Future<void> _csvImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;

    final path = result.files.first.path;
    if (path == null) return;

    final bytes = await File(path).readAsBytes();
    String content;
    try {
      content = utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      content = latin1.decode(bytes);
    }
    if (content.startsWith('﻿')) content = content.substring(1);

    final lines = content.split(RegExp(r'\r?\n'));
    final List<Map<String, String?>> entries = [];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final sep = trimmed.contains(';') ? ';' : ',';
      final cols = trimmed.split(sep).map((c) => c.trim()).toList();

      final ad = cols[0];
      if (ad.isEmpty) continue;

      // İlk satır başlık mı?
      if (entries.isEmpty &&
          (ad.toLowerCase() == 'ad' ||
              ad.toLowerCase() == 'isim' ||
              ad.toLowerCase() == 'ad soyad')) {
        continue;
      }

      final pozisyon =
          cols.length > 1 && cols[1].isNotEmpty ? cols[1] : null;
      entries.add({'ad': ad, 'pozisyon': pozisyon});
    }

    if (entries.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("CSV'de geçerli kayıt bulunamadı."),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    for (final e in entries) {
      await DatabaseService.insertCalisan(
          widget.firmaId, e['ad']!, e['pozisyon']);
    }

    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${entries.length} çalışan eklendi."),
          backgroundColor: Colors.green[800],
        ),
      );
    }
  }

  void _addCalisanSheet() {
    final adCtrl = TextEditingController();
    final pozCtrl = TextEditingController();

    showModalBottomSheet(
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
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Çalışan Ekle",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _inputField(adCtrl, "Ad Soyad *"),
            const SizedBox(height: 10),
            _inputField(pozCtrl, "Pozisyon / Unvan"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final ad = adCtrl.text.trim();
                  if (ad.isEmpty) return;
                  await DatabaseService.insertCalisan(
                    widget.firmaId,
                    ad,
                    pozCtrl.text.trim().isEmpty ? null : pozCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Ekle",
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _openDetay(Map<String, dynamic> calisan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1117),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CalisanDetaySheet(
        calisan: calisan,
        firmaId: widget.firmaId,
        firmaAyarlari: _firma,
        onChanged: _loadData,
      ),
    );
  }

  void _deleteCalisan(Map<String, dynamic> calisan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Çalışanı Sil"),
        content: Text(
            "${calisan['ad']} kişisi ve tüm belgeleri silinsin mi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteCalisan(calisan['id'] as int);
              if (context.mounted) Navigator.pop(context);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  Widget _countChip(int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.amber));
    }

    return Column(
      children: [
        Expanded(
          child: _calisanlar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          color: Colors.grey[700], size: 56),
                      const SizedBox(height: 12),
                      Text(
                        "Henüz çalışan eklenmedi",
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Aşağıdan ekleyin veya CSV yükleyin",
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: _calisanlar.length,
                  itemBuilder: (_, i) {
                    final c = _calisanlar[i];
                    final egitimCount = c['egitimCount'] as int? ?? 0;
                    final muayeneCount =
                        c['muayeneCount'] as int? ?? 0;
                    final pozisyon =
                        c['pozisyon'] as String? ?? '';
                    return GestureDetector(
                      onTap: () => _openDetay(c),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white
                                  .withValues(alpha: 0.07)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.person,
                                  color: Colors.amber, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['ad'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (pozisyon.isNotEmpty)
                                    Text(
                                      pozisyon,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                _countChip(egitimCount,
                                    Icons.school_outlined,
                                    Colors.blue),
                                const SizedBox(width: 6),
                                _countChip(muayeneCount,
                                    Icons.medical_services_outlined,
                                    Colors.green),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () =>
                                      _deleteCalisan(c),
                                  child: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18),
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
                  onPressed: _csvImport,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text("CSV Yükle"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(color: Colors.amber),
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
                  onPressed: _addCalisanSheet,
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text("Çalışan Ekle"),
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
}

// ─────────────────────────────────────────────────────
// ÇALIŞAN DETAY SAYFASI (BottomSheet)
// ─────────────────────────────────────────────────────

class _CalisanDetaySheet extends StatefulWidget {
  final Map<String, dynamic> calisan;
  final int firmaId;
  final Map<String, dynamic> firmaAyarlari;
  final VoidCallback onChanged;

  const _CalisanDetaySheet({
    required this.calisan,
    required this.firmaId,
    required this.firmaAyarlari,
    required this.onChanged,
  });

  @override
  State<_CalisanDetaySheet> createState() =>
      _CalisanDetaySheetState();
}

class _CalisanDetaySheetState extends State<_CalisanDetaySheet> {
  List<Map<String, dynamic>> _belgeler = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBelgeler();
  }

  Future<void> _loadBelgeler() async {
    final belgeler = await DatabaseService.getCalisanBelgeleri(
        widget.calisan['id'] as int);
    if (mounted) {
      setState(() {
        _belgeler = belgeler;
        _loading = false;
      });
    }
  }

  void _addBelgeSheet(String tur) {
    final baslikCtrl = TextEditingController();
    DateTime? seciliTarih;

    final defaultYil = tur == 'egitim'
        ? (widget.firmaAyarlari['egitimGecerlilikYil'] as int? ?? 1)
        : (widget.firmaAyarlari['muayeneGecerlilikYil'] as int? ?? 1);

    int gecerlilikYil = defaultYil;
    final yillar = [1, 3, 5];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setM) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tur == 'egitim'
                    ? "Eğitim Sertifikası Ekle"
                    : "Muayene Formu Ekle",
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baslikCtrl,
                decoration: InputDecoration(
                  labelText: tur == 'egitim'
                      ? "Eğitim Adı *"
                      : "Muayene Türü / Açıklama *",
                  filled: true,
                  fillColor: const Color(0xFF0D1117),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2010),
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
                    setM(() => seciliTarih = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        seciliTarih != null
                            ? "${seciliTarih!.day.toString().padLeft(2, '0')}.${seciliTarih!.month.toString().padLeft(2, '0')}.${seciliTarih!.year}"
                            : "Belge Tarihi Seçin *",
                        style: TextStyle(
                          color: seciliTarih != null
                              ? Colors.white
                              : Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1117),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      "Geçerlilik Süresi",
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 13),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: gecerlilikYil,
                      dropdownColor: const Color(0xFF161B22),
                      underline: const SizedBox(),
                      style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      items: yillar
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text("$y Yıl"),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setM(() => gecerlilikYil = v ?? gecerlilikYil),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final baslik = baslikCtrl.text.trim();
                    if (baslik.isEmpty || seciliTarih == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Açıklama ve tarih alanları zorunludur.")),
                      );
                      return;
                    }
                    await DatabaseService.insertCalisanBelge(
                      calisanId: widget.calisan['id'] as int,
                      firmaId: widget.firmaId,
                      tur: tur,
                      baslik: baslik,
                      belgeTarihi: seciliTarih!,
                      gecerlilikYil: gecerlilikYil,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadBelgeler();
                    widget.onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kaydet",
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBelge(int id) async {
    await DatabaseService.deleteCalisanBelge(id);
    await _loadBelgeler();
    widget.onChanged();
  }

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  Color _expiryColor(int daysLeft) {
    if (daysLeft < 0) return Colors.red;
    if (daysLeft <= 30) return Colors.orange;
    return Colors.green;
  }

  String _expiryLabel(int daysLeft) {
    if (daysLeft < 0) return "Süresi Doldu (${(-daysLeft)} gün önce)";
    if (daysLeft == 0) return "Bugün Sona Eriyor!";
    if (daysLeft <= 30) return "$daysLeft gün kaldı";
    final months = daysLeft ~/ 30;
    if (months < 12) return "~$months ay kaldı";
    return "~${daysLeft ~/ 365} yıl kaldı";
  }

  Widget _belgeSection(
      String tur, String baslik, IconData icon, Color color) {
    final list =
        _belgeler.where((b) => b['tur'] == tur).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                baslik,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _addBelgeSheet(tur),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text("Ekle",
                          style:
                              TextStyle(color: color, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              "Henüz kayıt yok",
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          )
        else
          ...list.map((belge) {
            final belgeTarihi =
                DateTime.parse(belge['belgeTarihi'] as String);
            final gecerlilikYil = belge['gecerlilikYil'] as int;
            final expiry = DateTime(
              belgeTarihi.year + gecerlilikYil,
              belgeTarihi.month,
              belgeTarihi.day,
            );
            final today = DateTime.now();
            final todayNorm =
                DateTime(today.year, today.month, today.day);
            final daysLeft =
                expiry.difference(todayNorm).inDays;
            final ec = _expiryColor(daysLeft);
            final el = _expiryLabel(daysLeft);

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: ec.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          belge['baslik'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Belge: ${_formatTarih(belgeTarihi)}  •  $gecerlilikYil yıl",
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.circle,
                                color: ec, size: 7),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                "Bitiş: ${_formatTarih(expiry)}  •  $el",
                                style: TextStyle(
                                    color: ec, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        _deleteBelge(belge['id'] as int),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                    ),
                  ),
                ],
              ),
            );
          }),
        const Divider(color: Colors.white12, height: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final calisan = widget.calisan;
    final pozisyon = calisan['pozisyon'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20)),
              border: Border(
                  bottom: BorderSide(
                      color:
                          Colors.white.withValues(alpha: 0.08))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.amber, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            calisan['ad'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (pozisyon.isNotEmpty)
                            Text(
                              pozisyon,
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.amber))
                : ListView(
                    controller: scrollCtrl,
                    children: [
                      const SizedBox(height: 4),
                      _belgeSection(
                        'egitim',
                        'Eğitim Sertifikaları',
                        Icons.school_outlined,
                        Colors.blue,
                      ),
                      const SizedBox(height: 4),
                      _belgeSection(
                        'muayene',
                        'Muayene Formları',
                        Icons.medical_services_outlined,
                        Colors.green,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
