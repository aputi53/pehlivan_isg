import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pehlivan_isg/pages/firma_detay_page.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/app_drawer.dart';
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
      drawer: const AppDrawer(currentRoute: 'firmalar'),
      appBar: AppBar(
        backgroundColor: colors.card,
        foregroundColor: colors.text,
        title: const Text("Firmalar",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            padding: const EdgeInsets.only(left: 16),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: "Tümünü Sil",
            onPressed: _deleteAll,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: "CSV Yükle",
            onPressed: _csvImport,
          ),
        ],
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: colors.accent))
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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business_outlined,
                                  color: Colors.grey[700], size: 48),
                              const SizedBox(height: 12),
                              Text(
                                _arama.isEmpty
                                    ? "Henüz firma yok"
                                    : "Sonuç bulunamadı",
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14),
                              ),
                              if (_arama.isEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Sağ alttaki + ile ekleyin",
                                  style: TextStyle(
                                      color: Colors.grey[700], fontSize: 12),
                                ),
                              ],
                            ],
                          ),
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
        onPressed: _addFirmaSheet,
        backgroundColor: colors.accent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}
