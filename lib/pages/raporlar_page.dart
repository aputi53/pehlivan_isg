import 'package:flutter/material.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/pages/gorsel_rapor_page.dart';

class RaporlarPage extends StatefulWidget {
  const RaporlarPage({super.key});

  @override
  State<RaporlarPage> createState() => _RaporlarPageState();
}

class _RaporlarPageState extends State<RaporlarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _loading = true;

  Map<String, int> _ozet = {};
  List<Map<String, dynamic>> _gorselRaporlar = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final ozet = await DatabaseService.getDenetimOzeti();
    final raporlar = await DatabaseService.getAllGorselRaporlar();
    if (mounted) {
      setState(() {
        _ozet = ozet;
        _gorselRaporlar = raporlar;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: const Text("Raporlar",
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: "Denetim Özeti"),
            Tab(text: "Görsel Raporlar"),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _DenetimOzetiTab(ozet: _ozet),
                _GorselRaporlarTab(raporlar: _gorselRaporlar),
              ],
            ),
    );
  }
}

/// ─── DENETİM ÖZETİ ─────────────────────────────────────────────────────────
class _DenetimOzetiTab extends StatelessWidget {
  final Map<String, int> ozet;

  const _DenetimOzetiTab({required this.ozet});

  @override
  Widget build(BuildContext context) {
    final toplam =
        (ozet['GİDİLDİ'] ?? 0) + (ozet['GİDİLMEDİ'] ?? 0) +
        (ozet['KİMSE_YOK'] ?? 0) + (ozet['NORMAL'] ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _baslik("GENEL DURUM"),
          const SizedBox(height: 12),
          Row(
            children: [
              _OzetKart(
                label: "Toplam",
                sayi: toplam,
                renk: Colors.blueAccent,
                icon: Icons.business_outlined,
              ),
              const SizedBox(width: 10),
              _OzetKart(
                label: "Gidildi",
                sayi: ozet['GİDİLDİ'] ?? 0,
                renk: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _OzetKart(
                label: "Gidilmedi",
                sayi: ozet['GİDİLMEDİ'] ?? 0,
                renk: Colors.red,
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(width: 10),
              _OzetKart(
                label: "Kimse Yok",
                sayi: ozet['KİMSE_YOK'] ?? 0,
                renk: Colors.orange,
                icon: Icons.person_off_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _OzetKart(
            label: "Bekliyor",
            sayi: ozet['NORMAL'] ?? 0,
            renk: Colors.grey,
            icon: Icons.hourglass_empty_outlined,
            genislik: double.infinity,
          ),
          const SizedBox(height: 24),
          _baslik("TAMAMLANMA ORANI"),
          const SizedBox(height: 12),
          _TamamlanmaBar(
            gidildi: ozet['GİDİLDİ'] ?? 0,
            toplam: toplam,
          ),
        ],
      ),
    );
  }

  Widget _baslik(String text) => Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
        ],
      );
}

class _OzetKart extends StatelessWidget {
  final String label;
  final int sayi;
  final Color renk;
  final IconData icon;
  final double? genislik;

  const _OzetKart({
    required this.label,
    required this.sayi,
    required this.renk,
    required this.icon,
    this.genislik,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: genislik,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: renk.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: renk, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$sayi",
                  style: TextStyle(
                      color: renk,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 12)),
            ],
          ),
        ],
      ),
    );

    if (genislik != null) return widget;
    return Expanded(child: widget);
  }
}

class _TamamlanmaBar extends StatelessWidget {
  final int gidildi;
  final int toplam;

  const _TamamlanmaBar({required this.gidildi, required this.toplam});

  @override
  Widget build(BuildContext context) {
    final oran = toplam == 0 ? 0.0 : gidildi / toplam;
    final yuzde = (oran * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$gidildi / $toplam firma ziyaret edildi",
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
              Text("%$yuzde",
                  style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: oran,
              minHeight: 8,
              backgroundColor: Colors.white12,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── GÖRSEL RAPORLAR LİSTESİ ────────────────────────────────────────────────
class _GorselRaporlarTab extends StatelessWidget {
  final List<Map<String, dynamic>> raporlar;

  const _GorselRaporlarTab({required this.raporlar});

  @override
  Widget build(BuildContext context) {
    if (raporlar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined,
                color: Colors.grey[700], size: 48),
            const SizedBox(height: 12),
            Text("Henüz görsel rapor oluşturulmadı",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: raporlar.length,
      itemBuilder: (_, i) {
        final r = raporlar[i];
        final tarih = r['tarih'] as DateTime;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RaporDetayPage(
                  rapor: GorselRapor(
                    id: r['id'] as String,
                    tarih: tarih,
                    fotoPaths: List<String>.from(r['fotoPaths']),
                    baslik: r['baslik'] as String,
                    rapor: r['rapor'] as String,
                  ),
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.amber.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined,
                      color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['baslik'] as String,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(r['firmaIsim'] as String,
                          style: TextStyle(
                              color: Colors.amber.withValues(alpha: 0.8),
                              fontSize: 12)),
                      Text(
                        "${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
