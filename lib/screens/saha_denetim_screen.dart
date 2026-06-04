import 'dart:io';
import 'package:pehlivan_isg/pages/gorsel_rapor_page.dart';
import 'package:pehlivan_isg/utils/platform_utils.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';
import 'package:pehlivan_isg/widgets/belgeler_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/*
   SAHA DENETİM EKRANI
   ====================================================
*/
class SahaDenetimScreen extends StatefulWidget {
  const SahaDenetimScreen({super.key});

  @override
  State<SahaDenetimScreen> createState() => _SahaDenetimScreenState();
}

class _SahaDenetimScreenState extends State<SahaDenetimScreen> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  List<Map<String, dynamic>> gruplar = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final dbGruplar = await DatabaseService.getGruplar();
    final converted = dbGruplar.map((g) {
      final firmalar = (g['firmalar'] as List<Map<String, dynamic>>).map((f) {
        final dbNotlar = (f['notlar'] as List<Map<String, dynamic>>)
            .map((n) => FirmaNot(
                  id: n['id'] as int,
                  metin: n['metin'] as String,
                  zaman: n['zaman'] as DateTime,
                  fotoPaths: List<String>.from(n['fotoPaths']),
                ))
            .toList();
        final dbRaporlar = (f['raporlar'] as List<Map<String, dynamic>>)
            .map((r) => GorselRapor(
                  id: r['id'] as String,
                  tarih: r['tarih'] as DateTime,
                  fotoPaths: List<String>.from(r['fotoPaths']),
                  baslik: r['baslik'] as String,
                  rapor: r['rapor'] as String,
                  firmaAdi: f['isim'] as String? ?? '',
                ))
            .toList();
        return {
          'id': f['id'],
          'grupId': f['grupId'],
          'isim': f['isim'],
          'telefon': f['telefon'] ?? '',
          'mail': f['mail'] ?? '',
          'durum': f['durum'],
          'notlar': dbNotlar,
          'raporlar': dbRaporlar,
          'belgeler': f['belgeler'],
        };
      }).toList();
      return {
        'id': g['id'],
        'grupAdi': g['grupAdi'],
        'tarih': g['tarih'],
        'firmalar': firmalar,
      };
    }).toList();

    if (mounted) setState(() { gruplar = converted; _loading = false; });
  }

  void yeniGrupEklePopup() {
    final grupAdController = TextEditingController();
    final DateTime secilenTarih = DateTime.now();
    final colors = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        title: Text("Yeni Denetim Grubu",
            style: TextStyle(color: colors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: grupAdController,
              style: TextStyle(color: colors.text),
              decoration: const InputDecoration(
                  hintText: "Grup Adı",
                  hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İPTAL")),
          ElevatedButton(
            onPressed: () async {
              if (grupAdController.text.isNotEmpty) {
                final id = await DatabaseService.insertGrup(
                    grupAdController.text, secilenTarih);
                setState(() {
                  gruplar.add({
                    "id": id,
                    "grupAdi": grupAdController.text,
                    "tarih": secilenTarih,
                    "firmalar": [],
                  });
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("OLUŞTUR"),
          ),
        ],
      ),
    );
  }

  void yeniFirmaEklePopup(int grupIndex) async {
    final allFirmalar = await DatabaseService.getAllFirmalar();
    if (!mounted) return;

    final targetGrupId = gruplar[grupIndex]["id"] as int;
    final targetGrupAdi = gruplar[grupIndex]["grupAdi"] as String;
    final colors = AppColors.of(context);

    String mode = 'picker';
    String arama = '';
    final aramaCtrl = TextEditingController();
    final adCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final mailCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setM) {
        final filtered = allFirmalar.where((f) {
          if (arama.isEmpty) return true;
          final q = arama.toLowerCase();
          return (f['isim'] as String).toLowerCase().contains(q) ||
              (f['grupAdi'] as String? ?? '').toLowerCase().contains(q);
        }).toList();

        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.82,
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(
                  child: Text(
                    mode == 'picker' ? 'Gruba Firma Ekle' : 'Yeni Firma Oluştur',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: colors.text),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setM(() => mode = mode == 'picker' ? 'yeni' : 'picker'),
                  icon: Icon(mode == 'picker' ? Icons.add : Icons.list,
                      size: 16, color: colors.accent),
                  label: Text(
                    mode == 'picker' ? 'Yeni' : 'Listeden',
                    style: TextStyle(color: colors.accent, fontSize: 13),
                  ),
                ),
              ]),
            ),
            const Divider(height: 16),

            if (mode == 'picker') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: aramaCtrl,
                  style: TextStyle(color: colors.text),
                  decoration: InputDecoration(
                    hintText: 'Firma adı veya grup ara...',
                    hintStyle: TextStyle(color: colors.textMuted),
                    prefixIcon:
                        Icon(Icons.search, color: colors.accent, size: 20),
                    filled: true,
                    fillColor: colors.card,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (v) => setM(() => arama = v),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text('Kayıtlı firma bulunamadı',
                            style: TextStyle(color: colors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final f = filtered[i];
                          final firmaGrupId = f['grupId'] as int?;
                          final firmaGrupAdi = f['grupAdi'] as String?;
                          final isThisGroup = firmaGrupId == targetGrupId;
                          final isOtherGroup =
                              firmaGrupId != null && !isThisGroup;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isThisGroup
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : colors.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isThisGroup
                                    ? Icons.check_circle
                                    : Icons.business,
                                color: isThisGroup
                                    ? Colors.green
                                    : colors.accent,
                                size: 20,
                              ),
                            ),
                            title: Text(f['isim'] as String,
                                style: TextStyle(
                                    color: isThisGroup
                                        ? Colors.green
                                        : colors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(
                              isThisGroup
                                  ? 'Bu grupta'
                                  : (firmaGrupAdi != null
                                      ? firmaGrupAdi
                                      : 'Grupsuz'),
                              style: TextStyle(
                                color: isThisGroup
                                    ? Colors.green.withValues(alpha: 0.7)
                                    : (isOtherGroup
                                        ? Colors.orange.withValues(alpha: 0.9)
                                        : colors.textMuted),
                                fontSize: 12,
                              ),
                            ),
                            trailing: isOtherGroup
                                ? Icon(Icons.swap_horiz,
                                    color:
                                        Colors.orange.withValues(alpha: 0.7),
                                    size: 18)
                                : (isThisGroup
                                    ? null
                                    : Icon(Icons.add_circle_outline,
                                        color: colors.accent
                                            .withValues(alpha: 0.6),
                                        size: 18)),
                            onTap: isThisGroup
                                ? null
                                : () async {
                                    final firmaId = f['id'] as int;

                                    if (isOtherGroup) {
                                      final eskiGrupAdi =
                                          firmaGrupAdi ?? 'başka bir grup';
                                      final onay = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          backgroundColor: colors.card,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          title:
                                              const Text("Firmayı Taşı"),
                                          content: Text(
                                            '"${f['isim']}" firması "$eskiGrupAdi" grubuna dahildir.\n\n"$targetGrupAdi" grubuna taşınmasını onaylıyor musunuz?',
                                          ),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(
                                                        dialogCtx, false),
                                                child:
                                                    const Text("İptal")),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(
                                                      dialogCtx, true),
                                              style:
                                                  ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          colors.accent,
                                                      foregroundColor:
                                                          Colors.black),
                                              child: const Text("Evet, Taşı"),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (onay != true) return;
                                    }

                                    await DatabaseService.assignFirmaToGrup(
                                        firmaId, targetGrupId);
                                    await _loadData();
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                          );
                        },
                      ),
              ),
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20, right: 20, top: 4,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                      controller: adCtrl,
                      decoration:
                          const InputDecoration(labelText: "Firma Adı *"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: telCtrl,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(labelText: "Telefon"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: mailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(labelText: "E-posta"),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final isim = adCtrl.text.trim();
                          if (isim.isEmpty) return;
                          final id = await DatabaseService.insertFirma(
                            targetGrupId, isim,
                            telCtrl.text.trim(), mailCtrl.text.trim(),
                          );
                          setState(() {
                            gruplar[grupIndex]["firmalar"].add({
                              "id": id,
                              "grupId": targetGrupId,
                              "isim": isim,
                              "telefon": telCtrl.text.trim(),
                              "mail": mailCtrl.text.trim(),
                              "durum": "NORMAL",
                              "notlar": <FirmaNot>[],
                              "raporlar": <GorselRapor>[],
                              "belgeler": <Map<String, dynamic>>[],
                            });
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accent,
                          foregroundColor: Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("EKLE",
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ]),
        );
      }),
    );

    aramaCtrl.dispose();
    adCtrl.dispose();
    telCtrl.dispose();
    mailCtrl.dispose();
  }

  Color durumRenk(String d) {
    if (d == "GİDİLDİ") return Colors.green;
    if (d == "GİDİLMEDİ") return Colors.red;
    if (d == "KİMSE_YOK") return Colors.orange;
    return Colors.grey;
  }

  String durumText(String d) {
    if (d == "GİDİLDİ") return "Gidildi";
    if (d == "GİDİLMEDİ") return "Gidilmedi";
    if (d == "KİMSE_YOK") return "Kimse Yok";
    return "Bekliyor";
  }

  Future<void> tarihSec(int g) async {
    final colors = AppColors.of(context);
    final secilen = await showDatePicker(
      context: context,
      initialDate: gruplar[g]["tarih"] as DateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: colors.accent,
            onPrimary: Colors.black,
            surface: colors.card,
            onSurface: colors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (secilen != null) {
      await DatabaseService.updateGrup(
          gruplar[g]["id"] as int, gruplar[g]["grupAdi"] as String, secilen);
      setState(() => gruplar[g]["tarih"] = secilen);
    }
  }

  void _grupSilOnay(int g) {
    final grupAdi = gruplar[g]["grupAdi"] as String;
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.card,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Grubu Sil"),
        content: Text(
            "$grupAdi silinecek. Gruptaki firmalar grupsuz kalır, silinmez."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hayır"),
          ),
          ElevatedButton(
            onPressed: () async {
              final grupId = gruplar[g]["id"] as int;
              final savedGrupTarih = gruplar[g]["tarih"] as DateTime;
              final savedFirmalar = List<Map<String, dynamic>>.from(
                  gruplar[g]["firmalar"]);
              final firmaIds =
                  savedFirmalar.map((f) => f["id"] as int).toList();

              await DatabaseService.deleteGrup(grupId);
              setState(() => gruplar.removeAt(g));
              if (context.mounted) {
                Navigator.pop(context); // dialog kapat
                Navigator.pop(context); // bottomsheet kapat
              }

              if (!mounted) return;
              _messengerKey.currentState?.clearSnackBars();
              _messengerKey.currentState?.showSnackBar(
                SnackBar(
                  content: Text("$grupAdi silindi"),
                  action: SnackBarAction(
                    label: "Geri Al",
                    textColor: colors.accent,
                    onPressed: () async {
                      final newId = await DatabaseService.insertGrup(
                          grupAdi, savedGrupTarih);
                      for (final fId in firmaIds) {
                        await DatabaseService.assignFirmaToGrup(fId, newId);
                      }
                      final restoredFirmalar = savedFirmalar
                          .map((f) => {...f, "grupId": newId})
                          .toList();
                      setState(() => gruplar.insert(g, {
                            "id": newId,
                            "grupAdi": grupAdi,
                            "tarih": savedGrupTarih,
                            "firmalar": restoredFirmalar,
                          }));
                    },
                  ),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colors.cardDark,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
  }

  void grupDuzenlePopup(int g) {
    final grup = gruplar[g];
    final isimController = TextEditingController(text: grup["grupAdi"]);
    final colors = AppColors.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sbCtx, setM) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sbCtx).viewInsets.bottom + 20,
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Grup Düzenle",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => _grupSilOnay(g),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.red.withValues(alpha:0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline,
                                color: Colors.red, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "Grubu Sil",
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: isimController,
                  decoration: InputDecoration(
                    labelText: "Grup Adı",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: colors.bg,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final secilen = await showDatePicker(
                      context: context,
                      initialDate: gruplar[g]["tarih"] as DateTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: colors.accent,
                            onPrimary: Colors.black,
                            surface: colors.card,
                            onSurface: colors.text,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (secilen != null) {
                      setState(() => gruplar[g]["tarih"] = secilen);
                      setM(() {});
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: colors.accent),
                        const SizedBox(width: 12),
                        Text(
                          "${(gruplar[g]["tarih"] as DateTime).day.toString().padLeft(2, '0')}-"
                              "${(gruplar[g]["tarih"] as DateTime).month.toString().padLeft(2, '0')}-"
                              "${(gruplar[g]["tarih"] as DateTime).year}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("İptal"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await DatabaseService.updateGrup(
                            grup["id"] as int,
                            isimController.text,
                            gruplar[g]["tarih"] as DateTime,
                          );
                          setState(() => grup["grupAdi"] = isimController.text);
                          if (sheetCtx.mounted) Navigator.pop(sheetCtx);
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
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _silOnay(int g, int f) {
    final firma = gruplar[g]["firmalar"][f];
    final firmaIsim = firma["isim"] as String;
    final anaContext = context;
    final colors = AppColors.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colors.card,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Firmayı Sil"),
        content: Text("$firmaIsim silinsin mi? Notlar, raporlar ve belgeler de silinir."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hayır"),
          ),
          ElevatedButton(
            onPressed: () async {
              final firmaId = firma["id"] as int;
              final grupId = firma["grupId"] as int?;
              final savedFirma = Map<String, dynamic>.from(firma);
              final savedNotlar = List<Map<String, dynamic>>.from(
                  (firma["notlar"] as List).map((n) => n is FirmaNot
                      ? {"metin": n.metin, "zaman": n.zaman, "fotoPaths": n.fotoPaths}
                      : Map<String, dynamic>.from(n as Map)));
              final savedRaporlar = List<GorselRapor>.from(
                  (firma["raporlar"] as List).cast<GorselRapor>());
              final savedBelgeler = List<Map<String, dynamic>>.from(
                  (firma["belgeler"] as List).cast<Map<String, dynamic>>());
              final grupIndex = g;
              final firmaIndex = f;

              await DatabaseService.deleteFirma(firmaId);

              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (anaContext.mounted) Navigator.pop(anaContext);

              setState(() {
                gruplar[grupIndex]["firmalar"].removeAt(firmaIndex);
              });

              if (!anaContext.mounted) return;
              ScaffoldMessenger.of(anaContext).clearSnackBars();
              ScaffoldMessenger.of(anaContext).showSnackBar(
                SnackBar(
                  content: Text("$firmaIsim silindi"),
                  action: SnackBarAction(
                    label: "Geri Al",
                    textColor: colors.accent,
                    onPressed: () async {
                      final newId = await DatabaseService.insertFirmaStandalone(
                        savedFirma["isim"] as String,
                        savedFirma["telefon"] as String? ?? '',
                        savedFirma["mail"] as String? ?? '',
                      );
                      if (grupId != null) {
                        await DatabaseService.assignFirmaToGrup(newId, grupId);
                      }
                      for (final n in savedNotlar) {
                        await DatabaseService.insertNot(newId, n["metin"] as String,
                            n["zaman"] as DateTime, List<String>.from(n["fotoPaths"] as List));
                      }
                      for (final r in savedRaporlar) {
                        await DatabaseService.insertGorselRapor(
                            id: r.id, firmaId: newId, baslik: r.baslik,
                            rapor: r.rapor, tarih: r.tarih, fotoPaths: r.fotoPaths);
                      }
                      for (final b in savedBelgeler) {
                        await DatabaseService.insertBelge(
                            firmaId: newId, baslik: b["baslik"] as String,
                            dosyaYolu: b["dosyaYolu"] as String, tur: b["tur"] as String,
                            gecerlilikTarihi: b["gecerlilikTarihi"] as DateTime?);
                      }
                      await _loadData();
                    },
                  ),
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colors.cardDark,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
  }

  void firmaPopup(int g, int f) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => _FirmaPopupSheet(
        gruplar: gruplar,
        grupIndex: g,
        firmaIndex: f,
        onStateChange: () => setState(() {}),
        onSilTap: () => _silOnay(g, f),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        title: const Text("Saha Denetim",
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colors.accent),
            onPressed: yeniGrupEklePopup,
            tooltip: "Yeni Grup",
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.accent))
          : gruplar.isEmpty
          ? const Center(
          child: Text("Henüz grup yok",
              style: TextStyle(color: Colors.white38)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: gruplar.length,
        itemBuilder: (context, g) {
          final grup = gruplar[g];
          final firmalar =
          List<Map<String, dynamic>>.from(grup["firmalar"]);
          final tarih = grup["tarih"] as DateTime;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: colors.accent.withValues(alpha:0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => grupDuzenlePopup(g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha:0.07),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.folder_open,
                            color: colors.accent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            grup["grupAdi"],
                            style: TextStyle(
                              color: colors.accent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Text(
                          "${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}",
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit_outlined,
                            color: Colors.grey[600], size: 16),
                      ],
                    ),
                  ),
                ),

                ...firmalar.asMap().entries.map((e) {
                  final fi = e.key;
                  final firma = e.value;
                  final durum = firma["durum"] as String;
                  final notlar =
                      (firma["notlar"] as List<FirmaNot>?) ?? [];

                  return GestureDetector(
                    onTap: () => firmaPopup(g, fi),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: colors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: durumRenk(durum),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firma["isim"],
                                  style: TextStyle(
                                    color: colors.text,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                if (notlar.isNotEmpty)
                                  Padding(
                                    padding:
                                    const EdgeInsets.only(top: 3),
                                    child: Text(
                                      "${notlar.length} not",
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: colors.accent
                                              .withValues(alpha:0.7)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                              durumRenk(durum).withValues(alpha:0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              durumText(durum),
                              style: TextStyle(
                                color: durumRenk(durum),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right,
                              color: Colors.grey[700], size: 18),
                        ],
                      ),
                    ),
                  );
                }),

                GestureDetector(
                  onTap: () => yeniFirmaEklePopup(g),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                            color: colors.border),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add,
                            color: Colors.grey[600], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "Firma Ekle",
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),   // Scaffold
    );   // ScaffoldMessenger
  }
}

/* ====================================================
   FİRMA POPUP SHEET
   ==================================================== */
class _FirmaPopupSheet extends StatefulWidget {
  final List<Map<String, dynamic>> gruplar;
  final int grupIndex;
  final int firmaIndex;
  final VoidCallback onStateChange;
  final VoidCallback onSilTap;

  const _FirmaPopupSheet({
    required this.gruplar,
    required this.grupIndex,
    required this.firmaIndex,
    required this.onStateChange,
    required this.onSilTap,
  });

  @override
  State<_FirmaPopupSheet> createState() => _FirmaPopupSheetState();
}

class _FirmaPopupSheetState extends State<_FirmaPopupSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Map<String, dynamic> firma;

  final TextEditingController _notCtrl = TextEditingController();
  final List<String> _seciliFotoPaths = [];
  final ImagePicker _picker = ImagePicker();

  late TextEditingController isimCtrl;
  late TextEditingController telCtrl;
  late TextEditingController mailCtrl;
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    firma = widget.gruplar[widget.grupIndex]["firmalar"][widget.firmaIndex];
    isimCtrl = TextEditingController(text: firma["isim"] ?? "");
    telCtrl = TextEditingController(text: firma["telefon"] ?? "");
    mailCtrl = TextEditingController(text: firma["mail"] ?? "");
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notCtrl.dispose();
    isimCtrl.dispose();
    telCtrl.dispose();
    mailCtrl.dispose();
    super.dispose();
  }

  List<FirmaNot> get notlar =>
      (firma["notlar"] as List<FirmaNot>?) ?? [];

  Future<void> _fotoSec(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _seciliFotoPaths.add(picked.path));
    }
  }

  void _fotoEkleSheet() {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.cardDark,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCameraSupport)
              ListTile(
                leading: Icon(Icons.camera_alt_outlined,
                    color: colors.accent),
                title: const Text("Kamera"),
                onTap: () {
                  Navigator.pop(context);
                  _fotoSec(ImageSource.camera);
                },
              ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: colors.accent),
              title: const Text("Galeri"),
              onTap: () {
                Navigator.pop(context);
                _fotoSec(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _notEkle() async {
    final metin = _notCtrl.text.trim();
    if (metin.isEmpty && _seciliFotoPaths.isEmpty) return;

    final firmaId = firma["id"] as int;
    final zaman = DateTime.now();
    final fotolar = List<String>.from(_seciliFotoPaths);

    final id = await DatabaseService.insertNot(firmaId, metin, zaman, fotolar);

    final yeniNot = FirmaNot(
      id: id,
      metin: metin,
      zaman: zaman,
      fotoPaths: fotolar,
    );

    setState(() {
      (firma["notlar"] as List<FirmaNot>).add(yeniNot);
      _notCtrl.clear();
      _seciliFotoPaths.clear();
    });
    widget.onStateChange();
  }

  Future<void> _notSil(int index) async {
    final notlar = firma["notlar"] as List<FirmaNot>;
    final not = notlar[index];
    if (not.id != null) {
      await DatabaseService.deleteNot(not.id!);
    }
    setState(() => notlar.removeAt(index));
    widget.onStateChange();
  }

  String _formatZaman(DateTime z) {
    final gun = z.day.toString().padLeft(2, '0');
    final ay = z.month.toString().padLeft(2, '0');
    final yil = z.year;
    final saat = z.hour.toString().padLeft(2, '0');
    final dk = z.minute.toString().padLeft(2, '0');
    return "$gun.$ay.$yil  $saat:$dk";
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final durum = firma["durum"] as String? ?? "NORMAL";

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
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
                  Row(
                    children: [
                      Icon(Icons.business,
                          color: colors.accent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          firma["isim"] ?? "",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.accent.withValues(alpha: 0.4)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: colors.accent,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  const Tab(text: "Genel"),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Notlar"),
                        if (notlar.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colors.accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${notlar.length}",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Tab(text: "AI Rapor"),
                  const Tab(text: "Belgeler"),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  /* ========== GENEL SEKME ========== */
                  ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    children: [
                      const Text(
                        "ZİYARET DURUMU",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _DurumButon(
                            label: "Gidildi",
                            icon: Icons.check_circle_outline,
                            renk: Colors.green,
                            secili: durum == "GİDİLDİ",
                            onTap: () async {
                              final yeni = durum == "GİDİLDİ" ? "NORMAL" : "GİDİLDİ";
                              await DatabaseService.updateFirmaDurum(firma["id"] as int, yeni);
                              setState(() => firma["durum"] = yeni);
                              widget.onStateChange();
                            },
                          ),
                          const SizedBox(width: 8),
                          _DurumButon(
                            label: "Gidilmedi",
                            icon: Icons.cancel_outlined,
                            renk: Colors.red,
                            secili: durum == "GİDİLMEDİ",
                            onTap: () async {
                              final yeni = durum == "GİDİLMEDİ" ? "NORMAL" : "GİDİLMEDİ";
                              await DatabaseService.updateFirmaDurum(firma["id"] as int, yeni);
                              setState(() => firma["durum"] = yeni);
                              widget.onStateChange();
                            },
                          ),
                          const SizedBox(width: 8),
                          _DurumButon(
                            label: "Kimse Yok",
                            icon: Icons.person_off_outlined,
                            renk: Colors.orange,
                            secili: durum == "KİMSE_YOK",
                            onTap: () async {
                              final yeni = durum == "KİMSE_YOK" ? "NORMAL" : "KİMSE_YOK";
                              await DatabaseService.updateFirmaDurum(firma["id"] as int, yeni);
                              setState(() => firma["durum"] = yeni);
                              widget.onStateChange();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        "İLETİŞİM",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined,
                                color: colors.accent, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: editMode
                                  ? TextField(
                                controller: telCtrl,
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 14),
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: "Telefon",
                                  hintStyle: TextStyle(
                                      color: Colors.white30),
                                ),
                              )
                                  : Text(
                                firma["telefon"] ?? "-",
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 14),
                              ),
                            ),
                            if (!editMode)
                              GestureDetector(
                                onTap: () async {
                                  final tel =
                                      (firma["telefon"] as String?)
                                          ?.replaceAll(
                                          RegExp(r'\D'), '') ??
                                          '';
                                  if (tel.isEmpty) return;
                                  final uri = Uri.parse(
                                      "https://wa.me/90$tel");
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode
                                            .externalApplication);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF25D366)
                                        .withValues(alpha:0.12),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: const Color(0xFF25D366)
                                            .withValues(alpha:0.35)),
                                  ),
                                  child: const Icon(Icons.chat_outlined,
                                      color: Color(0xFF25D366), size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.border),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.mail_outline,
                                color: colors.accent, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: editMode
                                  ? TextField(
                                controller: mailCtrl,
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 14),
                                keyboardType:
                                TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                  hintText: "E-posta",
                                  hintStyle: TextStyle(
                                      color: Colors.white30),
                                ),
                              )
                                  : Text(
                                firma["mail"] ?? "-",
                                style: TextStyle(
                                    color: colors.text,
                                    fontSize: 14),
                              ),
                            ),
                            if (!editMode)
                              GestureDetector(
                                onTap: () async {
                                  final mail =
                                      firma["mail"] as String? ?? '';
                                  if (mail.isEmpty) return;
                                  final uri = Uri(
                                    scheme: 'mailto',
                                    path: mail,
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent
                                        .withValues(alpha:0.12),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.blueAccent
                                            .withValues(alpha:0.35)),
                                  ),
                                  child: const Icon(Icons.send_outlined,
                                      color: Colors.blueAccent, size: 16),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (editMode) {
                                  await DatabaseService.updateFirma(
                                    firma["id"] as int,
                                    isimCtrl.text,
                                    telCtrl.text,
                                    mailCtrl.text,
                                  );
                                  setState(() {
                                    firma["isim"] = isimCtrl.text;
                                    firma["telefon"] = telCtrl.text;
                                    firma["mail"] = mailCtrl.text;
                                    editMode = false;
                                  });
                                  widget.onStateChange();
                                } else {
                                  setState(() => editMode = true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: colors.accent.withValues(alpha: 0.1),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                      colors.accent.withValues(alpha:0.35)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      editMode
                                          ? Icons.save_outlined
                                          : Icons.edit_outlined,
                                      color: colors.accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      editMode ? "Kaydet" : "Düzenle",
                                      style: TextStyle(
                                        color: colors.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: widget.onSilTap,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha:0.08),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                      Colors.red.withValues(alpha:0.35)),
                                ),
                                child: const Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete_outline,
                                        color: Colors.red, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      "Firmayı Sil",
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),

                  /* ========== NOTLAR SEKME ========== */
                  Column(
                    children: [
                      Expanded(
                        child: notlar.isEmpty
                            ? Center(
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(Icons.note_alt_outlined,
                                  color: Colors.grey[700], size: 48),
                              const SizedBox(height: 12),
                              Text(
                                "Henüz not yok",
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Aşağıdan not ekleyebilirsiniz",
                                style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: notlar.length,
                          itemBuilder: (_, i) {
                            final not = notlar[i];
                            return _NotKarti(
                              not: not,
                              onSil: () => _notSil(i),
                              formatZaman: _formatZaman,
                            );
                          },
                        ),
                      ),

                      _NotGirisAlani(
                        ctrl: _notCtrl,
                        seciliFotoPaths: _seciliFotoPaths,
                        onFotoEkle: _fotoEkleSheet,
                        onFotoKaldir: (path) =>
                            setState(() => _seciliFotoPaths.remove(path)),
                        onNotEkle: _notEkle,
                      ),
                    ],
                  ),

                  /* ========== 3. SEKME: GÖRSEL RAPOR ========== */
                  GorselRaporPage(
                    firmaAdi: firma["isim"] ?? "Bilinmeyen Firma",
                    firmaId: firma["id"] as int,
                    raporlar: (firma["raporlar"] as List?)?.cast<GorselRapor>() ?? [],
                  ),

                  /* ========== 4. SEKME: BELGELER ========== */
                  BelgelerWidget(firmaId: firma["id"] as int),

                ], // TabBarView'in ana listesini kapatan parantez
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/* ====================================================
   NOT KARTI WIDGET
   ==================================================== */
class _NotKarti extends StatelessWidget {
  final FirmaNot not;
  final VoidCallback onSil;
  final String Function(DateTime) formatZaman;

  const _NotKarti({
    required this.not,
    required this.onSil,
    required this.formatZaman,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: colors.accent, size: 12),
              const SizedBox(width: 4),
              Text(
                formatZaman(not.zaman),
                style: TextStyle(color: Colors.grey[500], fontSize: 11),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSil,
                child:
                Icon(Icons.close, color: Colors.grey[600], size: 16),
              ),
            ],
          ),
          if (not.metin.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              not.metin,
              style: TextStyle(color: colors.text, fontSize: 14),
            ),
          ],
          if (not.fotoPaths.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: not.fotoPaths.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _fotoTamEkran(context, not.fotoPaths[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(not.fotoPaths[i])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _fotoTamEkran(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(path)),
            ),
          ),
        ),
      ),
    );
  }
}

/* ====================================================
   NOT GİRİŞ ALANI WIDGET
   ==================================================== */
class _NotGirisAlani extends StatelessWidget {
  final TextEditingController ctrl;
  final List<String> seciliFotoPaths;
  final VoidCallback onFotoEkle;
  final void Function(String) onFotoKaldir;
  final VoidCallback onNotEkle;

  const _NotGirisAlani({
    required this.ctrl,
    required this.seciliFotoPaths,
    required this.onFotoEkle,
    required this.onFotoKaldir,
    required this.onNotEkle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.cardDark,
        border: Border(
            top: BorderSide(color: colors.border)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (seciliFotoPaths.isNotEmpty) ...[
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: seciliFotoPaths.length,
                itemBuilder: (_, i) {
                  final path = seciliFotoPaths[i];
                  return Stack(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(File(path)),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => onFotoKaldir(path),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          Row(
            children: [
              GestureDetector(
                onTap: onFotoEkle,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: colors.accent.withValues(alpha:0.3)),
                  ),
                  child: Icon(Icons.camera_alt_outlined,
                      color: colors.accent, size: 20),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: colors.border),
                  ),
                  child: TextField(
                    controller: ctrl,
                    maxLines: null,
                    style: TextStyle(
                        color: colors.text, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Saha notu ekle...",
                      hintStyle: TextStyle(
                          color: Colors.grey[600], fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              GestureDetector(
                onTap: onNotEkle,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.black, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ====================================================
   DURUM BUTON WIDGET
   ==================================================== */
class _DurumButon extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color renk;
  final bool secili;
  final VoidCallback onTap;

  const _DurumButon({
    required this.label,
    required this.icon,
    required this.renk,
    required this.secili,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: secili
                ? renk.withValues(alpha:0.18)
                : colors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: secili ? renk : colors.border,
              width: secili ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: secili ? renk : Colors.grey[600],
                size: 22,
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secili ? renk : Colors.grey[600],
                  fontSize: 11,
                  fontWeight:
                  secili ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class FirmaNot {
  int? id;
  String metin;
  DateTime zaman;
  List<String> fotoPaths;

  FirmaNot({
    this.id,
    required this.metin,
    required this.zaman,
    required this.fotoPaths,
  });
}