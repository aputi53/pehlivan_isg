import 'dart:convert'; // KURAL 1: Base64 kod çözümü için eklendi
import 'dart:io';
import 'package:pehlivan_isg/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Hafıza kaydı için eklendi
import 'edit_profile_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> with SingleTickerProviderStateMixin {
  // Güvenli hafıza nesnesi oluşturuluyor
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true, // Güvenli ve kalıcı şifreleme havuzunu zorunlu kılar
      sharedPreferencesName: 'PehlivanISG_Storage', // Verilerin yazılacağı özel bir dosya adı tanımlar
    ),
  );

  // Başlangıç varsayılan değerleri (Eğer hafızada kayıt yoksa bunlar görünecek)
  String name = "Abdurrahman Pehlivan";
  String email = "kullanici@isg.com";
  String phone = "+90 5xx xxx xx xx";
  String title = "A Sınıfı İş Güvenliği Uzmanı";
  String profession = "İş Güvenliği Uzmanı";
  String employeeId = "";
  String certLevel = "A Sınıfı";
  String startDate = "";
  String? profileImageBase64;
  String companyName = '';
  String? companyLogoBase64;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // Uygulama açılırken kaydedilen verileri yükle

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  // SÜREÇ ANALİZİ: Hafızadan verileri güvenli okuma fonksiyonu
  Future<void> _loadProfileData() async {
    final savedName       = await _storage.read(key: "user_name");
    final savedEmail      = await _storage.read(key: "user_email");
    final savedPhone      = await _storage.read(key: "user_phone");
    final savedTitle      = await _storage.read(key: "user_title");
    final savedProfession = await _storage.read(key: "user_profession");
    final savedEmpId      = await _storage.read(key: "user_emp_id");
    final savedCert       = await _storage.read(key: "user_cert");
    final savedStartDate  = await _storage.read(key: "user_company_start_date");
    final savedImg        = await _storage.read(key: "user_image_base64");
    final savedCompany    = await _storage.read(key: "user_company");
    final savedCompanyLogo= await _storage.read(key: "user_company_logo");

    setState(() {
      if (savedName != null)       name       = savedName;
      if (savedEmail != null)      email      = savedEmail;
      if (savedPhone != null)      phone      = savedPhone;
      if (savedTitle != null)      title      = savedTitle;
      if (savedProfession != null) profession = savedProfession;
      if (savedEmpId != null)      employeeId = savedEmpId;
      if (savedCert != null)       certLevel  = savedCert;
      if (savedStartDate != null)  startDate  = savedStartDate;
      if (savedImg != null)        profileImageBase64 = savedImg;
      if (savedCompany != null)    companyName = savedCompany;
      companyLogoBase64 = savedCompanyLogo;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Başlangıç tarihinden bugüne geçen süre (tam metin: "5 Yıl 42 Gün")
  String _calculateDuration(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final p = dateStr.split('.');
      if (p.length != 3) return '';
      final start = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      final now = DateTime.now();
      if (!now.isAfter(start)) return '';
      int years = now.year - start.year;
      final lastAnniv = DateTime(start.year + years, start.month, start.day);
      if (lastAnniv.isAfter(now)) years--;
      final annivDate = DateTime(start.year + years, start.month, start.day);
      final remainDays = now.difference(annivDate).inDays;
      if (years > 0 && remainDays > 0) return '$years Yıl $remainDays Gün';
      if (years > 0) return '$years Yıl';
      return '${now.difference(start).inDays} Gün';
    } catch (_) {
      return '';
    }
  }

  // Stat kart için kısa versiyon ("5 Yıl" veya "286 Gün")
  String _durationShort(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final p = dateStr.split('.');
      if (p.length != 3) return '-';
      final start = DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
      final now = DateTime.now();
      if (!now.isAfter(start)) return '-';
      int years = now.year - start.year;
      final lastAnniv = DateTime(start.year + years, start.month, start.day);
      if (lastAnniv.isAfter(now)) years--;
      if (years > 0) return '$years Yıl';
      return '${now.difference(start).inDays} Gün';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PROFİL",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: Color(0xFFE8B84B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white54),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFFE8B84B)),
            onPressed: _openEditPage,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // ── HERO CARD ──────────────────────────────────────────────
                _buildHeroCard(),

                const SizedBox(height: 24),

                // ── STATS ROW ──────────────────────────────────────────────
                _buildStatsRow(),

                const SizedBox(height: 24),

                // ── CONTACT & INFO ─────────────────────────────────────────
                _buildSectionTitle("İletişim Bilgileri"),
                const SizedBox(height: 10),
                _infoTile(Icons.email_outlined, "E-posta", email),
                _infoTile(Icons.phone_outlined, "Telefon", phone),

                const SizedBox(height: 20),

                _buildSectionTitle("Mesleki Bilgiler"),
                const SizedBox(height: 10),
                _infoTile(Icons.badge_outlined, "Unvan", title),
                _infoTile(Icons.workspace_premium_outlined, "Sertifika No",
                    employeeId.isNotEmpty ? employeeId : '-'),

                if (companyName.isNotEmpty ||
                    companyLogoBase64 != null ||
                    startDate.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionTitle("Firma Bilgileri"),
                  const SizedBox(height: 10),
                  _buildCompanyTile(),
                  if (startDate.isNotEmpty)
                    _infoTile(
                      Icons.calendar_today_outlined,
                      "İşe Giriş Tarihi",
                      startDate,
                      subtitle: _calculateDuration(startDate),
                    ),
                ],

                const SizedBox(height: 28),

                // ── EDIT BUTTON ────────────────────────────────────────────
                _buildEditButton(),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HERO CARD ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF151C2E), Color(0xFF0F1420)],
        ),
        border: Border.all(
            color: const Color(0xFFE8B84B).withValues(alpha: 0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8B84B).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Dekoratif arka plan deseni ──
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _HeroPatternPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE8B84B), Color(0xFFB8882B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE8B84B).withValues(alpha: 0.30),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFF0F1420),
                        backgroundImage: profileImageBase64 != null
                            ? MemoryImage(base64Decode(profileImageBase64!))
                            : null,
                        child: profileImageBase64 == null
                            ? const Icon(Icons.person,
                                size: 52, color: Color(0xFFE8B84B))
                            : null,
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8B84B),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF0F1420), width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Color(0xFF0A0E1A)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // İsim
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 8),

                // Unvan badge (amber çerçeveli)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8B84B).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFE8B84B).withValues(alpha: 0.45),
                        width: 1.2),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE8B84B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Yeşil onay satırı
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 14, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 4),
                    Text(
                      profession == 'İşyeri Hekimi'
                          ? 'Sertifikalı İşyeri Hekimi'
                          : 'Sertifikalı ISG Uzmanı · $certLevel',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── STATS ROW ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    // Deneyim: başlangıç tarihinden kısa süre hesabı
    final deneyim = _durationShort(startDate);
    // Sınıf/Meslek stat değeri
    final classStat = profession == 'İşyeri Hekimi'
        ? 'Hekim'
        : (certLevel.isNotEmpty ? certLevel.replaceAll(' Sınıfı', '') : '-');
    // Sertifika numarası stat (sadece rakam kısmı)
    final certNumStat = employeeId.contains('-')
        ? employeeId.split('-').last
        : (employeeId.isNotEmpty ? employeeId : '-');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(Icons.work_history_outlined, deneyim, "Deneyim"),
          const SizedBox(width: 10),
          _statCard(Icons.shield_outlined, classStat, "Sınıf"),
          const SizedBox(width: 10),
          _statCard(Icons.assignment_ind_outlined, certNumStat, "Sertifika"),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF151C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFFE8B84B).withValues(alpha: 0.22),
              width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFE8B84B), size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION TITLE ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text.toUpperCase(),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── INFO TILE ─────────────────────────────────────────────────────────────
  Widget _infoTile(IconData icon, String label, String value,
      {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFFE8B84B).withValues(alpha: 0.15),
            width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFE8B84B), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 11, color: Color(0xFFE8B84B)),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFE8B84B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── COMPANY TILE ──────────────────────────────────────────────────────────
  Widget _buildCompanyTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2035),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFFE8B84B).withValues(alpha: 0.25)),
            ),
            child: companyLogoBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.memory(
                      base64Decode(companyLogoBase64!),
                      fit: BoxFit.contain,
                    ),
                  )
                : const Icon(Icons.business_outlined,
                    color: Color(0xFFE8B84B), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Firma",
                    style: TextStyle(
                        color: Colors.white38,
                        fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(
                  companyName.isNotEmpty ? companyName : "Firma adı girilmedi",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── EDIT BUTTON ───────────────────────────────────────────────────────────
  Widget _buildEditButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8B84B),
            foregroundColor: const Color(0xFF0A0E1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text(
            "Profili Düzenle",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
          ),
          onPressed: _openEditPage,
        ),
      ),
    );
  }

  // ── ACTIONS ───────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF151C2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text("Fotoğraf Seç",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            if (hasCameraSupport)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: Color(0xFFE8B84B)),
                title: const Text("Kamera",
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFFE8B84B)),
              title: const Text("Galeri",
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      final String base64Str = base64Encode(bytes);

      // Doğrudan hafızaya yaz
      await _storage.write(key: "user_image_base64", value: base64Str);

      setState(() {
        profileImageBase64 = base64Str;
      });
    }
  }

  // SÜREÇ ANALİZİ: Düzenleme sayfasından gelen verileri hafızaya mühürleme adımı
  Future<void> _openEditPage() async {
    // Telefon +90 prefix'ini soy
    String rawPhone = phone;
    if (rawPhone.startsWith('+90 ')) rawPhone = rawPhone.substring(4);
    else if (rawPhone.startsWith('+90')) rawPhone = rawPhone.substring(3);

    // Sertifika numarasının prefix'ini soy
    String rawCertNum = employeeId;
    if (rawCertNum.startsWith('İGU-')) rawCertNum = rawCertNum.substring(4);
    else if (rawCertNum.startsWith('İH-')) rawCertNum = rawCertNum.substring(3);
    // Eski format (ISG-2024-001 gibi) varsa sadece rakamları al
    else rawCertNum = rawCertNum.replaceAll(RegExp(r'[^0-9]'), '');

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          name:               name,
          email:              email,
          phone:              rawPhone,
          profession:         profession,
          certLevel:          certLevel,
          certNumber:         rawCertNum,
          startDate:          startDate,
          profileImageBase64: profileImageBase64,
          companyName:        companyName,
          companyLogoBase64:  companyLogoBase64,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        name       = result['name']       ?? name;
        email      = result['email']      ?? email;
        phone      = result['phone']      ?? phone;
        profession = result['profession'] ?? profession;
        title      = result['title']      ?? title;
        certLevel  = result['certLevel']  ?? certLevel;
        employeeId = result['certNumber'] ?? employeeId;
        startDate  = result['startDate']  ?? startDate;
        companyName = result['companyName'] ?? companyName;
        companyLogoBase64 = result['companyLogoBase64'];
        if (result['profileImageBase64'] != null) {
          profileImageBase64 = result['profileImageBase64'];
        }
      });
    }
  }
}

// ── Hero kart dekoratif desen ──────────────────────────────────────────────
class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Sağ üst köşe: amber eş merkezli yay halkalar
    final paintArc = Paint()
      ..color = const Color(0xFFE8B84B).withValues(alpha: 0.055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final topRight = Offset(size.width + 10, -10);
    for (final r in [70.0, 130.0, 190.0, 250.0, 310.0]) {
      canvas.drawCircle(topRight, r, paintArc);
    }

    // Sol alt köşe: çok silik beyaz halkalar
    final paintDim = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final bottomLeft = Offset(-10, size.height + 10);
    for (final r in [60.0, 110.0, 160.0]) {
      canvas.drawCircle(bottomLeft, r, paintDim);
    }
  }

  @override
  bool shouldRepaint(_HeroPatternPainter old) => false;
}