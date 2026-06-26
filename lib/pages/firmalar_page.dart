import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pehlivan_isg/pages/firma_detay_page.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_empty_state.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class FirmalarPage extends StatefulWidget {
  const FirmalarPage({super.key});

  @override
  State<FirmalarPage> createState() => _FirmalarPageState();
}

class _FirmalarPageState extends State<FirmalarPage> {
  List<Map<String, dynamic>> _firmalar = [];
  bool _loading = true;
  final _aramaCtrl = TextEditingController();
  String _arama = '';
  String _grupFiltre = 'tumu'; // tumu | gruplu | grupsuz
  String _siralama = 'isimAZ'; // isimAZ | isimZA | grupAZ | grupZA

  @override
  void initState() {
    super.initState();
    _aramaCtrl.addListener(() => setState(() => _arama = _aramaCtrl.text));
    _loadData();
  }

  @override
  void dispose() {
    _aramaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final list = await DatabaseService.getAllFirmalar();
    if (mounted) setState(() { _firmalar = list; _loading = false; });
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_firmalar);

    if (_grupFiltre == 'gruplu') {
      list = list.where((f) => f['grupId'] != null).toList();
    } else if (_grupFiltre == 'grupsuz') {
      list = list.where((f) => f['grupId'] == null).toList();
    }

    if (_arama.isNotEmpty) {
      final q = _arama.toLowerCase();
      list = list.where((f) {
        final isim = (f['isim'] as String).toLowerCase();
        final grup = (f['grupAdi'] as String? ?? '').toLowerCase();
        return isim.contains(q) || grup.contains(q);
      }).toList();
    }

    list.sort((a, b) {
      switch (_siralama) {
        case 'isimZA':
          return (b['isim'] as String)
              .toLowerCase()
              .compareTo((a['isim'] as String).toLowerCase());
        case 'grupAZ':
          final ga = (a['grupAdi'] as String? ?? '').toLowerCase();
          final gb = (b['grupAdi'] as String? ?? '').toLowerCase();
          return ga.compareTo(gb);
        case 'grupZA':
          final ga = (a['grupAdi'] as String? ?? '').toLowerCase();
          final gb = (b['grupAdi'] as String? ?? '').toLowerCase();
          return gb.compareTo(ga);
        default: // isimAZ
          return (a['isim'] as String)
              .toLowerCase()
              .compareTo((b['isim'] as String).toLowerCase());
      }
    });

