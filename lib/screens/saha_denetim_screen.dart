import 'dart:io';
import 'package:pehlivan_isg/pages/gorsel_rapor_page.dart';
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
  List<Map<String, dynamic>> gruplar = [
    {
      "grupAdi": "GRUP 1",
      "tarih": DateTime(2026, 5, 10),
      "firmalar": [
        {
          "isim": "A FİRMA",
          "telefon": "555",
          "mail": "a@mail.com",
          "durum": "NORMAL",
          "notlar": <FirmaNot>[],
        }
      ]
    },
    {
      "grupAdi": "GRUP 2",
      "tarih": DateTime(2026, 5, 11),
      "firmalar": [
        {
          "isim": "B FİRMA",
          "telefon": "555",
          "mail": "b@mail.com",
          "durum": "NORMAL",
          "notlar": <FirmaNot>[],
        }
      ]
    }
  ];

  void yeniGrupEklePopup() {
    final grupAdController = TextEditingController();
    DateTime secilenTarih = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text("Yeni Denetim Grubu",
            style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: grupAdController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: "Grup Adı",
                  hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İPTAL")),
          ElevatedButton(
            onPressed: () {
              if (grupAdController.text.isNotEmpty) {
                setState(() {
                  gruplar.add({
                    "grupAdi": grupAdController.text,
                    "tarih": secilenTarih,
                    "firmalar": [],
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text("OLUŞTUR"),
          ),
        ],
      ),
    );
  }

  void yeniFirmaEklePopup(int grupIndex) {
    final adController = TextEditingController();
    final telController = TextEditingController();
    final mailController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D1117),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Firma Bilgileri",
                style: TextStyle(fontSize: 18, color: Colors.amber)),
            TextField(
                controller: adController,
                decoration:
                const InputDecoration(labelText: "Firma Adı")),
            TextField(
                controller: telController,
                decoration: const InputDecoration(labelText: "Telefon")),
            TextField(
                controller: mailController,
                decoration: const InputDecoration(labelText: "E-posta")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  gruplar[grupIndex]["firmalar"].add({
                    "isim": adController.text,
                    "telefon": telController.text,
                    "mail": mailController.text,
                    "durum": "NORMAL",
                    "notlar": <FirmaNot>[],
                    "raporlar": <GorselRapor>[],
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("EKLE"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
    final secilen = await showDatePicker(
      context: context,
      initialDate: gruplar[g]["tarih"] as DateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.amber,
            onPrimary: Colors.black,
            surface: Color(0xFF161B22),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (secilen != null) setState(() => gruplar[g]["tarih"] = secilen);
  }

  void _grupSilOnay(int g) {
    final grupAdi = gruplar[g]["grupAdi"] as String;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Grubu Sil"),
        content: Text(
            "$grupAdi ve içindeki tüm firmalar silinecek. Emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hayır"),
          ),
          ElevatedButton(
            onPressed: () {
              final silinen = {
                "grupAdi": gruplar[g]["grupAdi"],
                "tarih": gruplar[g]["tarih"],
                "firmalar": (gruplar[g]["firmalar"] as List)
                    .map((f) => Map<String, dynamic>.from(f))
                    .toList(),
              };
              final gIndex = g;

              setState(() => gruplar.removeAt(g));
              Navigator.pop(context);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).clearSnackBars();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$grupAdi silindi"),
                  action: SnackBarAction(
                    label: "Geri Al",
                    textColor: Colors.amber,
                    onPressed: () {
                      setState(() {
                        gruplar.insert(
                          gIndex.clamp(0, gruplar.length),
                          silinen,
                        );
                      });
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1F2937),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
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
                    fillColor: const Color(0xFF0D1117),
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
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Colors.amber,
                            onPrimary: Colors.black,
                            surface: Color(0xFF161B22),
                            onSurface: Colors.white,
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
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.amber),
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
                        onPressed: () {
                          setState(
                                  () => grup["grupAdi"] = isimController.text);
                          Navigator.pop(sheetCtx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
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

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Firmayı Sil"),
        content: Text("$firmaIsim silinsin mi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Hayır"),
          ),
          ElevatedButton(
            onPressed: () {
              final firmaKopya = Map<String, dynamic>.from(firma);
              final grupIndex = g;
              final firmaIndex = f;

              Navigator.pop(dialogCtx);
              Navigator.pop(anaContext);

              setState(() {
                gruplar[grupIndex]["firmalar"].removeAt(firmaIndex);
              });

              ScaffoldMessenger.of(anaContext).clearSnackBars();
              ScaffoldMessenger.of(anaContext).showSnackBar(
                SnackBar(
                  content: Text("$firmaIsim silindi"),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: "Geri Al",
                    textColor: Colors.amber,
                    onPressed: () {
                      setState(() {
                        final mevcutListe =
                        List<Map<String, dynamic>>.from(
                            gruplar[grupIndex]["firmalar"]);
                        mevcutListe.insert(
                          firmaIndex.clamp(0, mevcutListe.length),
                          firmaKopya,
                        );
                        gruplar[grupIndex]["firmalar"] = mevcutListe;
                      });
                    },
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF1F2937),
                  margin: const EdgeInsets.all(20),
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
      backgroundColor: const Color(0xFF161B22),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text("Saha Denetim",
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.amber),
            onPressed: yeniGrupEklePopup,
            tooltip: "Yeni Grup",
          ),
        ],
      ),
      body: gruplar.isEmpty
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
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.amber.withValues(alpha:0.2), width: 1),
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
                      color: Colors.amber.withValues(alpha:0.07),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            grup["grupAdi"],
                            style: const TextStyle(
                              color: Colors.amber,
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
                              color: Colors.white.withValues(alpha:0.05)),
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
                                  style: const TextStyle(
                                    color: Colors.white,
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
                                          color: Colors.amber
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
                            color: Colors.white.withValues(alpha:0.05)),
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
    );
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
    _tabController = TabController(length: 3, vsync: this);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2333),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Colors.amber),
              title: const Text("Kamera"),
              onTap: () {
                Navigator.pop(context);
                _fotoSec(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Colors.amber),
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

  void _notEkle() {
    final metin = _notCtrl.text.trim();
    if (metin.isEmpty && _seciliFotoPaths.isEmpty) return;

    final yeniNot = FirmaNot(
      metin: metin,
      zaman: DateTime.now(),
      fotoPaths: List.from(_seciliFotoPaths),
    );

    setState(() {
      (firma["notlar"] as List<FirmaNot>).add(yeniNot);
      _notCtrl.clear();
      _seciliFotoPaths.clear();
    });
    widget.onStateChange();
  }

  void _notSil(int index) {
    setState(() {
      (firma["notlar"] as List<FirmaNot>).removeAt(index);
    });
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
                      const Icon(Icons.business,
                          color: Colors.amber, size: 20),
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
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.amber,
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
                              color: Colors.amber,
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
                  const Tab(text: "Görsel Rapor"), // 3. Sekme başlığımız premium tasarıma dahil oldu
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
                            onTap: () {
                              setState(() => firma["durum"] =
                              durum == "GİDİLDİ" ? "NORMAL" : "GİDİLDİ");
                              widget.onStateChange();
                            },
                          ),
                          const SizedBox(width: 8),
                          _DurumButon(
                            label: "Gidilmedi",
                            icon: Icons.cancel_outlined,
                            renk: Colors.red,
                            secili: durum == "GİDİLMEDİ",
                            onTap: () {
                              setState(() => firma["durum"] =
                              durum == "GİDİLMEDİ" ? "NORMAL" : "GİDİLMEDİ");
                              widget.onStateChange();
                            },
                          ),
                          const SizedBox(width: 8),
                          _DurumButon(
                            label: "Kimse Yok",
                            icon: Icons.person_off_outlined,
                            renk: Colors.orange,
                            secili: durum == "KİMSE_YOK",
                            onTap: () {
                              setState(() => firma["durum"] =
                              durum == "KİMSE_YOK" ? "NORMAL" : "KİMSE_YOK");
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
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha:0.07)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: editMode
                                  ? TextField(
                                controller: telCtrl,
                                style: const TextStyle(
                                    color: Colors.white,
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
                                style: const TextStyle(
                                    color: Colors.white,
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
                          color: const Color(0xFF0D1117),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha:0.07)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.mail_outline,
                                color: Colors.amber, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: editMode
                                  ? TextField(
                                controller: mailCtrl,
                                style: const TextStyle(
                                    color: Colors.white,
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
                                style: const TextStyle(
                                    color: Colors.white,
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
                              onTap: () {
                                if (editMode) {
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
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius:
                                  BorderRadius.circular(12),
                                  border: Border.all(
                                      color:
                                      Colors.amber.withValues(alpha:0.35)),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      editMode
                                          ? Icons.save_outlined
                                          : Icons.edit_outlined,
                                      color: Colors.amber,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      editMode ? "Kaydet" : "Düzenle",
                                      style: const TextStyle(
                                        color: Colors.amber,
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

                  /* ========== 3. SEKME: GÖRSEL RAPOR MODÜLÜ ========== */
                  GorselRaporPage(
                    firmaAdi: firma["isim"] ?? "Bilinmeyen Firma",
                    raporlar: (firma["raporlar"] as List<dynamic>?)?.cast<GorselRapor>() ?? [],
                  ),

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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha:0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.amber, size: 12),
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C2333),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha:0.08))),
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
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                    Border.all(color: Colors.amber.withValues(alpha:0.3)),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Colors.amber, size: 20),
                ),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1117),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha:0.1)),
                  ),
                  child: TextField(
                    controller: ctrl,
                    maxLines: null,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
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
                    color: Colors.amber,
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: secili
                ? renk.withValues(alpha:0.18)
                : const Color(0xFF0D1117),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: secili ? renk : Colors.white.withValues(alpha:0.08),
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
  String metin;
  DateTime zaman;
  List<String> fotoPaths;

  FirmaNot({
    required this.metin,
    required this.zaman,
    required this.fotoPaths,
  });
}