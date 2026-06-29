import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';

class AksiyanPage extends StatefulWidget {
  const AksiyanPage({super.key});

  @override
  State<AksiyanPage> createState() => _AksiyanPageState();
}

class _AksiyanPageState extends State<AksiyanPage> {
  List<Map<String, dynamic>> _aksiyonlar = [];
  List<Map<String, dynamic>> _firmalar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final aksiyonlar = await DatabaseService.getAksiyonlar();
    final firmalar = await DatabaseService.getAllFirmalar();
    if (mounted) {
      setState(() {
        _aksiyonlar = aksiyonlar;
        _firmalar = firmalar;
        _loading = false;
      });
    }
  }

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  int _daysLeft(DateTime? sonTarih) {
    if (sonTarih == null) return 9999;
    final today = DateTime.now();
    final todayNorm =
        DateTime(today.year, today.month, today.day);
    return sonTarih.difference(todayNorm).inDays;
  }

  void _yeniAksiyon() {
    final c = AppColors.of(context);
    final baslikCtrl = TextEditingController();
    final aciklamaCtrl = TextEditingController();
    int? secilenFirmaId;
    DateTime? secilenTarih;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setM) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Görev / Aksiyon Ekle",
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: baslikCtrl,
                  decoration: InputDecoration(
                    labelText: "Görev Başlığı *",
                    filled: true,
                    fillColor: c.input,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: aciklamaCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: "Açıklama",
                    filled: true,
                    fillColor: c.input,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int?>(
                  key: ValueKey(secilenFirmaId),
                  initialValue: secilenFirmaId,
                  isExpanded: true,
                  dropdownColor: c.card,
                  decoration: InputDecoration(
                    labelText: "Firma (opsiyonel)",
                    filled: true,
                    fillColor: c.input,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null,
                        child: Text("— Firma bağlantısı yok —")),
                    ..._firmalar.map((f) =>
                        DropdownMenuItem<int?>(
                          value: f['id'] as int,
                          child: Text(
                            f['isim'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )),
                  ],
                  onChanged: (v) =>
                      setM(() => secilenFirmaId = v),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: secilenTarih ??
                          DateTime.now()
                              .add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
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
                      setM(() => secilenTarih = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
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
                        const SizedBox(width: 10),
                        Text(
                          secilenTarih != null
                              ? "Son tarih: ${_formatTarih(secilenTarih!)}"
                              : "Son Tarih Seç (opsiyonel)",
                          style: TextStyle(
                            color: secilenTarih != null
                                ? c.text
                                : Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (baslikCtrl.text.trim().isEmpty) return;
                      await DatabaseService.insertAksiyon(
                        firmaId: secilenFirmaId,
                        baslik: baslikCtrl.text.trim(),
                        aciklama: aciklamaCtrl.text.trim().isEmpty
                            ? null
                            : aciklamaCtrl.text.trim(),
                        sonTarih: secilenTarih,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadData();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Görev Ekle",
                        style: TextStyle(
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sil(int id) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text("Görevi Sil"),
        content: const Text("Bu görev silinsin mi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteAksiyon(id);
              if (context.mounted) Navigator.pop(context);
              _loadData();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: c.card,
          foregroundColor: c.text,
          automaticallyImplyLeading: false,
          title: Text(
            'Görev Takibi',
            style: GoogleFonts.outfit(
                color: c.text, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: c.border),
          ),
        ),
        body: const AppShimmerList(itemCount: 5),
      );
    }

    final today = DateTime.now();
    final todayNorm =
        DateTime(today.year, today.month, today.day);

    final bekleyen = _aksiyonlar
        .where((a) => !(a['tamamlandi'] as bool))
        .toList();
    final gecmis = bekleyen
        .where((a) =>
            a['sonTarih'] != null &&
            (a['sonTarih'] as DateTime)
                    .difference(todayNorm)
                    .inDays <
                0)
        .toList();
    final buHafta = bekleyen
        .where((a) {
          final d = _daysLeft(a['sonTarih'] as DateTime?);
          return d >= 0 && d <= 7;
        })
        .toList();
    final buAy = bekleyen
        .where((a) {
          final d = _daysLeft(a['sonTarih'] as DateTime?);
          return d > 7 && d <= 30;
        })
        .toList();
    final daha = bekleyen
        .where((a) {
          final d = _daysLeft(a['sonTarih'] as DateTime?);
          return d > 30;
        })
        .toList();
    final tamamlanan = _aksiyonlar
        .where((a) => a['tamamlandi'] as bool)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.card,
        foregroundColor: c.text,
        automaticallyImplyLeading: false,
        title: Text(
          'Görev Takibi',
          style: GoogleFonts.outfit(
              color: c.text, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'aksiyon_fab',
        backgroundColor: c.accent,
        foregroundColor: Colors.black,
        onPressed: _yeniAksiyon,
        child: const Icon(Icons.add),
      ),
      body: _aksiyonlar.isEmpty
          ? AppEmptyState(
              icon: Icons.task_outlined,
              title: 'Henüz görev yok',
              subtitle:
                  'Sağ alttaki + butonuna basarak\nilk görevinizi ekleyin',
            )
          : ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                if (gecmis.isNotEmpty) ...[
                  _bolumBaslik(
                      "Geciken", Colors.red, gecmis.length),
                  ...gecmis.map((a) => _aksiyanKart(a)),
                  const SizedBox(height: 12),
                ],
                if (buHafta.isNotEmpty) ...[
                  _bolumBaslik(
                      "Bu Hafta", Colors.orange, buHafta.length),
                  ...buHafta.map((a) => _aksiyanKart(a)),
                  const SizedBox(height: 12),
                ],
                if (buAy.isNotEmpty) ...[
                  _bolumBaslik(
                      "Bu Ay", Colors.amber, buAy.length),
                  ...buAy.map((a) => _aksiyanKart(a)),
                  const SizedBox(height: 12),
                ],
                if (daha.isNotEmpty) ...[
                  _bolumBaslik(
                      "Daha Sonra", Colors.blue, daha.length),
                  ...daha.map((a) => _aksiyanKart(a)),
                  const SizedBox(height: 12),
                ],
                if (tamamlanan.isNotEmpty) ...[
                  _bolumBaslik(
                      "Tamamlanan",
                      Colors.green,
                      tamamlanan.length),
                  ...tamamlanan.map((a) => _aksiyanKart(a)),
                ],
              ],
            ),
    );
  }

  Widget _bolumBaslik(String label, Color renk, int sayi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: renk,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$sayi',
              style: TextStyle(
                  color: renk,
                  fontSize: 11,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aksiyanKart(Map<String, dynamic> a) {
    final c = AppColors.of(context);
    final done = a['tamamlandi'] as bool;
    final sonTarih = a['sonTarih'] as DateTime?;
    final dl = _daysLeft(sonTarih);
    final firmaIsim = a['firmaIsim'] as String?;

    Color deadlineRenk = Colors.grey;
    String deadlineLabel = '';
    if (sonTarih != null) {
      if (dl < 0) {
        deadlineRenk = Colors.red;
        deadlineLabel = "${(-dl)} gün gecikti";
      } else if (dl == 0) {
        deadlineRenk = Colors.red;
        deadlineLabel = "Bugün!";
      } else if (dl <= 7) {
        deadlineRenk = Colors.orange;
        deadlineLabel = "$dl gün kaldı";
      } else {
        deadlineRenk = Colors.grey[500]!;
        deadlineLabel = _formatTarih(sonTarih);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: done
              ? c.border.withValues(alpha: 0.5)
              : c.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tamamlandı checkbox
          GestureDetector(
            onTap: () async {
              await DatabaseService.toggleAksiyon(
                  a['id'] as int, !done);
              _loadData();
            },
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: done
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: done ? Colors.green : Colors.grey[600]!,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: done
                  ? const Icon(Icons.check,
                      color: Colors.green, size: 14)
                  : null,
            ),
          ),
          const SizedBox(width: 10),

          // İçerik
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a['baslik'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: done
                        ? Colors.grey[600]
                        : c.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if ((a['aciklama'] as String?) != null &&
                    (a['aciklama'] as String).isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    a['aciklama'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 11),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (firmaIsim != null) ...[
                      Icon(Icons.business,
                          color: c.accent.withValues(alpha: 0.6),
                          size: 11),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          firmaIsim,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.accent.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (sonTarih != null)
                      Text(
                        deadlineLabel,
                        style: TextStyle(
                            color: deadlineRenk, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _sil(a['id'] as int),
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(Icons.delete_outline,
                  color: Colors.red, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
