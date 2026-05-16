import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'edit_profile_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> with SingleTickerProviderStateMixin {
  String name = "Abdurrahman Pehlivan";
  String email = "kullanici@isg.com";
  String phone = "+90 5xx xxx xx xx";
  String title = "İş Sağlığı ve Güvenliği Uzmanı";
  String department = "HSE Departmanı";
  String employeeId = "ISG-2024-001";
  String certLevel = "A Sınıfı";
  String experience = "8 Yıl";
  File? profileImage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
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
                _infoTile(Icons.domain_outlined, "Departman", department),
                _infoTile(Icons.fingerprint_outlined, "Sicil No", employeeId),
                _infoTile(Icons.workspace_premium_outlined, "Sınıf", certLevel),

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
        border: Border.all(color: const Color(0xFFE8B84B).withOpacity(0.18), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8B84B).withOpacity(0.06),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative corner accent
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(topRight: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8B84B).withOpacity(0.12),
                    Colors.transparent,
                  ],
                ),
              ),
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
                            color: const Color(0xFFE8B84B).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 52,
                        backgroundColor: const Color(0xFF0F1420),
                        backgroundImage:
                        profileImage != null ? FileImage(profileImage!) : null,
                        child: profileImage == null
                            ? const Icon(Icons.person, size: 52, color: Color(0xFFE8B84B))
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
                          border: Border.all(color: const Color(0xFF0F1420), width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF0A0E1A)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8B84B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE8B84B).withOpacity(0.3)),
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

                const SizedBox(height: 8),

                Text(
                  department,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),

                // ISG Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_outlined, size: 14, color: Color(0xFF4ADE80)),
                    const SizedBox(width: 4),
                    Text(
                      "Sertifikalı ISG Uzmanı · $certLevel",
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard(Icons.work_history_outlined, experience, "Deneyim"),
          const SizedBox(width: 10),
          _statCard(Icons.shield_outlined, certLevel, "Sınıf"),
          const SizedBox(width: 10),
          _statCard(Icons.assignment_ind_outlined, employeeId.split("-").last, "Sicil"),
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
          border: Border.all(color: Colors.white.withOpacity(0.06)),
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
  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B).withOpacity(0.10),
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
                    style: const TextStyle(color: Colors.white38, fontSize: 11,
                        letterSpacing: 0.5)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
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
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFFE8B84B)),
              title: const Text("Kamera", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Color(0xFFE8B84B)),
              title: const Text("Galeri", style: TextStyle(color: Colors.white)),
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
      setState(() => profileImage = File(picked.path));
    }
  }

  Future<void> _openEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          name: name,
          email: email,
          phone: phone,
          title: title,
          department: department,
          employeeId: employeeId,
          certLevel: certLevel,
          experience: experience,
          profileImage: profileImage,
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        name = result["name"] ?? name;
        email = result["email"] ?? email;
        phone = result["phone"] ?? phone;
        title = result["title"] ?? title;
        department = result["department"] ?? department;
        employeeId = result["employeeId"] ?? employeeId;
        certLevel = result["certLevel"] ?? certLevel;
        experience = result["experience"] ?? experience;
        if (result["profileImage"] != null) profileImage = result["profileImage"];
      });
    }
  }
}