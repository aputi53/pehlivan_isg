import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';
import 'package:pehlivan_isg/widgets/form_helpers.dart';

class PersonelHavuzuPage extends StatefulWidget {
  const PersonelHavuzuPage({super.key});

  @override
  State<PersonelHavuzuPage> createState() => _PersonelHavuzuPageState();
}

class _PersonelHavuzuPageState extends State<PersonelHavuzuPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _uzmanlar = [];
  List<Map<String, dynamic>> _hekimler = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final uzmanlar = await DatabaseService.getPersonelHavuzu(tip: 'UZMAN');
    final hekimler = await DatabaseService.getPersonelHavuzu(tip: 'HEKIM');
    if (mounted) {
      setState(() {
        _uzmanlar = uzmanlar;
        _hekimler = hekimler;
        _loading = false;
      });
    }
  }

  Future<void> _sil(int id) async {
    final c = AppColors.of(context);
    final onay = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: c.card,
        title: Text('Sil', style: GoogleFonts.inter(color: c.text)),
        content: Text('Bu personel silinecek. Emin misiniz?',
            style: GoogleFonts.inter(color: c.textMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal',
                  style: GoogleFonts.inter(color: c.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sil',
                  style: TextStyle(color: Color(0xFFEF4444)))),
        ],
      ),
    );
    if (onay == true) {
      await DatabaseService.deletePersonel(id);
      _loadData();
    }
  }

  Future<void> _form({Map<String, dynamic>? mevcut, required String tip}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PersonelForm(
        mevcut: mevcut,
        tip: tip,
        onKayit: (data) async {
          if (mevcut != null) {
            await DatabaseService.updatePersonel(mevcut['id'] as int, data);
          } else {
            await DatabaseService.insertPersonel(
              tip: tip,
              isim: data['isim'] as String,
              unvan: data['unvan'] as String?,
              belgeNo: data['belgeNo'] as String?,
              dipNo: data['dipNo'] as String?,
            );
          }
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.card,
        elevation: 0,
        foregroundColor: c.text,
        title: Text('Personel Havuzu',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: c.text, fontSize: 17)),
        bottom: TabBar(
          controller: _tab,
          labelColor: const Color(0xFFE8B84B),
          unselectedLabelColor: c.textMuted,
          indicatorColor: const Color(0xFFE8B84B),
          tabs: const [
            Tab(text: 'İGU Uzmanları'),
            Tab(text: 'İşyeri Hekimleri'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'personel_havuzu_fab',
        backgroundColor: const Color(0xFFE8B84B),
        foregroundColor: Colors.black,
        onPressed: () =>
            _form(tip: _tab.index == 0 ? 'UZMAN' : 'HEKIM'),
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE8B84B)))
          : TabBarView(
              controller: _tab,
              children: [
                _liste(_uzmanlar, 'UZMAN'),
                _liste(_hekimler, 'HEKIM'),
              ],
            ),
    );
  }

  Widget _liste(List<Map<String, dynamic>> liste, String tip) {
    if (liste.isEmpty) {
      return AppEmptyState(
        icon: tip == 'UZMAN'
            ? Icons.engineering_outlined
            : Icons.local_hospital_outlined,
        title: tip == 'UZMAN' ? 'Uzman eklenmemiş' : 'Hekim eklenmemiş',
        subtitle: '+ butonuyla ekleyebilirsiniz',
        iconColor: const Color(0xFFE8B84B),
      );
    }
    final c = AppColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: liste.length,
      itemBuilder: (_, i) {
        final p = liste[i];
        final isim = p['isim'] as String;
        final unvan = (p['unvan'] as String?) ?? '';
        final belgeNo = (p['belgeNo'] as String?) ?? '';
        final dipNo = (p['dipNo'] as String?) ?? '';
        return Card(
          color: c.card,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: c.border.withValues(alpha: 0.4))),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tip == 'UZMAN'
                    ? const Color(0xFFE8B84B).withValues(alpha: 0.15)
                    : const Color(0xFF4FC3F7).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                tip == 'UZMAN'
                    ? Icons.engineering_rounded
                    : Icons.local_hospital_rounded,
                color: tip == 'UZMAN'
                    ? const Color(0xFFE8B84B)
                    : const Color(0xFF4FC3F7),
                size: 20,
              ),
            ),
            title: Text(isim,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: c.text,
                    fontSize: 13)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (unvan.isNotEmpty)
                  Text(unvan,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: c.textMuted)),
                if (belgeNo.isNotEmpty)
                  Text('Belge No: $belgeNo',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: c.textMuted)),
                if (dipNo.isNotEmpty)
                  Text('Dip/Tes No: $dipNo',
                      style: GoogleFonts.inter(
                          fontSize: 10, color: c.textMuted)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: c.textMuted, size: 18),
                  onPressed: () => _form(mevcut: p, tip: tip),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 18),
                  onPressed: () => _sil(p['id'] as int),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Form ────────────────────────────────────────────────────────────────────

