import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/pages/gorsel_rapor_page.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';

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
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.card,
        title: Text(
          'Raporlar',
          style: GoogleFonts.outfit(
              color: c.text, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: c.accent,
          labelColor: c.accent,
          unselectedLabelColor: c.textMuted,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          tabs: const [
            Tab(text: 'Denetim Özeti'),
            Tab(text: 'Görsel Raporlar'),
          ],
        ),
      ),
      body: _loading
          ? const AppShimmerList(itemCount: 4, itemHeight: 80)
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
    final c = AppColors.of(context);
    final widget = Container(
      width: genislik,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: c.card,
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
    final c = AppColors.of(context);
    final oran = toplam == 0 ? 0.0 : gidildi / toplam;
    final yuzde = (oran * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
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
                  style: TextStyle(
                      color: c.accent,
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
              backgroundColor: c.border,
              valueColor:
                  AlwaysStoppedAnimation<Color>(c.accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── GÖRSEL RAPORLAR LİSTESİ ────────────────────────────────────────────────
class _GorselRaporlarTab extends StatefulWidget {
  final List<Map<String, dynamic>> raporlar;

  const _GorselRaporlarTab({required this.raporlar});

  @override
  State<_GorselRaporlarTab> createState() => _GorselRaporlarTabState();
}

class _GorselRaporlarTabState extends State<_GorselRaporlarTab> {
  final _aramaCtrl = TextEditingController();
  String _arama = '';

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    if (_arama.isEmpty) return widget.raporlar;
    final q = _arama.toLowerCase();
    return widget.raporlar.where((r) {
      final baslik = (r['baslik'] as String).toLowerCase();
      final firma = (r['firmaIsim'] as String).toLowerCase();
      return baslik.contains(q) || firma.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final filtered = _filtered;

    if (widget.raporlar.isEmpty) {
      return const AppEmptyState(
        icon: Icons.camera_alt_outlined,
        title: 'Henüz görsel rapor yok',
        subtitle: 'Saha Denetim ekranından\nfotoğraf çekip AI rapor oluşturun',
        iconColor: Color(0xFFCE93D8),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            controller: _aramaCtrl,
            onChanged: (v) => setState(() => _arama = v),
            decoration: InputDecoration(
              hintText: 'Rapor başlığı veya firma adı ara...',
              prefixIcon: Icon(Icons.search, color: c.accent, size: 20),
              filled: true,
              fillColor: c.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (filtered.isEmpty)
          Expanded(
            child: AppEmptyState(
              icon: Icons.search_off_rounded,
              title: 'Sonuç bulunamadı',
              subtitle: '"$_arama" ile eşleşen rapor bulunamadı',
              iconColor: Colors.orange,
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final r = filtered[i];
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
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: c.accent.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: c.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.description_outlined,
                              color: c.accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['baslik'] as String,
                                  style: TextStyle(
                                      color: c.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(r['firmaIsim'] as String,
                                  style: TextStyle(
                                      color: c.accent.withValues(alpha: 0.8),
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
            ),
          ),
      ],
    );
  }
}
