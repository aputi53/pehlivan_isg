import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pehlivan_isg/utils/platform_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pehlivan_isg/pages/calisanlar_page.dart';
import 'package:pehlivan_isg/pages/gorsel_rapor_page.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/belgeler_widget.dart';

class FirmaDetayPage extends StatefulWidget {
  final int firmaId;
  const FirmaDetayPage({super.key, required this.firmaId});

  @override
  State<FirmaDetayPage> createState() => _FirmaDetayPageState();
}

class _FirmaDetayPageState extends State<FirmaDetayPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _firma;
  bool _loading = true;

  List<Map<String, dynamic>> _notlar = [];
  List<GorselRapor> _raporlar = [];
  List<Map<String, dynamic>> _belgeler = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final f = await DatabaseService.getFirmaById(widget.firmaId);
    if (!mounted || f == null) return;

    final raporMaps = f['raporlar'] as List<Map<String, dynamic>>;
    setState(() {
      _firma = f;
      _notlar = List<Map<String, dynamic>>.from(f['notlar']);
      _raporlar = raporMaps
          .map((r) => GorselRapor(
                id: r['id'] as String,
                tarih: r['tarih'] as DateTime,
                fotoPaths: List<String>.from(r['fotoPaths']),
                baslik: r['baslik'] as String,
                rapor: r['rapor'] as String,
              ))
          .toList();
      _belgeler = List<Map<String, dynamic>>.from(f['belgeler']);
      _loading = false;
    });
  }

  void _deleteFirma() {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Firmayı Sil"),
        content: Text(
            "${_firma?['isim'] ?? 'Bu firma'} silinsin mi? Tüm notlar, raporlar ve belgeler de silinir."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final savedFirma = Map<String, dynamic>.from(_firma!);
              final savedNotlar = _notlar
                  .map((n) => Map<String, dynamic>.from(n))
                  .toList();
              final savedRaporlar = List<GorselRapor>.from(_raporlar);
              final savedBelgeler = _belgeler
                  .map((b) => Map<String, dynamic>.from(b))
                  .toList();

              await DatabaseService.deleteFirma(widget.firmaId);
              if (context.mounted) Navigator.pop(context); // dialog

              if (!mounted) return;

              bool undone = false;
              final snackCtrl =
                  ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("${savedFirma['isim']} silindi"),
                  action: SnackBarAction(
                    label: "Geri Al",
                    textColor: Colors.amber,
                    onPressed: () async {
                      undone = true;
                      final newId =
                          await DatabaseService.insertFirmaStandalone(
                        savedFirma['isim'] as String,
                        savedFirma['telefon'] as String? ?? '',
                        savedFirma['mail'] as String? ?? '',
                      );
                      if (savedFirma['grupId'] != null) {
                        await DatabaseService.assignFirmaToGrup(
                            newId, savedFirma['grupId'] as int);
                      }
                      for (final n in savedNotlar) {
                        await DatabaseService.insertNot(
                            newId,
                            n['metin'] as String,
                            n['zaman'] as DateTime,
                            List<String>.from(n['fotoPaths'] as List));
                      }
                      for (final r in savedRaporlar) {
                        await DatabaseService.insertGorselRapor(
                          id: r.id,
                          firmaId: newId,
                          baslik: r.baslik,
                          rapor: r.rapor,
                          tarih: r.tarih,
                          fotoPaths: r.fotoPaths,
                        );
                      }
                      for (final b in savedBelgeler) {
                        await DatabaseService.insertBelge(
                          firmaId: newId,
                          baslik: b['baslik'] as String,
                          dosyaYolu: b['dosyaYolu'] as String,
                          tur: b['tur'] as String,
                          gecerlilikTarihi:
                              b['gecerlilikTarihi'] as DateTime?,
                        );
                      }
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1F2937),
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );

              final reason = await snackCtrl.closed;
              if (!undone && mounted &&
                  reason != SnackBarClosedReason.action) {
                Navigator.pop(context); // pop detail page
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    if (_loading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: colors.accent)),
      );
    }
    if (_firma == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: colors.card),
        body: const Center(child: Text("Firma bulunamadı")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        title: Text(
          _firma!['isim'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
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
            Tab(text: "Genel"),
            Tab(text: "Çalışanlar"),
            Tab(text: "Notlar"),
            Tab(text: "Raporlar"),
            Tab(text: "Belgeler"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteFirma,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _GenelTab(
            firma: _firma!,
            onUpdated: _loadData,
          ),
          CalisanlarPage(
            firmaId: widget.firmaId,
            firma: _firma!,
          ),
          _NotlarTab(
            firmaId: widget.firmaId,
            notlar: _notlar,
            onChanged: _loadData,
          ),
          _RaporlarTab(
            firmaId: widget.firmaId,
            firmaAdi: _firma!['isim'] as String,
            raporlar: _raporlar,
            onChanged: _loadData,
          ),
          BelgelerWidget(firmaId: widget.firmaId),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GENEL TAB
// ─────────────────────────────────────────────

class _GenelTab extends StatefulWidget {
  final Map<String, dynamic> firma;
  final VoidCallback onUpdated;
  const _GenelTab({required this.firma, required this.onUpdated});

  @override
  State<_GenelTab> createState() => _GenelTabState();
}

class _GenelTabState extends State<_GenelTab> {
  List<Map<String, dynamic>> _gruplar = [];
  bool _gruplarLoaded = false;
  late int _egitimYil;
  late int _muayeneYil;
  late int _evrakYil;

  @override
  void initState() {
    super.initState();
    _egitimYil =
        (widget.firma['egitimGecerlilikYil'] as int?) ?? 1;
    _muayeneYil =
        (widget.firma['muayeneGecerlilikYil'] as int?) ?? 1;
    _evrakYil =
        (widget.firma['evrakGecerlilikYil'] as int?) ?? 1;
    _loadGruplar();
  }

  @override
  void didUpdateWidget(_GenelTab old) {
    super.didUpdateWidget(old);
    _egitimYil =
        (widget.firma['egitimGecerlilikYil'] as int?) ?? 1;
    _muayeneYil =
        (widget.firma['muayeneGecerlilikYil'] as int?) ?? 1;
    _evrakYil =
        (widget.firma['evrakGecerlilikYil'] as int?) ?? 1;
  }

  Future<void> _loadGruplar() async {
    final g = await DatabaseService.getGruplarSimple();
    if (mounted) setState(() { _gruplar = g; _gruplarLoaded = true; });
  }

  void _editSheet() {
    final isimCtrl =
        TextEditingController(text: widget.firma['isim'] as String);
    final telCtrl =
        TextEditingController(text: widget.firma['telefon'] as String? ?? '');
    final mailCtrl =
        TextEditingController(text: widget.firma['mail'] as String? ?? '');

    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text("Firma Bilgilerini Düzenle",
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _field(isimCtrl, "Firma Adı *"),
            const SizedBox(height: 10),
            _field(telCtrl, "Telefon",
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _field(mailCtrl, "E-posta",
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final isim = isimCtrl.text.trim();
                  if (isim.isEmpty) return;
                  await DatabaseService.updateFirma(
                    widget.firma['id'] as int,
                    isim,
                    telCtrl.text.trim(),
                    mailCtrl.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  widget.onUpdated();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
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
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    final colors = AppColors.of(context);
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colors.input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _assignGrup(int? grupId) async {
    await DatabaseService.assignFirmaToGrup(
        widget.firma['id'] as int, grupId);
    widget.onUpdated();
  }

  Future<void> _pickZiyaretTarihi() async {
    final now = DateTime.now();
    final existing = widget.firma['ziyaretTarihi'] as DateTime?;
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) => Theme(
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
      await DatabaseService.updateFirmaZiyaretTarihi(
          widget.firma['id'] as int, picked);
      widget.onUpdated();
    }
  }

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  Future<void> _launchTel(String tel) async {
    final uri = Uri(scheme: 'tel', path: tel);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchMail(String mail) async {
    final uri = Uri(scheme: 'mailto', path: mail);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final firma = widget.firma;
    final telefon = firma['telefon'] as String? ?? '';
    final mail = firma['mail'] as String? ?? '';
    final ziyaretTarihi = firma['ziyaretTarihi'] as DateTime?;
    final grupId = firma['grupId'] as int?;
    final grupAdi = firma['grupAdi'] as String?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Firma info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.business,
                        color: colors.accent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      firma['isim'] as String,
                      style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _editSheet,
                    icon: Icon(Icons.edit_outlined,
                        color: colors.accent, size: 18),
                    tooltip: "Düzenle",
                  ),
                ],
              ),
              if (telefon.isNotEmpty) ...[
                const Divider(color: Colors.white12, height: 20),
                GestureDetector(
                  onTap: () => _launchTel(telefon),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          color: Colors.blue, size: 16),
                      const SizedBox(width: 8),
                      Text(telefon,
                          style: const TextStyle(
                              color: Colors.blue, fontSize: 14)),
                    ],
                  ),
                ),
              ],
              if (mail.isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _launchMail(mail),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          color: Colors.teal, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(mail,
                            style: const TextStyle(
                                color: Colors.teal, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Grup atama
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Grup",
                  style: TextStyle(
                      color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              _gruplarLoaded
                  ? DropdownButtonFormField<int?>(
                      key: ValueKey(grupId),
                      initialValue: _gruplar.any((g) => g['id'] == grupId)
                          ? grupId
                          : null,
                      dropdownColor: colors.card,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.input,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text("— Grupsuz —")),
                        ..._gruplar.map((g) => DropdownMenuItem<int?>(
                              value: g['id'] as int,
                              child: Text(g['grupAdi'] as String),
                            )),
                      ],
                      onChanged: (v) => _assignGrup(v),
                    )
                  : const SizedBox(
                      height: 48,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Colors.amber, strokeWidth: 2)),
                    ),
              if (grupAdi != null) ...[
                const SizedBox(height: 6),
                Text(
                  "Mevcut: $grupAdi",
                  style: TextStyle(
                      color: colors.accent.withValues(alpha: 0.7),
                      fontSize: 11),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Ziyaret tarihi
        GestureDetector(
          onTap: _pickZiyaretTarihi,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: colors.accent, size: 18),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Son Ziyaret Tarihi",
                        style:
                            TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(
                      ziyaretTarihi != null
                          ? _formatTarih(ziyaretTarihi)
                          : "Belirlenmedi",
                      style: TextStyle(
                        color: ziyaretTarihi != null
                            ? colors.text
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Evrak geçerlilik süreleri
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined,
                      color: colors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Evrak Geçerlilik Süreleri",
                    style: TextStyle(
                        color: colors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Belge ekleme ekranında varsayılan süre olarak kullanılır.",
                style:
                    TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
              const SizedBox(height: 14),
              _gecerlilikRow(
                "Eğitim Sertifikaları",
                Icons.school_outlined,
                Colors.blue,
                _egitimYil,
                [1, 3, 5],
                (v) async {
                  setState(() => _egitimYil = v);
                  await DatabaseService.updateFirmaGecerlilikAyarlari(
                      firma['id'] as int,
                      v,
                      _muayeneYil,
                      _evrakYil);
                },
              ),
              const SizedBox(height: 10),
              _gecerlilikRow(
                "Muayene Formları",
                Icons.medical_services_outlined,
                Colors.green,
                _muayeneYil,
                [1, 3, 5],
                (v) async {
                  setState(() => _muayeneYil = v);
                  await DatabaseService.updateFirmaGecerlilikAyarlari(
                      firma['id'] as int,
                      _egitimYil,
                      v,
                      _evrakYil);
                },
              ),
              const SizedBox(height: 10),
              _gecerlilikRow(
                "Firma Evrakları",
                Icons.folder_outlined,
                Colors.orange,
                _evrakYil,
                [1, 2, 3],
                (v) async {
                  setState(() => _evrakYil = v);
                  await DatabaseService.updateFirmaGecerlilikAyarlari(
                      firma['id'] as int,
                      _egitimYil,
                      _muayeneYil,
                      v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gecerlilikRow(
    String label,
    IconData icon,
    Color color,
    int value,
    List<int> options,
    Future<void> Function(int) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Builder(builder: (context) {
            final colors = AppColors.of(context);
            return Text(
              label,
              style: TextStyle(
                  color: colors.text.withValues(alpha: 0.7), fontSize: 13),
            );
          }),
        ),
        Builder(builder: (context) {
          final colors = AppColors.of(context);
          return DropdownButton<int>(
            value: options.contains(value) ? value : options.first,
            dropdownColor: colors.cardDark,
            underline: const SizedBox(),
            style: TextStyle(
                color: colors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 13),
            items: options
                .map((y) => DropdownMenuItem(
                      value: y,
                      child: Text("$y Yıl"),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          );
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// NOTLAR TAB
// ─────────────────────────────────────────────

class _NotlarTab extends StatelessWidget {
  final int firmaId;
  final List<Map<String, dynamic>> notlar;
  final VoidCallback onChanged;
  const _NotlarTab(
      {required this.firmaId,
      required this.notlar,
      required this.onChanged});

  void _addNotSheet(BuildContext context) {
    final ctrl = TextEditingController();
    final ImagePicker picker = ImagePicker();
    final List<String> fotoPaths = [];
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(builder: (_, setM) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Not Ekle",
                  style: TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Notunuzu yazın...",
                  filled: true,
                  fillColor: colors.input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (fotoPaths.isNotEmpty)
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotoPaths.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(fotoPaths[i]),
                            width: 70, height: 70, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              if (hasCameraSupport)
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        final img = await picker.pickImage(
                            source: ImageSource.camera);
                        if (img != null) {
                          setM(() => fotoPaths.add(img.path));
                        }
                      },
                      icon: const Icon(Icons.camera_alt_outlined,
                          size: 16),
                      label: const Text("Fotoğraf"),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final metin = ctrl.text.trim();
                    if (metin.isEmpty) return;
                    await DatabaseService.insertNot(
                        firmaId, metin, DateTime.now(), fotoPaths);
                    if (ctx.mounted) Navigator.pop(ctx);
                    onChanged();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Kaydet"),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _deleteNot(BuildContext context, Map<String, dynamic> not) {
    final id = not['id'] as int;
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        title: const Text("Notu Sil"),
        content: const Text("Bu not silinsin mi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseService.deleteNot(id);
              if (context.mounted) Navigator.pop(context);
              onChanged();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Not silindi"),
                  action: SnackBarAction(
                    label: "Geri Al",
                    textColor: Colors.amber,
                    onPressed: () async {
                      await DatabaseService.insertNot(
                        firmaId,
                        not['metin'] as String,
                        not['zaman'] as DateTime,
                        List<String>.from(not['fotoPaths'] as List),
                      );
                      onChanged();
                    },
                  ),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1F2937),
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Sil"),
          ),
        ],
      ),
    );
  }

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Expanded(
          child: notlar.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notes, color: Colors.grey[700], size: 48),
                      const SizedBox(height: 12),
                      Text("Henüz not yok",
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: notlar.length,
                  itemBuilder: (_, i) {
                    final n = notlar[i];
                    final zaman = n['zaman'] as DateTime;
                    final fotos =
                        List<String>.from(n['fotoPaths'] as List? ?? []);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                _formatTarih(zaman),
                                style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 11),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => _deleteNot(context, n),
                                child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                    size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n['metin'] as String,
                            style: TextStyle(
                                color: colors.text, fontSize: 14),
                          ),
                          if (fotos.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 64,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: fotos.length,
                                itemBuilder: (_, j) => Padding(
                                  padding:
                                      const EdgeInsets.only(right: 6),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(6),
                                    child: File(fotos[j])
                                            .existsSync()
                                        ? Image.file(
                                            File(fotos[j]),
                                            width: 64,
                                            height: 64,
                                            fit: BoxFit.cover)
                                        : Container(
                                            width: 64,
                                            height: 64,
                                            color: colors.cardDark,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.cardDark,
            border: Border(
                top: BorderSide(color: colors.border)),
          ),
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _addNotSheet(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Not Ekle",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.accent,
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
}

// ─────────────────────────────────────────────
// RAPORLAR TAB
// ─────────────────────────────────────────────

class _RaporlarTab extends StatelessWidget {
  final int firmaId;
  final String firmaAdi;
  final List<GorselRapor> raporlar;
  final VoidCallback onChanged;
  const _RaporlarTab(
      {required this.firmaId,
      required this.firmaAdi,
      required this.raporlar,
      required this.onChanged});

  String _formatTarih(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Stack(
      children: [
        raporlar.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined,
                        color: Colors.grey[700], size: 48),
                    const SizedBox(height: 12),
                    Text("Henüz görsel rapor yok",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 4),
                    Text("Sağ alttaki + ile rapor oluşturun",
                        style: TextStyle(
                            color: Colors.grey[700], fontSize: 12)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount: raporlar.length,
                itemBuilder: (_, i) {
                  final r = raporlar[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RaporDetayPage(rapor: r)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colors.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          if (r.fotoPaths.isNotEmpty &&
                              File(r.fotoPaths.first).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(r.fotoPaths.first),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: colors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.image_outlined,
                                  color: colors.accent, size: 28),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.baslik,
                                    style: TextStyle(
                                        color: colors.text,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(_formatTarih(r.tarih),
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12)),
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
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            backgroundColor: colors.accent,
            foregroundColor: Colors.black,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: colors.card,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => RaporTipiSecSheet(
                  onSecim: (tip) async {
                    Navigator.pop(context);
                    final result = await Navigator.push<GorselRapor>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RaporOlusturPage(
                          firmaAdi: firmaAdi,
                          raporTipi: tip,
                        ),
                      ),
                    );
                    if (result != null) {
                      await DatabaseService.insertGorselRapor(
                        id: result.id,
                        firmaId: firmaId,
                        baslik: result.baslik,
                        rapor: result.rapor,
                        tarih: result.tarih,
                        fotoPaths: result.fotoPaths,
                      );
                      onChanged();
                    }
                  },
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