class _PersonelForm extends StatefulWidget {
  final Map<String, dynamic>? mevcut;
  final String tip;
  final Future<void> Function(Map<String, dynamic>) onKayit;

  const _PersonelForm(
      {this.mevcut, required this.tip, required this.onKayit});

  @override
  State<_PersonelForm> createState() => _PersonelFormState();
}

class _PersonelFormState extends State<_PersonelForm> {
  late TextEditingController _isim;
  late TextEditingController _unvan;
  late TextEditingController _belgeNo;
  late TextEditingController _dipNo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.mevcut;
    _isim = TextEditingController(text: m?['isim'] as String? ?? '');
    _unvan = TextEditingController(text: m?['unvan'] as String? ?? '');
    _belgeNo = TextEditingController(text: m?['belgeNo'] as String? ?? '');
    _dipNo = TextEditingController(text: m?['dipNo'] as String? ?? '');
  }

  @override
  void dispose() {
    _isim.dispose();
    _unvan.dispose();
    _belgeNo.dispose();
    _dipNo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isUzman = widget.tip == 'UZMAN';
    final baslik = widget.mevcut != null
        ? (isUzman ? 'Uzmanı Düzenle' : 'Hekimi Düzenle')
        : (isUzman ? 'Yeni Uzman Ekle' : 'Yeni Hekim Ekle');

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(baslik,
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: c.text,
                      fontSize: 16)),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: c.textMuted),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 16),
          TextFormField(
            controller: _isim,
            style: GoogleFonts.inter(color: c.text, fontSize: 13),
            decoration: buildInputDecoration(
                c, isUzman ? 'Ad Soyad *' : 'Dr. Ad Soyad *'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _unvan,
            style: GoogleFonts.inter(color: c.text, fontSize: 13),
            decoration: buildInputDecoration(
                c,
                isUzman
                    ? 'Sınıf (A/B/C Sınıfı İGU)'
                    : 'Unvan (İşyeri Hekimi)'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _belgeNo,
            style: GoogleFonts.inter(color: c.text, fontSize: 13),
            decoration: buildInputDecoration(
                c, isUzman ? 'Belge No (İGU-XXXXXX)' : 'Belge No (İH-XXXXX)'),
          ),
          if (!isUzman) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _dipNo,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              decoration:
                  buildInputDecoration(c, 'Diploma / Tescil No (opsiyonel)'),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_isim.text.trim().isEmpty) return;
                      setState(() => _saving = true);
                      await widget.onKayit({
                        'tip': widget.tip,
                        'isim': _isim.text.trim(),
                        'unvan': _unvan.text.trim().isEmpty
                            ? null
                            : _unvan.text.trim(),
                        'belgeNo': _belgeNo.text.trim().isEmpty
                            ? null
                            : _belgeNo.text.trim(),
                        'dipNo': _dipNo.text.trim().isEmpty
                            ? null
                            : _dipNo.text.trim(),
                        'aktif': 1,
                      });
                      if (mounted) Navigator.pop(context);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8B84B),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text('Kaydet',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
