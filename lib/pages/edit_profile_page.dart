import 'dart:convert'; // KURAL 1: Base64 dönüşümü için eklendi
import 'dart:io';
import 'package:pehlivan_isg/utils/platform_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Hafıza kaydı için eklendi

class EditProfilePage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String title;
  final String department;
  final String employeeId;
  final String certLevel;
  final String experience;
  final String? profileImageBase64;
  final String companyName;
  final String? companyLogoBase64;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.title,
    required this.department,
    required this.employeeId,
    required this.certLevel,
    required this.experience,
    this.profileImageBase64,
    this.companyName = '',
    this.companyLogoBase64,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // SÜREÇ ANALİZİ: ProfilPage ile birebir aynı isimde, şifreli güvenli havuz nesnesi oluşturuldu
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController titleController;
  late TextEditingController departmentController;
  late TextEditingController employeeIdController;
  late TextEditingController experienceController;
  late TextEditingController companyNameController;

  String? _base64Image;
  String? _companyLogoBase64;
  String _selectedCertLevel = "A Sınıfı";
  final _formKey = GlobalKey<FormState>();

  final List<String> _certLevels = ["A Sınıfı", "B Sınıfı", "C Sınıfı"];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    emailController = TextEditingController(text: widget.email);
    phoneController = TextEditingController(text: widget.phone);
    titleController = TextEditingController(text: widget.title);
    departmentController = TextEditingController(text: widget.department);
    employeeIdController = TextEditingController(text: widget.employeeId);
    experienceController = TextEditingController(text: widget.experience);
    companyNameController = TextEditingController(text: widget.companyName);
    _base64Image = widget.profileImageBase64;
    _companyLogoBase64 = widget.companyLogoBase64;
    _selectedCertLevel = widget.certLevel;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    titleController.dispose();
    departmentController.dispose();
    employeeIdController.dispose();
    experienceController.dispose();
    companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "PROFİLİ DÜZENLE",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: Color(0xFFE8B84B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── PHOTO SECTION ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
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
                                color: const Color(0xFFE8B84B).withOpacity(0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 56,
                            backgroundColor: const Color(0xFF0F1420),
                            backgroundImage: _base64Image != null
                                ? MemoryImage(base64Decode(_base64Image!))
                                : null,
                            child: _base64Image == null
                                ? const Icon(Icons.person, size: 56, color: Color(0xFFE8B84B))
                                : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8B84B),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0A0E1A), width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16,
                                color: Color(0xFF0A0E1A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_outlined, size: 16,
                          color: Color(0xFFE8B84B)),
                      label: const Text("Fotoğraf Yükle",
                          style: TextStyle(color: Color(0xFFE8B84B), fontSize: 13)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── PERSONAL INFO ──────────────────────────────────────────
              _sectionLabel("Kişisel Bilgiler"),
              const SizedBox(height: 12),
              _buildField(
                controller: nameController,
                label: "Ad Soyad",
                icon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? "Bu alan zorunludur" : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: emailController,
                label: "E-posta",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Bu alan zorunludur";
                  if (!v.contains("@")) return "Geçerli bir e-posta giriniz";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: phoneController,
                label: "Telefon",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 24),

              // ── PROFESSIONAL INFO ──────────────────────────────────────
              _sectionLabel("Mesleki Bilgiler"),
              const SizedBox(height: 12),
              _buildField(
                controller: titleController,
                label: "Unvan",
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: departmentController,
                label: "Departman",
                icon: Icons.domain_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: employeeIdController,
                label: "Sicil Numarası",
                icon: Icons.fingerprint_outlined,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: experienceController,
                label: "Deneyim (Örn: 8 Yıl)",
                icon: Icons.work_history_outlined,
              ),
              const SizedBox(height: 12),

              // CERT LEVEL DROPDOWN
              _buildDropdown(),

              const SizedBox(height: 24),

              // ── FIRMA BİLGİLERİ ────────────────────────────────────────
              _sectionLabel("Firma Bilgileri"),
              const SizedBox(height: 12),
              _buildField(
                controller: companyNameController,
                label: "Çalıştığınız Firma Adı",
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              _buildCompanyLogoSection(),

              const SizedBox(height: 32),

              // ── SAVE BUTTON ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8B84B),
                    foregroundColor: const Color(0xFF0A0E1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _save,
                  child: const Text(
                    "Değişiklikleri Kaydet",
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // DISCARD BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "İptal",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(
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
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFE8B84B), size: 16),
          ),
        ),
        filled: true,
        fillColor: const Color(0xFF10151F),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8B84B), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8B84B).withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                color: Color(0xFFE8B84B), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCertLevel,
                dropdownColor: const Color(0xFF151C2E),
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE8B84B)),
                items: _certLevels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCertLevel = val);
                },
              ),
            ),
          ),
          const Text("Sertifika Sınıfı",
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10151F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF1A2035),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFFE8B84B).withValues(alpha: 0.3)),
            ),
            child: _companyLogoBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(
                      base64Decode(_companyLogoBase64!),
                      fit: BoxFit.contain,
                    ),
                  )
                : const Icon(Icons.business_outlined,
                    color: Color(0xFFE8B84B), size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Firma Logosu",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  "PDF raporlarda sol üstte görünür",
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickCompanyLogo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8B84B)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFE8B84B)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload_outlined,
                                color: Color(0xFFE8B84B), size: 14),
                            SizedBox(width: 5),
                            Text("Logo Yükle",
                                style: TextStyle(
                                    color: Color(0xFFE8B84B),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    if (_companyLogoBase64 != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _companyLogoBase64 = null),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCompanyLogo() async {
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
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text("Logo Seç",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
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
              title:
                  const Text("Galeri", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked =
        await picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _companyLogoBase64 = base64Encode(bytes));
    }
  }

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
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Text("Fotoğraf Seç",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
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
      final bytes = await picked.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  // SÜREÇ ANALİZİ: Çift dikiş kalıcı hafıza mühürlemesi
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final String finalName = nameController.text.trim();
    final String finalEmail = emailController.text.trim();
    final String finalPhone = phoneController.text.trim();
    final String finalTitle = titleController.text.trim();
    final String finalDept = departmentController.text.trim();
    final String finalEmpId = employeeIdController.text.trim();
    final String finalExp = experienceController.text.trim();

    // Verileri doğrudan bu ekrandayken de şifreli hafızaya taahhüt ediyoruz
    final finalCompany = companyNameController.text.trim();

    await _storage.write(key: "user_name", value: finalName);
    await _storage.write(key: "user_email", value: finalEmail);
    await _storage.write(key: "user_phone", value: finalPhone);
    await _storage.write(key: "user_title", value: finalTitle);
    await _storage.write(key: "user_dept", value: finalDept);
    await _storage.write(key: "user_emp_id", value: finalEmpId);
    await _storage.write(key: "user_cert", value: _selectedCertLevel);
    await _storage.write(key: "user_exp", value: finalExp);
    await _storage.write(key: "user_company", value: finalCompany);
    if (_base64Image != null) {
      await _storage.write(key: "user_image_base64", value: _base64Image);
    }
    if (_companyLogoBase64 != null) {
      await _storage.write(
          key: "user_company_logo", value: _companyLogoBase64);
    } else {
      await _storage.delete(key: "user_company_logo");
    }

    // ProfilPage'e haritayı pasla
    if (mounted) {
      Navigator.pop(context, {
        "name": finalName,
        "email": finalEmail,
        "phone": finalPhone,
        "title": finalTitle,
        "department": finalDept,
        "employeeId": finalEmpId,
        "certLevel": _selectedCertLevel,
        "experience": finalExp,
        "profileImageBase64": _base64Image,
        "companyName": finalCompany,
        "companyLogoBase64": _companyLogoBase64,
      });
    }
  }
}