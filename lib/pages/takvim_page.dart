import 'package:flutter/material.dart';
import 'package:pehlivan_isg/pages/firma_detay_page.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';

class TakvimPage extends StatefulWidget {
  const TakvimPage({super.key});

  @override
  State<TakvimPage> createState() => _TakvimPageState();
}

class _TakvimPageState extends State<TakvimPage> {
  List<Map<String, dynamic>> _etkinlikler = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await DatabaseService.getTakvimEtkinlikleri();
    if (mounted) {
      setState(() {
        _etkinlikler = list;
        _loading = false;
      });
    }
  }

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  Color _renk(int daysLeft) {
    if (daysLeft < 0) return Colors.red;
    if (daysLeft <= 7) return Colors.red;
    if (daysLeft <= 30) return Colors.orange;
    return Colors.green;
  }

  IconData _ikon(String tip) {
    if (tip == 'Eğitim') return Icons.school_outlined;
    if (tip == 'Muayene') return Icons.medical_services_outlined;
    if (tip.contains('Sözleşme')) return Icons.assignment_outlined;
    return Icons.folder_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: c.card,
          foregroundColor: c.text,
          title: Text('Takvim / Ajanda',
              style: GoogleFonts.outfit(
                  color: c.text, fontSize: 20, fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: c.border),
          ),
        ),
        body: const AppShimmerList(itemCount: 6),
      );
    }

    // Grupla
    final gecmis = _etkinlikler
        .where((e) => (e['daysLeft'] as int) < 0)
        .toList();
    final buHafta = _etkinlikler
        .where((e) {
          final d = e['daysLeft'] as int;
          return d >= 0 && d <= 7;
        })
        .toList();
    final buAy = _etkinlikler
        .where((e) {
          final d = e['daysLeft'] as int;
          return d > 7 && d <= 30;
        })
        .toList();
    final sonra = _etkinlikler
        .where((e) => (e['daysLeft'] as int) > 30)
        .toList();

    final tumBos = _etkinlikler.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.card,
        foregroundColor: c.text,
        title: Text(
          'Takvim / Ajanda',
          style: GoogleFonts.outfit(
              color: c.text, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: c.textMuted),
            onPressed: () {
              setState(() => _loading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: tumBos
          ? AppEmptyState(
              icon: Icons.event_available_outlined,
              title: 'Yaklaşan son tarih yok',
              subtitle:
                  'Firmalar → Çalışanlar bölümüne\neğitim veya muayene belgesi ekleyin',
              iconColor: const Color(0xFF81C784),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (gecmis.isNotEmpty) ...[
                  _grupBaslik(
                      "Süresi Geçmiş", Colors.red, Icons.error_outline,
                      gecmis.length),
                  ...gecmis.map((e) => _kart(e)),
                  const SizedBox(height: 12),
                ],
                if (buHafta.isNotEmpty) ...[
                  _grupBaslik(
                      "Bu Hafta", Colors.red[300]!, Icons.warning_amber,
                      buHafta.length),
                  ...buHafta.map((e) => _kart(e)),
                  const SizedBox(height: 12),
                ],
                if (buAy.isNotEmpty) ...[
                  _grupBaslik(
                      "Bu Ay", Colors.orange, Icons.access_time_outlined,
                      buAy.length),
                  ...buAy.map((e) => _kart(e)),
                  const SizedBox(height: 12),
                ],
                if (sonra.isNotEmpty) ...[
                  _grupBaslik(
                      "Gelecek", Colors.green, Icons.check_circle_outline,
                      sonra.length),
                  ...sonra.map((e) => _kart(e)),
                ],
              ],
            ),
    );
  }

  Widget _grupBaslik(
      String baslik, Color renk, IconData ikon, int sayi) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(ikon, color: renk, size: 16),
          const SizedBox(width: 6),
          Text(
            baslik,
            style: TextStyle(
              color: renk,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
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

  Widget _kart(Map<String, dynamic> e) {
    final c = AppColors.of(context);
    final daysLeft = e['daysLeft'] as int;
    final renk = _renk(daysLeft);
    final tarih = e['tarih'] as DateTime;
    final calisanAd = e['calisanAd'] as String?;

    String kaldiLabel;
    if (daysLeft < 0) {
      kaldiLabel = "${(-daysLeft)} gün önce doldu";
    } else if (daysLeft == 0) {
      kaldiLabel = "Bugün sona eriyor!";
    } else {
      kaldiLabel = "$daysLeft gün kaldı";
    }

    return GestureDetector(
      onTap: () {
        final firmaId = e['firmaId'] as int?;
        if (firmaId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FirmaDetayPage(firmaId: firmaId),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: renk.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_ikon(e['tip'] as String),
                  color: renk, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e['baslik'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        e['firmaIsim'] as String,
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (calisanAd != null) ...[
                        Text(" • ",
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11)),
                        Flexible(
                          child: Text(
                            calisanAd,
                            style: const TextStyle(
                                color: Colors.teal, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${e['tip']}  •  ${_formatTarih(tarih)}",
                    style:
                        TextStyle(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: renk.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    kaldiLabel,
                    style: TextStyle(
                      color: renk,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
