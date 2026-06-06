import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pehlivan_isg/utils/platform_utils.dart';

const _kAccent = Color(0xFFE8B84B);
const _kBg     = Color(0xFF10151F);
const _kCard   = Color(0xFF151C2E);

class EditProfilePage extends StatefulWidget {
  final String  name;
  final String  email;
  final String  phone;       // +90 olmadan, sadece numara
  final String  profession;  // 'İş Güvenliği Uzmanı' | 'İşyeri Hekimi'
  final String  certLevel;   // 'A Sınıfı' | 'B Sınıfı' | 'C Sınıfı' | ''
  final String  certNumber;  // prefix olmadan sadece rakamlar
  final String  startDate;   // 'DD.MM.YYYY' | ''
  final String  companyName;
  final String? profileImageBase64;
  final String? companyLogoBase64;

  const EditProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    this.profession  = 'İş Güvenliği Uzmanı',
    this.certLevel   = 'A Sınıfı',
    this.certNumber  = '',
    this.startDate   = '',
    this.companyName = '',
    this.profileImageBase64,
    this.companyLogoBase64,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController certNumberController;
  late TextEditingController startDateController;
  late TextEditingController companyNameController;

  String?  _base64Image;
  String?  _companyLogoBase64;
  String   _selectedProfession = 'İş Güvenliği Uzmanı';
  String   _selectedCertLevel  = 'A Sınıfı';
  DateTime? _selectedStartDate;
  final _formKey = GlobalKey<FormState>();

  bool get _isIGU => _selectedProfession == 'İş Güvenliği Uzmanı';