    return list;
  }

  Future<void> _addFirmaSheet() async {
    final isimCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final mailCtrl = TextEditingController();
    int? secilenGrupId;

    final gruplar = await DatabaseService.getGruplarSimple();
    if (!mounted) return;

    final colors = AppColors.of(context);
    await showModalBottomSheet(
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
              const Text("Yeni Firma Ekle",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _inputField(isimCtrl, "Firma Adı *"),
              const SizedBox(height: 10),
              _inputField(telCtrl, "Telefon", keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              _inputField(mailCtrl, "E-posta", keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              DropdownButtonFormField<int?>(
                initialValue: secilenGrupId,
                dropdownColor: colors.card,
                decoration: InputDecoration(
                  labelText: "Grup (opsiyonel)",
                  filled: true,
                  fillColor: colors.input,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text("— Grupsuz —")),
                  ...gruplar.map((g) => DropdownMenuItem<int?>(
                    value: g['id'] as int,
                    child: Text(g['grupAdi'] as String),
                  )),
                ],
                onChanged: (v) => setM(() => secilenGrupId = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final isim = isimCtrl.text.trim();
                    if (isim.isEmpty) return;
                    final id = await DatabaseService.insertFirmaStandalone(
                      isim, telCtrl.text.trim(), mailCtrl.text.trim(),
                    );
                    if (secilenGrupId != null) {
                      await DatabaseService.assignFirmaToGrup(id, secilenGrupId);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accent,
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
          );
        }),
      ),
    );
  }

  Future<void> _deleteAll() async {
    final colors = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text("Tüm Firmaları Sil",
            style: TextStyle(color: colors.text)),
        content: Text(
            "Tüm firmalar ve bağlı veriler (notlar, görseller, belgeler) silinecek. Devam edilsin mi?",
            style: TextStyle(color: colors.text.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text("İptal",
                  style: TextStyle(color: colors.text.withValues(alpha: 0.54)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Sil",
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await DatabaseService.deleteAllFirmalar();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Tüm firmalar silindi"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1F2937),
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _firmaMenu(Map<String, dynamic> f) {
    final colors = AppColors.of(context);
    final isim = f['isim'] as String;
    final telefon = (f['telefon'] as String? ?? '').trim();
    final mail = (f['mail'] as String? ?? '').trim();
    final firmaId = f['id'] as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.business, color: colors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(isim,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: colors.border, height: 1),
            if (telefon.isNotEmpty)
              _menuTile(Icons.phone_outlined, 'Ara', colors.accent, () {
                Navigator.pop(context);
                launchUrl(Uri(scheme: 'tel', path: telefon));
              }),
            if (mail.isNotEmpty)
              _menuTile(Icons.email_outlined, 'Mail Gönder', colors.accent, () {
                Navigator.pop(context);
                launchUrl(Uri(scheme: 'mailto', path: mail));
              }),
            if (telefon.isNotEmpty)
              _menuTile(Icons.chat_outlined, 'WhatsApp Mesaj', const Color(0xFF25D366), () {
                Navigator.pop(context);
                final num = telefon.replaceAll(RegExp(r'[^\d+]'), '');
                launchUrl(Uri.parse('https://wa.me/$num'),
                    mode: LaunchMode.externalApplication);
              }),
            _menuTile(Icons.attach_file_outlined, 'Belge Gönder', colors.accent, () async {
              Navigator.pop(context);
              final r = await FilePicker.platform.pickFiles(allowMultiple: false);
              if (r != null && r.files.first.path != null) {
                await Share.shareXFiles([XFile(r.files.first.path!)]);
              }
            }),
            if (telefon.isNotEmpty)
              _menuTile(Icons.copy_outlined, 'Telefonu Kopyala', colors.textMuted, () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: telefon));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('$telefon kopyalandı'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: colors.card,
                ));
              }),
            Divider(color: colors.border, height: 1),
            _menuTile(Icons.delete_outline, 'Sil', Colors.redAccent, () async {
              Navigator.pop(context);
              final onay = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: colors.card,
                  title: Text('Firmayı Sil', style: TextStyle(color: colors.text)),
                  content: Text('$isim silinecek. Devam edilsin mi?',
                      style: TextStyle(color: colors.textMuted)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('İptal', style: TextStyle(color: colors.textMuted))),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Sil', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
              if (onay != true) return;

              final grupId = f['grupId'] as int?;
              final savedTelefon = (f['telefon'] as String? ?? '');
              final savedMail = (f['mail'] as String? ?? '');

              await DatabaseService.deleteFirma(firmaId);
              await _loadData();

              if (!mounted) return;
              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$isim silindi'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 5),
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 72),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  backgroundColor: colors.cardDark,
                  action: SnackBarAction(
                    label: 'Geri Al',
                    textColor: colors.accent,
                    onPressed: () async {
                      if (grupId != null) {
                        await DatabaseService.insertFirma(
                            grupId, isim, savedTelefon, savedMail);
                      } else {
                        await DatabaseService.insertFirmaStandalone(
                            isim, savedTelefon, savedMail);
                      }
                      await _loadData();
                    },
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, Color color, VoidCallback onTap) {
    final colors = AppColors.of(context);
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(label, style: TextStyle(color: colors.text, fontSize: 14)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }

  Future<void> _isgKatipImport() async {
    if (!mounted) return;
    // Önce seçenek sun: Excel toplu veya tek firma güncelle
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _IsgKatipSecenekSheet(
        onExcel: () async {
          await _isgKatipExcelImport();
        },
        onTekFirma: () async {
          if (!mounted) return;
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _IsgKatipImportSheet(
              firmalar: _firmalar,
              onKayit: () => _loadData(),
            ),
          );
        },
      ),
    );
  }

  // Excel/CSV'yi parse eder → uzman seçim ekranı gösterir → seçilen uzmanların firmalarını aktar
  Future<void> _isgKatipExcelImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
    );
    if (result == null || result.files.single.path == null) return;
    if (!mounted) return;

    final path = result.files.single.path!;
    final ext = path.toLowerCase().split('.').last;
    List<List<String>> tumSatirlar = [];

    try {
      if (ext == 'csv' || ext == 'txt') {
        final bytes = File(path).readAsBytesSync();
        String content;
        try { content = utf8.decode(bytes); } catch (_) { content = latin1.decode(bytes); }
        if (content.startsWith('﻿')) content = content.substring(1);
        final lines = content.split('\n').map((l) => l.trimRight()).toList();
        final sep = lines.first.contains(';') ? ';' : ',';
        for (int i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = line.split(sep).map((c) => c.replaceAll('"', '').trim()).toList();
          if (cols.isNotEmpty && cols[0].isNotEmpty) tumSatirlar.add(cols);
        }
      } else {
        final rawBytes = File(path).readAsBytesSync();
        final bytes = _patchXlsxStyles(rawBytes);
        final excel = Excel.decodeBytes(bytes);
        final sheetNames = excel.tables.keys.toList();
        if (sheetNames.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Excel dosyasında sayfa bulunamadı')),
            );
          }
          return;
        }
        final sheet = excel.tables[sheetNames.first];
        if (sheet == null) return;
        final rows = sheet.rows;
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.isEmpty) continue;
          final cols = row.map((c) {
            final v = c?.value;
            if (v == null) return '';
            return v.toString().trim();
          }).toList();
          if (cols.isNotEmpty && cols[0].isNotEmpty) tumSatirlar.add(cols);
        }
      }
    } catch (e, st) {
      debugPrint('KATIP_IMPORT_ERROR: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dosya okunurken hata: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    if (tumSatirlar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dosyada veri bulunamadı')),
        );
      }
      return;
    }

    // Benzersiz uzmanları çıkar (col[3] = uzman isim, col[4] = belge no)
    final Map<String, List<List<String>>> uzmanMap = {};
    for (final cols in tumSatirlar) {
      final uzmanIsim = cols.length > 3 ? cols[3].trim() : '';
      final key = uzmanIsim.isEmpty ? '(Uzman Belirtilmemiş)' : uzmanIsim;
      uzmanMap.putIfAbsent(key, () => []).add(cols);
    }

    if (!mounted) return;

    // Uzman seçim sheet'ini göster
    final secilen = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UzmanSecimSheet(uzmanMap: uzmanMap),
    );

    if (secilen == null || secilen.isEmpty || !mounted) return;

    // Seçilen uzmanların satırlarını topla
    final aktarilacak = <List<String>>[];
    for (final uzman in secilen) {
      aktarilacak.addAll(uzmanMap[uzman] ?? []);
    }

    int added = 0;
    int updated = 0;
    for (final cols in aktarilacak) {
      final r = await _katipRowImport(cols);
      if (r == 'added') added++;
      else if (r == 'updated') updated++;
    }

    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$added firma eklendi, $updated firma güncellendi'),
          backgroundColor: const Color(0xFF1F2937),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // SGK sicil no öncelikli firma eşleşmesi ile ISG-Katip satırını DB'ye kaydeder.
  // Sütun sırası: 0=firma isim, 1=SGK no, 2=tehlike sınıfı, 3=uzman isim,
  //   4=uzman belge no, 5=hekim isim, 6=hekim belge no, 7=sertifika no,
  //   8=telefon, 9=mail
  Future<String> _katipRowImport(List<String> cols) async {
    final isim = cols[0].trim();
    if (isim.isEmpty) return 'skip';

    final sgkNo = cols.length > 1 ? cols[1].trim() : '';
    final tehlikeSinifi = cols.length > 2 ? cols[2].trim() : '';
    final uzmanIsim = cols.length > 3 ? cols[3].trim() : '';
    final uzmanBelgeNo = cols.length > 4 ? cols[4].trim() : '';
    final hekimIsim = cols.length > 5 ? cols[5].trim() : '';
    final hekimBelgeNo = cols.length > 6 ? cols[6].trim() : '';
    final katipSertNo = cols.length > 7 ? cols[7].trim() : '';
    final telefon = cols.length > 8 ? cols[8].trim() : '';
    final mail = cols.length > 9 ? cols[9].trim() : '';

    // 1. Önce SGK sicil no ile eşleştir (güvenilir kimlik)
    Map<String, dynamic>? mevcut;
    if (sgkNo.isNotEmpty) {
      mevcut = await DatabaseService.getFirmaBySgkNo(sgkNo);
    }
    // 2. SGK bulunamazsa isimle dene (yedek)
    if (mevcut == null) {
      mevcut = _firmalar.where((f) =>
          (f['isim'] as String).toLowerCase().trim() ==
          isim.toLowerCase()).firstOrNull;
    }

    if (mevcut != null) {
      await DatabaseService.updateFirmaKatipBilgi(
        mevcut['id'] as int,
        sgkNo: sgkNo.isNotEmpty ? sgkNo : null,
        tehlikeSinifi: tehlikeSinifi.isNotEmpty ? tehlikeSinifi : null,
        uzmanIsim: uzmanIsim.isNotEmpty ? uzmanIsim : null,
        uzmanBelgeNo: uzmanBelgeNo.isNotEmpty ? uzmanBelgeNo : null,
        hekimIsim: hekimIsim.isNotEmpty ? hekimIsim : null,
        hekimBelgeNo: hekimBelgeNo.isNotEmpty ? hekimBelgeNo : null,
        katipSertifikaNo: katipSertNo.isNotEmpty ? katipSertNo : null,
      );
      return 'updated';
    } else {
      final firmaId = await DatabaseService.insertFirmaStandalone(isim, telefon, mail);
      await DatabaseService.updateFirmaKatipBilgi(
        firmaId,
        sgkNo: sgkNo.isNotEmpty ? sgkNo : null,
        tehlikeSinifi: tehlikeSinifi.isNotEmpty ? tehlikeSinifi : null,
        uzmanIsim: uzmanIsim.isNotEmpty ? uzmanIsim : null,
        uzmanBelgeNo: uzmanBelgeNo.isNotEmpty ? uzmanBelgeNo : null,
        hekimIsim: hekimIsim.isNotEmpty ? hekimIsim : null,
        hekimBelgeNo: hekimBelgeNo.isNotEmpty ? hekimBelgeNo : null,
        katipSertifikaNo: katipSertNo.isNotEmpty ? katipSertNo : null,
      );
      return 'added';
    }
  }

  Future<void> _csvImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result == null || result.files.single.path == null) return;

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }
      // Strip UTF-8 BOM if present
      if (content.startsWith('﻿')) content = content.substring(1);

      final lines =
          content.split('\n').map((l) => l.trimRight()).toList();
      if (lines.isEmpty) return;

      // Detect separator: semicolon (Turkish Excel) or comma
      final sep =
          lines.first.contains(';') ? ';' : ',';

      // Skip header if first column starts with a letter
      final firstCol = lines.first.split(sep).first.trim();
      final start =
          firstCol.isEmpty || RegExp(r'^[A-Za-zÇĞİÖŞÜçğışöşü]').hasMatch(firstCol)
              ? 1
              : 0;

      int added = 0;
      final gruplar = await DatabaseService.getGruplarSimple();

      for (int i = start; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final cols = line.split(sep).map((c) => c.trim()).toList();
        if (cols.isEmpty || cols[0].isEmpty) continue;

        final isim = cols[0];
        final telefon = cols.length > 1 ? cols[1] : '';
        final mail = cols.length > 2 ? cols[2] : '';
        final grupAdi =
            cols.length > 3 && cols[3].isNotEmpty ? cols[3] : null;

        final firmaId =
            await DatabaseService.insertFirmaStandalone(isim, telefon, mail);

        if (grupAdi != null) {
          final match = gruplar
              .where((g) =>
                  (g['grupAdi'] as String).toLowerCase() ==
                  grupAdi.toLowerCase())
              .firstOrNull;
          if (match != null) {
            await DatabaseService.assignFirmaToGrup(
                firmaId, match['id'] as int);
          }
        }
        added++;
      }

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$added firma yüklendi"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1F2937),
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Dosya okunamadı: $e"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade800,
            margin: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _grupFiltreChip(String label, String value, AppColors colors) {
    final selected = _grupFiltre == value;
    return GestureDetector(
      onTap: () => setState(() => _grupFiltre = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? colors.accent.withValues(alpha: 0.15)
              : colors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colors.accent.withValues(alpha: 0.6)
                : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.accent : colors.textMuted,
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortMenuItem(String value, String label) {
    final selected = _siralama == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: 16,
            color: selected ? Colors.amber : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
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

  Color _durumRenk(String durum) {
    switch (durum) {
      case 'GİDİLDİ':
        return Colors.green;
      case 'GİDİLMEDİ':
        return Colors.red;
      case 'KİMSE_YOK':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _durumLabel(String durum) {
    switch (durum) {
      case 'GİDİLDİ':
        return 'Gidildi';
      case 'GİDİLMEDİ':
        return 'Gidilmedi';
      case 'KİMSE_YOK':
        return 'Kimse Yok';
      default:
        return 'Normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        automaticallyImplyLeading: false,
        title: Text(
          "Firmalar",
          style: GoogleFonts.outfit(
            color: colors.text,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_outlined,
                color: Color(0xFF4FC3F7)),
            tooltip: "ISG-Katip Aktar",
            onPressed: _isgKatipImport,
          ),
          IconButton(
            icon: Icon(Icons.upload_file_outlined, color: colors.textMuted),
            tooltip: "CSV Yükle",
            onPressed: _csvImport,
          ),
          IconButton(
            icon: Icon(Icons.delete_sweep_outlined, color: colors.textMuted),
            tooltip: "Tümünü Sil",
            onPressed: _deleteAll,
          ),
        ],
      ),
      body: _loading
          ? const AppShimmerList(itemCount: 6)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: TextField(
                    controller: _aramaCtrl,
                    decoration: InputDecoration(
                      hintText: "Firma veya grup adı ara...",
                      prefixIcon:
                          Icon(Icons.search, color: colors.accent),
                      filled: true,
                      fillColor: colors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 8, 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                            _grupFiltreChip('Tümü', 'tumu', colors),
                            const SizedBox(width: 8),
                            _grupFiltreChip('Gruplu', 'gruplu', colors),
                            const SizedBox(width: 8),
                            _grupFiltreChip('Grupsuz', 'grupsuz', colors),
                          ]),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.sort, color: colors.accent, size: 20),
                        tooltip: 'Sırala',
                        color: colors.card,
                        onSelected: (v) => setState(() => _siralama = v),
                        itemBuilder: (_) => [
                          _sortMenuItem('isimAZ', 'İsim A → Z'),
                          _sortMenuItem('isimZA', 'İsim Z → A'),
                          _sortMenuItem('grupAZ', 'Grup A → Z'),
                          _sortMenuItem('grupZA', 'Grup Z → A'),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: Text(
                    "${filtered.length} firma",
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? AppEmptyState(
                          icon: _arama.isEmpty
                              ? Icons.business_outlined
                              : Icons.search_off_rounded,
                          title: _arama.isEmpty
                              ? 'Henüz firma yok'
                              : 'Sonuç bulunamadı',
                          subtitle: _arama.isEmpty
                              ? 'Sağ alttaki + butonuna basarak\nilk firmanızı ekleyin'
                              : '"$_arama" ile eşleşen firma bulunamadı',
                          iconColor: _arama.isEmpty ? null : Colors.orange,
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 80),
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final f = filtered[i];
                            final durum =
                                f['durum'] as String? ?? 'NORMAL';
                            final grupAdi = f['grupAdi'] as String?;
                            final telefon =
                                f['telefon'] as String? ?? '';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: colors.border),
                              ),
                              child: ListTile(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FirmaDetayPage(
                                        firmaId: f['id'] as int,
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                                onLongPress: () => _firmaMenu(f),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 4),
                                leading: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: colors.accent
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.business,
                                      color: colors.accent, size: 22),
                                ),
                                title: Text(
                                  f['isim'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      grupAdi ?? 'Grup Yok',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: grupAdi != null
                                            ? colors.accent
                                                .withValues(alpha: 0.75)
                                            : Colors.grey[600],
                                        fontSize: 11,
                                        fontStyle: grupAdi == null
                                            ? FontStyle.italic
                                            : FontStyle.normal,
                                      ),
                                    ),
                                    if (telefon.isNotEmpty)
                                      Text(
                                        telefon,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 11),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _durumRenk(durum)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: _durumRenk(durum)
                                                .withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        _durumLabel(durum),
                                        style: TextStyle(
                                            color: _durumRenk(durum),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.more_vert,
                                        color: colors.textMuted
                                            .withValues(alpha: 0.4),
                                        size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'firmalar_fab',
        onPressed: _addFirmaSheet,
        backgroundColor: colors.accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// xlsx dosyasındaki styles.xml'den numFmtId < 164 olan custom numFmt
// girdilerini kaldırır (ISG-Katip Excel'inin hatalı numFmt kayıtlarını düzeltir).
Uint8List _patchXlsxStyles(List<int> bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final encoder = ZipEncoder();
    final newArchive = Archive();

    for (final file in archive) {
      if (file.isFile && file.name == 'xl/styles.xml') {
        var content = utf8.decode(file.content as List<int>, allowMalformed: true);
        // numFmtId="0" ... numFmtId="163" olan custom <numFmt .../> satırlarını kaldır
        content = content.replaceAllMapped(
          RegExp(r'<numFmt[^>]+numFmtId="(\d+)"[^/]*/>', caseSensitive: false),
          (m) {
            final id = int.tryParse(m.group(1) ?? '') ?? 999;
            return id < 164 ? '' : m.group(0)!;
          },
        );
        final patched = utf8.encode(content);
        newArchive.addFile(
          ArchiveFile(file.name, patched.length, patched),
        );
      } else {
        newArchive.addFile(file);
      }
    }

    final encoded = encoder.encode(newArchive);
    if (encoded == null) return Uint8List.fromList(bytes);
    return Uint8List.fromList(encoded);
  } catch (_) {
    return Uint8List.fromList(bytes);
  }
}

// ─── Uzman Seçim Sheet ───────────────────────────────────────────────────────

class _UzmanSecimSheet extends StatefulWidget {
  final Map<String, List<List<String>>> uzmanMap;
  const _UzmanSecimSheet({required this.uzmanMap});

  @override
  State<_UzmanSecimSheet> createState() => _UzmanSecimSheetState();
}

class _UzmanSecimSheetState extends State<_UzmanSecimSheet> {
  late Set<String> _secilen;

  @override
  void initState() {
    super.initState();
    _secilen = Set.from(widget.uzmanMap.keys);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final uzmanlar = widget.uzmanMap.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Uzman Seç',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, color: c.text, fontSize: 16)),
                Text(
                    '${uzmanlar.length} uzman bulundu — aktarmak istediklerinizi seçin',
                    style: GoogleFonts.inter(fontSize: 11, color: c.textMuted)),
              ]),
            ),
            TextButton(
              onPressed: () => setState(() {
                if (_secilen.length == uzmanlar.length) {
                  _secilen.clear();
                } else {
                  _secilen = Set.from(uzmanlar);
                }
              }),
              child: Text(
                _secilen.length == uzmanlar.length ? 'Hiçbirini Seçme' : 'Hepsini Seç',
                style: GoogleFonts.inter(
                    fontSize: 12, color: const Color(0xFF4FC3F7)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uzmanlar.map((uzman) {
                  final secili = _secilen.contains(uzman);
                  final firmaAdet = widget.uzmanMap[uzman]?.length ?? 0;
                  return FilterChip(
                    selected: secili,
                    onSelected: (v) => setState(() {
                      if (v) _secilen.add(uzman); else _secilen.remove(uzman);
                    }),
                    label: Text(
                      '$uzman ($firmaAdet firma)',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                    selectedColor: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF4FC3F7),
                    backgroundColor: c.bg,
                    side: BorderSide(
                      color: secili ? const Color(0xFF4FC3F7) : c.border,
                    ),
                    labelStyle: GoogleFonts.inter(
                      color: secili ? const Color(0xFF4FC3F7) : c.textMuted,
                      fontWeight:
                          secili ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _secilen.isEmpty
                  ? null
                  : () => Navigator.pop(context, _secilen.toList()),
              icon: const Icon(Icons.download_rounded),
              label: Text(
                _secilen.isEmpty
                    ? 'Uzman Seçin'
                    : '${_secilen.fold(0, (s, k) => s + (widget.uzmanMap[k]?.length ?? 0))} firma aktar',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                foregroundColor: Colors.black,
                disabledBackgroundColor:
                    const Color(0xFF4FC3F7).withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ISG-Katip Seçenek Sheet ─────────────────────────────────────────────────

class _IsgKatipSecenekSheet extends StatelessWidget {
  final VoidCallback onExcel;
  final VoidCallback onTekFirma;
  const _IsgKatipSecenekSheet(
      {required this.onExcel, required this.onTekFirma});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.account_balance_outlined,
                color: Color(0xFF4FC3F7), size: 20),
            const SizedBox(width: 8),
            Text('ISG-Katip\'ten Aktar',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: c.text,
                    fontSize: 16)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close_rounded, color: c.textMuted),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Veri aktarma yöntemini seçin',
              style:
                  GoogleFonts.inter(fontSize: 12, color: c.textMuted)),
          const SizedBox(height: 20),
          _option(
            context,
            icon: Icons.upload_file_outlined,
            color: const Color(0xFF4FC3F7),
            title: 'Excel ile Toplu Aktar',
            subtitle:
                'ISG-Katip\'ten indirdiğiniz Excel dosyasını yükleyin',
            onTap: onExcel,
          ),
          const SizedBox(height: 12),
          _option(
            context,
            icon: Icons.edit_outlined,
            color: const Color(0xFFE8B84B),
            title: 'Tek Firma Güncelle',
            subtitle: 'Mevcut bir firmanın bilgilerini manuel girin',
            onTap: onTekFirma,
          ),
        ],
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return Material(
      color: c.bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: c.text,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 11, color: c.textMuted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: c.textMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}

// ─── ISG-Katip Import Sheet ──────────────────────────────────────────────────

class _IsgKatipImportSheet extends StatefulWidget {
  final List<Map<String, dynamic>> firmalar;
  final VoidCallback onKayit;
  const _IsgKatipImportSheet(
      {required this.firmalar, required this.onKayit});

  @override
  State<_IsgKatipImportSheet> createState() => _IsgKatipImportSheetState();
}

class _IsgKatipImportSheetState extends State<_IsgKatipImportSheet> {
  int? _firmaId;
  String? _tehlikeSinifi;
  final _sgkNo = TextEditingController();
  final _uzmanIsim = TextEditingController();
  final _uzmanUnvan = TextEditingController();
  final _uzmanBelgeNo = TextEditingController();
  final _hekimIsim = TextEditingController();
  final _hekimUnvan = TextEditingController();
  final _hekimBelgeNo = TextEditingController();
  final _katipSertNo = TextEditingController();
  bool _saving = false;

  static const _tehlikeler = ['AZ TEHLİKELİ', 'TEHLİKELİ', 'ÇOK TEHLİKELİ'];

  @override
  void dispose() {
    _sgkNo.dispose();
    _uzmanIsim.dispose();
    _uzmanUnvan.dispose();
    _uzmanBelgeNo.dispose();
    _hekimIsim.dispose();
    _hekimUnvan.dispose();
    _hekimBelgeNo.dispose();
    _katipSertNo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    InputDecoration dec(String label) => InputDecoration(
          labelText: label,
          labelStyle:
              GoogleFonts.inter(fontSize: 12, color: c.textMuted),
          filled: true,
          fillColor: c.bg,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: c.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF4FC3F7))),
        );

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ISG-Katip\'ten Aktar',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: c.text,
                              fontSize: 16)),
                      Text(
                          'Firmaya ait uzman, hekim ve sertifika bilgilerini girin',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: c.textMuted)),
                    ]),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: c.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _firmaId,
              dropdownColor: c.card,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              hint: Text('Firma seçin *',
                  style: GoogleFonts.inter(
                      color: c.textMuted, fontSize: 13)),
              decoration: dec('Firma'),
              items: widget.firmalar
                  .map((f) => DropdownMenuItem<int>(
                        value: f['id'] as int,
                        child: Text(f['isim'] as String,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: c.text)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  final firma = widget.firmalar.firstWhere((f) => f['id'] == v);
                  final ts = (firma['tehlikeSinifi'] as String?) ?? '';
                  setState(() {
                    _firmaId = v;
                    _tehlikeSinifi = _tehlikeler.contains(ts) ? ts : null;
                  });
                  _sgkNo.text = (firma['sgkNo'] as String?) ?? '';
                  _uzmanIsim.text = (firma['uzmanIsim'] as String?) ?? '';
                  _uzmanUnvan.text = (firma['uzmanUnvan'] as String?) ?? '';
                  _uzmanBelgeNo.text = (firma['uzmanBelgeNo'] as String?) ?? '';
                  _hekimIsim.text = (firma['hekimIsim'] as String?) ?? '';
                  _hekimUnvan.text = (firma['hekimUnvan'] as String?) ?? '';
                  _hekimBelgeNo.text = (firma['hekimBelgeNo'] as String?) ?? '';
                  _katipSertNo.text = (firma['katipSertifikaNo'] as String?) ?? '';
                } else {
                  setState(() => _firmaId = null);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sgkNo,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              decoration: dec('SGK İşyeri Sicil No'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tehlikeSinifi,
              dropdownColor: c.card,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              hint: Text('Tehlike Sınıfı',
                  style: GoogleFonts.inter(color: c.textMuted, fontSize: 13)),
              decoration: dec('Tehlike Sınıfı'),
              items: _tehlikeler
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t,
                            style: GoogleFonts.inter(
                                fontSize: 13, color: c.text)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _tehlikeSinifi = v),
            ),
            const Divider(height: 24),
            Text('İŞ GÜVENLİĞİ UZMANI',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE8B84B),
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _uzmanIsim,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              decoration: dec('Uzman Ad Soyad'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _uzmanUnvan,
                  style: GoogleFonts.inter(color: c.text, fontSize: 13),
                  decoration: dec('Sınıf'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _uzmanBelgeNo,
                  style: GoogleFonts.inter(color: c.text, fontSize: 13),
                  decoration: dec('Belge No'),
                ),
              ),
            ]),
            const Divider(height: 24),
            Text('İŞYERİ HEKİMİ',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4FC3F7),
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _hekimIsim,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              decoration: dec('Hekim Ad Soyad'),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  controller: _hekimUnvan,
                  style: GoogleFonts.inter(color: c.text, fontSize: 13),
                  decoration: dec('Unvan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _hekimBelgeNo,
                  style: GoogleFonts.inter(color: c.text, fontSize: 13),
                  decoration: dec('Belge No'),
                ),
              ),
            ]),
            const Divider(height: 24),
            Text('SERTİFİKA / SÖZLEŞME',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _katipSertNo,
              style: GoogleFonts.inter(color: c.text, fontSize: 13),
              decoration: dec('Katip Sertifika / Sözleşme No'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        if (_firmaId == null) return;
                        setState(() => _saving = true);
                        await DatabaseService.updateFirmaKatipBilgi(
                          _firmaId!,
                          sgkNo: _sgkNo.text.trim().isEmpty
                              ? null
                              : _sgkNo.text.trim(),
                          tehlikeSinifi: _tehlikeSinifi,
                          uzmanIsim: _uzmanIsim.text.trim().isEmpty
                              ? null
                              : _uzmanIsim.text.trim(),
                          uzmanUnvan: _uzmanUnvan.text.trim().isEmpty
                              ? null
                              : _uzmanUnvan.text.trim(),
                          uzmanBelgeNo: _uzmanBelgeNo.text.trim().isEmpty
                              ? null
                              : _uzmanBelgeNo.text.trim(),
                          hekimIsim: _hekimIsim.text.trim().isEmpty
                              ? null
                              : _hekimIsim.text.trim(),
                          hekimUnvan: _hekimUnvan.text.trim().isEmpty
                              ? null
                              : _hekimUnvan.text.trim(),
                          hekimBelgeNo: _hekimBelgeNo.text.trim().isEmpty
                              ? null
                              : _hekimBelgeNo.text.trim(),
                          katipSertifikaNo: _katipSertNo.text.trim().isEmpty
                              ? null
                              : _katipSertNo.text.trim(),
                        );
                        widget.onKayit();
                        if (mounted) Navigator.pop(context);
                      },
                icon: const Icon(Icons.save_rounded),
                label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
