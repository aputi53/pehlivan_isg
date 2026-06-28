import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';

class ZiyaretPlanlamaPage extends StatefulWidget {
  const ZiyaretPlanlamaPage({super.key});

  @override
  State<ZiyaretPlanlamaPage> createState() => _ZiyaretPlanlamaPageState();
}

class _ZiyaretPlanlamaPageState extends State<ZiyaretPlanlamaPage> {
  DateTime _aktifAy = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _plan = [];
  bool _loading = true;
  bool _syncing = false;
  String? _sonGrupSync;
  String? _sonPlanSync;

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkFirebase();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final plan = await DatabaseService.getZiyaretPlani(_aktifAy.year, _aktifAy.month);
    final grupLog = await DatabaseService.getLastSyncLog('gruplar');
    final planLog = await DatabaseService.getLastSyncLog('plan_${_aktifAy.year}');
    if (mounted) {
      setState(() {
        _plan = plan;
        _sonGrupSync = grupLog != null ? _formatTarih(grupLog['tarih'] as String) : null;
        _sonPlanSync = planLog != null ? _formatTarih(planLog['tarih'] as String) : null;
        _loading = false;
      });
    }
  }

  Future<void> _checkFirebase() async {
    // Firestore'da yeni veri var mı sessizce kontrol et
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pehlivan_sync')
          .doc('gruplar')
          .get();
      if (!doc.exists || !mounted) return;
      final fbTarih = doc.data()?['guncellenmeTarihi'] as String?;
      final sonLog = await DatabaseService.getLastSyncLog('gruplar');
      if (fbTarih != null && (sonLog == null || fbTarih.compareTo(sonLog['firebaseTarih'] as String? ?? '') > 0)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('PC\'den yeni grup güncellemesi var'),
              action: SnackBarAction(label: 'Yükle', onPressed: _grupSyncYap),
              duration: const Duration(seconds: 8),
              backgroundColor: Colors.blue[700],
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _grupSyncYap() async {
    setState(() => _syncing = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('pehlivan_sync')
          .doc('gruplar')
          .get();
      if (!doc.exists) throw Exception('Firebase\'de grup verisi bulunamadı');

      final veriStr = doc.data()?['veri'] as String?;
      if (veriStr == null) throw Exception('Veri boş');

      final veri = jsonDecode(veriStr) as Map<String, dynamic>;
      final gruplar = veri['gruplar'] as List<dynamic>? ?? [];
      final sayi = await DatabaseService.syncGruplar(gruplar);

      if (mounted) {
        _showSnack('$sayi grup senkronize edildi', Colors.green);
        _loadData();
      }
    } catch (e) {
      if (mounted) _showSnack('Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _planSyncYap() async {
    setState(() => _syncing = true);
    try {
      final docAdi = 'plan_${_aktifAy.year}_${_aktifAy.month.toString().padLeft(2, '0')}';
      final doc = await FirebaseFirestore.instance
          .collection('pehlivan_sync')
          .doc(docAdi)
          .get();
      if (!doc.exists) throw Exception('${_ayAdi(_aktifAy.month)} planı henüz yayınlanmamış');

      final veriStr = doc.data()?['veri'] as String?;
      if (veriStr == null) throw Exception('Plan verisi boş');

      final veri = jsonDecode(veriStr) as Map<String, dynamic>;
      final plan = veri['plan'] as List<dynamic>? ?? [];
      final sayi = await DatabaseService.syncPlan(plan, _aktifAy.year, _aktifAy.month);

      if (mounted) {
        _showSnack('${_ayAdi(_aktifAy.month)} planı yüklendi — $sayi grup güncellendi', Colors.green);
        _loadData();
      }
    } catch (e) {
      if (mounted) _showSnack('Hata: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _showSnack(String msg, Color renk) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: renk),
    );
  }

  String _formatTarih(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2,'0')}.${d.month.toString().padLeft(2,'0')}.${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return iso;
    }
  }

  String _ayAdi(int ay) =>
    ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran','Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'][ay - 1];

  void _ayDegistir(int delta) {
    setState(() {
      _aktifAy = DateTime(_aktifAy.year, _aktifAy.month + delta);
      _loading = true;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.card,
        foregroundColor: c.text,
        title: Text('Ziyaret Planlama',
            style: GoogleFonts.outfit(color: c.text, fontSize: 20, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.sync_outlined, color: c.textMuted),
              onSelected: (v) {
                if (v == 'gruplar') _grupSyncYap();
                if (v == 'plan') _planSyncYap();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'gruplar', child: Row(children: [
                  const Icon(Icons.group_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Grupları Güncelle${_sonGrupSync != null ? '\n$_sonGrupSync' : ''}',
                    style: const TextStyle(fontSize: 13)),
                ])),
                PopupMenuItem(value: 'plan', child: Row(children: [
                  const Icon(Icons.calendar_month_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('${_ayAdi(_aktifAy.month)} Planını Yükle${_sonPlanSync != null ? '\n$_sonPlanSync' : ''}',
                    style: const TextStyle(fontSize: 13)),
                ])),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Ay seçici
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: c.card,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _ayDegistir(-1),
                ),
                Expanded(
                  child: Text(
                    '${_ayAdi(_aktifAy.month)} ${_aktifAy.year}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: c.text),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _ayDegistir(1),
                ),
              ],
            ),
          ),
          Container(height: 1, color: c.border),
          // İçerik
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _plan.isEmpty
                    ? AppEmptyState(
                        icon: Icons.calendar_today_outlined,
                        title: '${_ayAdi(_aktifAy.month)} planı yüklenmemiş',
                        subtitle: 'PC\'den planı yayınlayın\nsonra ↻ butonuyla yükleyin',
                        iconColor: Colors.blue,
                      )
                    : _buildPlanListesi(c),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _planSyncYap,
        icon: const Icon(Icons.cloud_download_outlined),
        label: Text('${_ayAdi(_aktifAy.month)} Planını Yükle'),
        backgroundColor: Colors.blue[700],
      ),
    );
  }

  Widget _buildPlanListesi(AppColors c) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _plan.length,
      itemBuilder: (_, i) {
        final item = _plan[i];
        final tarih = DateTime.parse(item['tarih'] as String);
        final gun = tarih.day;
        final gunAdi = _gunAdi(tarih.weekday);
        final firmaSayisi = item['firmaSayisi'] as int? ?? 0;

        return GestureDetector(
          onTap: () => _gunDetayAc(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$gun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c.text)),
                      Text(gunAdi, style: TextStyle(fontSize: 10, color: c.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['grupAdi'] as String? ?? '',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.text)),
                      const SizedBox(height: 3),
                      Text('$firmaSayisi firma',
                        style: TextStyle(fontSize: 12, color: c.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: c.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _gunDetayAc(Map<String, dynamic> item) async {
    final grupId = item['id'] as int;
    final grupAdi = item['grupAdi'] as String? ?? '';
    final firmalar = await DatabaseService.getFirmalar(grupId);

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _GrupDetaySheet(grupAdi: grupAdi, firmalar: firmalar),
    );
  }

  String _gunAdi(int weekday) {
    const gunler = ['Pzt','Sal','Çar','Per','Cum','Cmt','Paz'];
    return gunler[weekday - 1];
  }
}

class _GrupDetaySheet extends StatelessWidget {
  final String grupAdi;
  final List<Map<String, dynamic>> firmalar;

  const _GrupDetaySheet({required this.grupAdi, required this.firmalar});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.3,
      expand: false,
      builder: (_, sc) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(grupAdi,
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: c.text)),
                const Spacer(),
                Text('${firmalar.length} firma',
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
              ],
            ),
          ),
          Divider(color: c.border, height: 1),
          Expanded(
            child: firmalar.isEmpty
                ? const Center(child: Text('Bu gruba atanmış firma yok'))
                : ListView.builder(
                    controller: sc,
                    padding: const EdgeInsets.all(12),
                    itemCount: firmalar.length,
                    itemBuilder: (_, i) {
                      final f = firmalar[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: c.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: c.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.business_outlined, size: 16, color: c.textMuted),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(f['isim'] as String? ?? '',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.text)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