  @override
  void initState() {
    super.initState();
    nameController       = TextEditingController(text: widget.name);
    emailController      = TextEditingController(text: widget.email);
    phoneController      = TextEditingController(text: widget.phone);
    certNumberController = TextEditingController(text: widget.certNumber);
    startDateController  = TextEditingController(text: widget.startDate);
    companyNameController= TextEditingController(text: widget.companyName);

    _base64Image        = widget.profileImageBase64;
    _companyLogoBase64  = widget.companyLogoBase64;
    _selectedProfession = widget.profession;
    _selectedCertLevel  = widget.certLevel.isNotEmpty ? widget.certLevel : 'A Sınıfı';

    // startDate string → DateTime
    if (widget.startDate.isNotEmpty) {
      try {
        final p = widget.startDate.split('.');
        if (p.length == 3) {
          _selectedStartDate =
              DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    certNumberController.dispose();
    startDateController.dispose();
    companyNameController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'PROFİLİ DÜZENLE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 4,
            color: _kAccent,
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
              // ── FOTOĞRAF ─────────────────────────────────────
              _buildPhotoSection(),
              const SizedBox(height: 28),

              // ── KİŞİSEL BİLGİLER ─────────────────────────────
              _sectionLabel('Kişisel Bilgiler'),
              const SizedBox(height: 12),
              _buildField(
                controller: nameController,
                label: 'Ad Soyad',
                icon: Icons.person_outline,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Bu alan zorunludur' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: emailController,
                label: 'E-posta',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Bu alan zorunludur';
                  if (!v.contains('@')) return 'Geçerli bir e-posta giriniz';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildPhoneField(),

              const SizedBox(height: 24),

              // ── MESLEKİ BİLGİLER ─────────────────────────────
              _sectionLabel('Mesleki Bilgiler'),
              const SizedBox(height: 12),

              // Meslek seçimi
              _buildProfessionToggle(),
              const SizedBox(height: 12),

              // Sertifika sınıfı (sadece IGU)
              if (_isIGU) ...[
                _buildCertLevelToggle(),
                const SizedBox(height: 12),
              ],

              // Sertifika numarası
              _buildCertNumberField(),

              const SizedBox(height: 24),

              // ── FİRMA BİLGİLERİ ───────────────────────────────
              _sectionLabel('Firma Bilgileri'),
              const SizedBox(height: 12),
              _buildField(
                controller: companyNameController,
                label: 'Çalıştığınız Firma Adı',
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 12),
              _buildDatePickerField(),
              const SizedBox(height: 12),
              _buildCompanyLogoSection(),

              const SizedBox(height: 32),

              // ── KAYDET ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: const Color(0xFF0A0E1A),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _save,
                  child: const Text(
                    'Değişiklikleri Kaydet',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal',
                      style: TextStyle(color: Colors.white38, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [_kAccent, Color(0xFFB8882B)]),
                  boxShadow: [
                    BoxShadow(
                        color: _kAccent.withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 6)),
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
                      ? const Icon(Icons.person, size: 56, color: _kAccent)
                      : null,
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF0A0E1A), width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      size: 16, color: Color(0xFF0A0E1A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_outlined, size: 16, color: _kAccent),
            label: const Text('Fotoğraf Yükle',
                style: TextStyle(color: _kAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Telefon',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefix: const Text('+90 ',
            style: TextStyle(
                color: _kAccent,
                fontSize: 14,
                fontWeight: FontWeight.w600)),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.phone_outlined, color: _kAccent, size: 16),
          ),
        ),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildProfessionToggle() {
    return Row(
      children: [
        _profBtn('İş Güvenliği Uzmanı', Icons.shield_outlined),
        const SizedBox(width: 10),
        _profBtn('İşyeri Hekimi', Icons.medical_services_outlined),
      ],
    );
  }

  Widget _profBtn(String value, IconData icon) {
    final bool sel = _selectedProfession == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedProfession = value;
          if (!_isIGU) _selectedCertLevel = '';
          if (_isIGU && _selectedCertLevel.isEmpty) _selectedCertLevel = 'A Sınıfı';
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: sel ? _kAccent.withValues(alpha: 0.10) : _kBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel
                  ? _kAccent
                  : Colors.white.withValues(alpha: 0.07),
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: sel ? _kAccent : Colors.white38, size: 22),
              const SizedBox(height: 6),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sel ? _kAccent : Colors.white38,
                  fontSize: 11.5,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertLevelToggle() {
    return Row(
      children: ['A Sınıfı', 'B Sınıfı', 'C Sınıfı'].map((v) {
        final bool sel = _selectedCertLevel == v;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedCertLevel = v),
            child: Container(
              margin: EdgeInsets.only(
                  right: v == 'C Sınıfı' ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: sel ? _kAccent.withValues(alpha: 0.10) : _kBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel
                      ? _kAccent
                      : Colors.white.withValues(alpha: 0.07),
                  width: sel ? 1.5 : 1,
                ),
              ),
              child: Text(
                v,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: sel ? _kAccent : Colors.white38,
                  fontSize: 12,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCertNumberField() {
    final prefix = _isIGU ? 'İGU-' : 'İH-';
    return TextFormField(
      controller: certNumberController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'Sertifika Numarası',
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefix: Text(
          prefix,
          style: const TextStyle(
              color: _kAccent, fontSize: 14, fontWeight: FontWeight.w700),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                color: _kAccent, size: 16),
          ),
        ),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDatePickerField() {
    return GestureDetector(
      onTap: _showStartDatePicker,
      child: AbsorbPointer(
        child: TextFormField(
          controller: startDateController,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: 'İşe Giriş Tarihi',
            labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _kAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    color: _kAccent, size: 16),
              ),
            ),
            suffixIcon: const Icon(Icons.expand_more, color: Colors.white38),
            filled: true,
            fillColor: _kBg,
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.07))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _kAccent, width: 1.4)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyLogoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.07)),
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
                  color: _kAccent.withValues(alpha: 0.3)),
            ),
            child: _companyLogoBase64 != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Image.memory(base64Decode(_companyLogoBase64!),
                        fit: BoxFit.contain))
                : const Icon(Icons.business_outlined,
                    color: _kAccent, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Firma Logosu',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text('PDF raporlarda sol üstte görünür',
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 11)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _logoBtn('Logo Yükle', Icons.upload_outlined,
                        _pickCompanyLogo),
                    if (_companyLogoBase64 != null) ...[
                      const SizedBox(width: 8),
                      _logoBtn(null, Icons.delete_outline,
                          () => setState(() => _companyLogoBase64 = null),
                          isDelete: true),
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

  Widget _logoBtn(String? label, IconData icon, VoidCallback onTap,
      {bool isDelete = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isDelete
              ? Colors.red.withValues(alpha: 0.1)
              : _kAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: isDelete
              ? null
              : Border.all(color: _kAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isDelete ? Colors.redAccent : _kAccent, size: 14),
            if (label != null) ...[
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(color: _kAccent, fontSize: 12)),
            ],
          ],
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
              color: _kAccent, borderRadius: BorderRadius.circular(2)),
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
      style: const TextStyle(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _kAccent, size: 16),
          ),
        ),
        filled: true,
        fillColor: _kBg,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.4)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
        errorStyle:
            const TextStyle(color: Colors.redAccent, fontSize: 11),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  TEKERLEK TARİH SEÇİCİ
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _showStartDatePicker() async {
    final now  = DateTime.now();
    final init = _selectedStartDate ?? now;

    int selDay   = init.day;
    int selMonth = init.month;
    int selYear  = init.year;

    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final years = List.generate(now.year - 1979, (i) => now.year - i);
    final yearIdx = years.indexOf(selYear).clamp(0, years.length - 1);

    final dayCtrl   = FixedExtentScrollController(initialItem: selDay - 1);
    final monthCtrl = FixedExtentScrollController(initialItem: selMonth - 1);
    final yearCtrl  = FixedExtentScrollController(initialItem: yearIdx);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const Text('İşe Giriş Tarihi',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                // Tekerlekler + vurgu bandı
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Orta seçim bandı
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: _kAccent.withValues(alpha: 0.08),
                          border: Border.symmetric(
                            horizontal: BorderSide(
                                color: _kAccent.withValues(alpha: 0.35),
                                width: 1),
                          ),
                        ),
                      ),
                      // Tekerlek Row
                      Row(
                        children: [
                          // Gün
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: dayCtrl,
                              itemExtent: 44,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setModal(() => selDay = i + 1),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 31,
                                builder: (_, i) {
                                  final sel = (i + 1) == selDay;
                                  return Center(
                                    child: Text(
                                      (i + 1).toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: sel ? _kAccent : Colors.white38,
                                        fontSize: sel ? 19 : 15,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(width: 1, color: Colors.white12),
                          // Ay
                          Expanded(
                            flex: 2,
                            child: ListWheelScrollView.useDelegate(
                              controller: monthCtrl,
                              itemExtent: 44,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setModal(() => selMonth = i + 1),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 12,
                                builder: (_, i) {
                                  final sel = (i + 1) == selMonth;
                                  return Center(
                                    child: Text(
                                      months[i],
                                      style: TextStyle(
                                        color: sel ? _kAccent : Colors.white38,
                                        fontSize: sel ? 16 : 13,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Container(width: 1, color: Colors.white12),
                          // Yıl
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: yearCtrl,
                              itemExtent: 44,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (i) =>
                                  setModal(() => selYear = years[i]),
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: years.length,
                                builder: (_, i) {
                                  final sel = years[i] == selYear;
                                  return Center(
                                    child: Text(
                                      '${years[i]}',
                                      style: TextStyle(
                                        color: sel ? _kAccent : Colors.white38,
                                        fontSize: sel ? 19 : 15,
                                        fontWeight: sel
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: const Color(0xFF0A0E1A),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedStartDate =
                            DateTime(selYear, selMonth, selDay);
                        startDateController.text =
                            '${selDay.toString().padLeft(2, '0')}.'
                            '${selMonth.toString().padLeft(2, '0')}.'
                            '$selYear';
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text('Tarihi Onayla',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  FOTOĞRAF
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final source = await _photoSourceSheet('Fotoğraf Seç');
    if (source == null) return;
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _base64Image = base64Encode(bytes));
    }
  }

  Future<void> _pickCompanyLogo() async {
    final source = await _photoSourceSheet('Logo Seç');
    if (source == null) return;
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _companyLogoBase64 = base64Encode(bytes));
    }
  }

  Future<ImageSource?> _photoSourceSheet(String title) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: _kCard,
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
                  borderRadius: BorderRadius.circular(2)),
            ),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 16),
            if (hasCameraSupport)
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: _kAccent),
                title: const Text('Kamera',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kAccent),
              title: const Text('Galeri',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  KAYDET
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Sertifika numarası: prefix + rakamlar
    final certNumRaw = certNumberController.text.trim();
    final certPrefix = _isIGU ? 'İGU-' : 'İH-';
    final fullCertNum =
        certNumRaw.isNotEmpty ? '$certPrefix$certNumRaw' : '';

    // Unvan: meslek + sınıf
    final composedTitle = _isIGU
        ? '$_selectedCertLevel İş Güvenliği Uzmanı'
        : 'İşyeri Hekimi';

    // Telefon: +90 ekle
    final rawPhone = phoneController.text.trim();
    final fullPhone = rawPhone.isNotEmpty ? '+90 $rawPhone' : '';

    final String finalName    = nameController.text.trim();
    final String finalEmail   = emailController.text.trim();
    final String finalCompany = companyNameController.text.trim();
    final String finalDate    = startDateController.text.trim();

    await _storage.write(key: 'user_name',      value: finalName);
    await _storage.write(key: 'user_email',     value: finalEmail);
    await _storage.write(key: 'user_phone',     value: fullPhone);
    await _storage.write(key: 'user_profession',value: _selectedProfession);
    await _storage.write(key: 'user_title',     value: composedTitle);
    await _storage.write(key: 'user_cert',      value: _selectedCertLevel);
    await _storage.write(key: 'user_emp_id',    value: fullCertNum);
    await _storage.write(key: 'user_company',   value: finalCompany);
    await _storage.write(key: 'user_company_start_date', value: finalDate);

    if (_base64Image != null) {
      await _storage.write(key: 'user_image_base64', value: _base64Image);
    }
    if (_companyLogoBase64 != null) {
      await _storage.write(
          key: 'user_company_logo', value: _companyLogoBase64);
    } else {
      await _storage.delete(key: 'user_company_logo');
    }

    if (mounted) {
      Navigator.pop(context, {
        'name':               finalName,
        'email':              finalEmail,
        'phone':              fullPhone,
        'profession':         _selectedProfession,
        'title':              composedTitle,
        'certLevel':          _selectedCertLevel,
        'certNumber':         fullCertNum,
        'startDate':          finalDate,
        'profileImageBase64': _base64Image,
        'companyName':        finalCompany,
        'companyLogoBase64':  _companyLogoBase64,
      });
    }
  }
}
