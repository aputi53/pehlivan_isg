import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pehlivan_isg/pages/ai_asistan_page.dart';
import 'package:pehlivan_isg/pages/aksiyon_page.dart';
import 'package:pehlivan_isg/pages/ayarlar_page.dart';
import 'package:pehlivan_isg/pages/firmalar_page.dart';
import 'package:pehlivan_isg/pages/profil_page.dart';
import 'package:pehlivan_isg/pages/raporlar_page.dart';
import 'package:pehlivan_isg/pages/takvim_page.dart';
import 'package:pehlivan_isg/screens/saha_denetim_screen.dart';
import 'package:pehlivan_isg/services/database_service.dart';
import 'package:pehlivan_isg/services/theme_service.dart';

// ══════════════════════════════════════════════════════════════════
//  ANA UYGULAMA KABUĞU — Bottom Navigation Shell
// ══════════════════════════════════════════════════════════════════

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;

  void _switchTab(int index) {
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      _DashboardPage(onSwitchTab: _switchTab),
      const SahaDenetimScreen(),
      const FirmalarPage(),
      const AksiyanPage(),
      const _DigerlerPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildNavBar(colors, isDark),
    );
  }

  Widget _buildNavBar(AppColors colors, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard_rounded,
                label: 'Ana Sayfa',
                index: 0,
                selected: _selectedIndex == 0,
                colors: colors,
                onTap: _switchTab,
              ),
              _NavItem(
                icon: Icons.location_on_outlined,
                selectedIcon: Icons.location_on_rounded,
                label: 'Saha',
                index: 1,
                selected: _selectedIndex == 1,
                colors: colors,
                onTap: _switchTab,
              ),
              _NavItem(
                icon: Icons.business_outlined,
                selectedIcon: Icons.business_rounded,
                label: 'Firmalar',
                index: 2,
                selected: _selectedIndex == 2,
                colors: colors,
                onTap: _switchTab,
              ),
              _NavItem(
                icon: Icons.task_alt_outlined,
                selectedIcon: Icons.task_alt_rounded,
                label: 'Görevler',
                index: 3,
                selected: _selectedIndex == 3,
                colors: colors,
                onTap: _switchTab,
              ),
              _NavItem(
                icon: Icons.apps_outlined,
                selectedIcon: Icons.apps_rounded,
                label: 'Daha Fazla',
                index: 4,
                selected: _selectedIndex == 4,
                colors: colors,
                onTap: _switchTab,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  NAV ITEM (Custom — animate edilmiş)
// ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  final bool selected;
  final AppColors colors;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected
                    ? colors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? selectedIcon : icon,
                  key: ValueKey(selected),
                  color: selected
                      ? colors.accent
                      : colors.textMuted.withValues(alpha: 0.75),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.inter(
                color: selected
                    ? colors.accent
                    : colors.textMuted.withValues(alpha: 0.75),
                fontSize: 10.5,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DASHBOARD SAYFASI
// ══════════════════════════════════════════════════════════════════

class _DashboardPage extends StatefulWidget {
  final ValueChanged<int> onSwitchTab;
  const _DashboardPage({required this.onSwitchTab});

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage>
    with AutomaticKeepAliveClientMixin {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'PehlivanISG_Storage',
    ),
  );

  String _kullaniciAdi = '';
  String? _profileImageBase64;
  int _firmaCount = 0;
  int _surenDolan = 0;
  int _bekleyenGorev = 0;
  int _toplamGorev = 0;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final name = await _storage.read(key: 'user_name');
    final image = await _storage.read(key: 'user_image_base64');
    final firmalar = await DatabaseService.getAllFirmalar();
    final expiring =
        await DatabaseService.getExpiringBelgeler(daysThreshold: 30);
    final aksiyonlar = await DatabaseService.getAksiyonlar();
    final bekleyen =
        aksiyonlar.where((a) => !(a['tamamlandi'] as bool)).length;

    if (mounted) {
      setState(() {
        _kullaniciAdi = name ?? '';
        _profileImageBase64 = image;
        _firmaCount = firmalar.length;
        _surenDolan = expiring.length;
        _bekleyenGorev = bekleyen;
        _toplamGorev = aksiyonlar.length;
        _isLoading = false;
      });
    }
  }

  String get _selamlama {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Günaydın';
    if (h >= 12 && h < 18) return 'İyi Günler';
    return 'İyi Akşamlar';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      body: RefreshIndicator(
        color: colors.accent,
        backgroundColor: colors.card,
        onRefresh: _loadStats,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(colors),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── STAT KARTLARI ──────────────────────────────
                  _isLoading
                      ? _ShimmerStats(colors: colors)
                      : _StatsRow(
                          firmaCount: _firmaCount,
                          surenDolan: _surenDolan,
                          bekleyenGorev: _bekleyenGorev,
                          colors: colors,
                          onTapFirma: () => widget.onSwitchTab(2),
                          onTapSuren: () => Navigator.push(
                            context,
                            _fadeRoute(const TakvimPage()),
                          ),
                          onTapGorev: () => widget.onSwitchTab(3),
                        ),
                  const SizedBox(height: 24),

                  // ── AKSİYON GRAFİĞİ (veri varsa) ─────────────
                  if (!_isLoading && _toplamGorev > 0) ...[
                    _AksiyanGrafigi(
                      tamamlanan: _toplamGorev - _bekleyenGorev,
                      bekleyen: _bekleyenGorev,
                      toplam: _toplamGorev,
                      colors: colors,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── HIZLI ERİŞİM ───────────────────────────────
                  _SectionTitle(title: 'HIZLI ERİŞİM', colors: colors),
                  const SizedBox(height: 12),
                  _buildQuickGrid(colors),
                  const SizedBox(height: 24),

                  // ── AI ASISTAN KARTI ───────────────────────────
                  _AiAsistanKart(
                    onTap: () => Navigator.push(
                      context,
                      _fadeRoute(const AiAsistanPage()),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Collapsing AppBar ──────────────────────────────────────────
  Widget _buildSliverAppBar(AppColors colors) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 130,
      backgroundColor: colors.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      // Küçük AppBar (pinned durum)
      title: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: colors.accent.withValues(alpha: 0.4), width: 1.2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.asset(
                'assets/ana ekran logo.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                    Icons.shield_outlined,
                    color: colors.accent,
                    size: 18),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            'PehlivanİSG',
            style: GoogleFonts.outfit(
              color: colors.accent,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded,
              color: colors.textMuted, size: 20),
          onPressed: _loadStats,
          tooltip: 'Yenile',
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: colors.border),
      ),
      // Açılır başlık (expanded durum)
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _buildHeader(colors),
      ),
    );
  }

  Widget _buildHeader(AppColors colors) {
    final isDark = colors.bg == const Color(0xFF0D1117);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF161B22), const Color(0xFF1C2333)]
              : [Colors.white, const Color(0xFFEEF1F5)],
        ),
      ),
      child: Stack(
        children: [
          // Arka plan dekorasyon
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -50,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent.withValues(alpha: 0.04),
              ),
            ),
          ),
          // İçerik
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      // Logo
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colors.accent.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.accent.withValues(alpha: 0.22),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/ana ekran logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                                Icons.shield_outlined,
                                color: colors.accent,
                                size: 26),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Greeting
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selamlama,
                              style: GoogleFonts.inter(
                                color: colors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _kullaniciAdi.isNotEmpty
                                  ? _kullaniciAdi
                                  : 'Hoş Geldiniz',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: colors.text,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'İSG Yönetim Sistemi',
                                  style: GoogleFonts.inter(
                                    color: colors.accent,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Profil avatar
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          _fadeRoute(const ProfilPage()),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.accent.withValues(alpha: 0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.accent.withValues(alpha: 0.18),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 27,
                            backgroundColor:
                                colors.accent.withValues(alpha: 0.12),
                            backgroundImage: _profileImageBase64 != null
                                ? MemoryImage(
                                    base64Decode(_profileImageBase64!))
                                : null,
                            child: _profileImageBase64 == null
                                ? Icon(Icons.person_outline,
                                    color: colors.accent, size: 26)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hızlı Erişim Grid ─────────────────────────────────────────
  Widget _buildQuickGrid(AppColors colors) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.85,
      children: [
        _QuickCard(
          baslik: 'Saha Denetim',
          aciklama: 'Grup & firma ziyaret takibi',
          icon: Icons.location_on_rounded,
          renk: colors.accent,
          onTap: () => widget.onSwitchTab(1),
        ),
        _QuickCard(
          baslik: 'Takvim',
          aciklama: 'Yaklaşan son tarihler',
          icon: Icons.calendar_month_rounded,
          renk: const Color(0xFF81C784),
          badge: _surenDolan > 0 ? '$_surenDolan' : null,
          onTap: () => Navigator.push(
              context, _fadeRoute(const TakvimPage())),
        ),
        _QuickCard(
          baslik: 'Raporlar',
          aciklama: 'Denetim özetleri & görseller',
          icon: Icons.bar_chart_rounded,
          renk: const Color(0xFFCE93D8),
          onTap: () => Navigator.push(
              context, _fadeRoute(const RaporlarPage())),
        ),
        _QuickCard(
          baslik: 'İSG Katip',
          aciklama: 'Bakanlık sistemi girişi',
          icon: Icons.open_in_browser_rounded,
          renk: const Color(0xFF80DEEA),
          isExternal: true,
          onTap: () async {
            final uri = Uri.parse('https://isgkatip.csgb.gov.tr');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri,
                  mode: LaunchMode.externalApplication);
            }
          },
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  STAT KARTLARI
// ══════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  final int firmaCount;
  final int surenDolan;
  final int bekleyenGorev;
  final AppColors colors;
  final VoidCallback onTapFirma;
  final VoidCallback onTapSuren;
  final VoidCallback onTapGorev;

  const _StatsRow({
    required this.firmaCount,
    required this.surenDolan,
    required this.bekleyenGorev,
    required this.colors,
    required this.onTapFirma,
    required this.onTapSuren,
    required this.onTapGorev,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.business_rounded,
            color: const Color(0xFF4FC3F7),
            value: firmaCount,
            label: 'Firma',
            colors: colors,
            onTap: onTapFirma,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.warning_rounded,
            color: surenDolan > 0 ? const Color(0xFFFFB74D) : const Color(0xFF4CAF50),
            value: surenDolan,
            label: '30 Gün\nUyarı',
            colors: colors,
            onTap: onTapSuren,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AnimatedStatCard(
            icon: Icons.task_alt_rounded,
            color: bekleyenGorev > 0
                ? colors.accent
                : const Color(0xFF4CAF50),
            value: bekleyenGorev,
            label: 'Bekleyen\nGörev',
            colors: colors,
            onTap: onTapGorev,
          ),
        ),
      ],
    );
  }
}

class _AnimatedStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  final AppColors colors;
  final VoidCallback onTap;

  const _AnimatedStatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => Text(
                '${val.toInt()}',
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: colors.textMuted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  SHIMMER LOADING
// ──────────────────────────────────────────────────────────────────

class _ShimmerStats extends StatelessWidget {
  final AppColors colors;
  const _ShimmerStats({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: colors.card,
      highlightColor: colors.cardDark,
      child: Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              height: 100,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  AKSİYON DURUM GRAFİĞİ (fl_chart PieChart)
// ──────────────────────────────────────────────────────────────────

class _AksiyanGrafigi extends StatefulWidget {
  final int tamamlanan;
  final int bekleyen;
  final int toplam;
  final AppColors colors;

  const _AksiyanGrafigi({
    required this.tamamlanan,
    required this.bekleyen,
    required this.toplam,
    required this.colors,
  });

  @override
  State<_AksiyanGrafigi> createState() => _AksiyanGrafigiState();
}

class _AksiyanGrafigiState extends State<_AksiyanGrafigi> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final oran = widget.toplam > 0 ? widget.tamamlanan / widget.toplam : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pie Chart
          SizedBox(
            width: 100,
            height: 100,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 3,
                centerSpaceRadius: 32,
                sections: [
                  PieChartSectionData(
                    value: widget.tamamlanan > 0
                        ? widget.tamamlanan.toDouble()
                        : 0.001,
                    color: const Color(0xFF4CAF50),
                    title: '',
                    radius: _touchedIndex == 0 ? 18 : 14,
                  ),
                  PieChartSectionData(
                    value: widget.bekleyen > 0
                        ? widget.bekleyen.toDouble()
                        : 0.001,
                    color: widget.colors.accent,
                    title: '',
                    radius: _touchedIndex == 1 ? 18 : 14,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Açıklama
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aksiyon Durumu',
                  style: GoogleFonts.outfit(
                    color: widget.colors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _LegendItem(
                  color: const Color(0xFF4CAF50),
                  label: 'Tamamlanan',
                  value: widget.tamamlanan,
                  colors: widget.colors,
                ),
                const SizedBox(height: 6),
                _LegendItem(
                  color: widget.colors.accent,
                  label: 'Bekleyen',
                  value: widget.bekleyen,
                  colors: widget.colors,
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: oran,
                    backgroundColor: widget.colors.cardDark,
                    valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF4CAF50)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '%${(oran * 100).toStringAsFixed(0)} tamamlandı',
                  style: GoogleFonts.inter(
                    color: widget.colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final AppColors colors;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 7),
        Text(label,
            style: GoogleFonts.inter(
                color: colors.textMuted, fontSize: 11)),
        const Spacer(),
        Text(
          '$value',
          style: GoogleFonts.inter(
            color: colors.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  HIZLI ERİŞİM KARTI
// ──────────────────────────────────────────────────────────────────

class _QuickCard extends StatelessWidget {
  final String baslik;
  final String aciklama;
  final IconData icon;
  final Color renk;
  final VoidCallback onTap;
  final String? badge;
  final bool isExternal;

  const _QuickCard({
    required this.baslik,
    required this.aciklama,
    required this.icon,
    required this.renk,
    required this.onTap,
    this.badge,
    this.isExternal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: renk.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: renk.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: renk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: renk, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          baslik,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: colors.text,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (isExternal)
                        Icon(
                          Icons.open_in_new,
                          color: colors.textMuted.withValues(alpha: 0.5),
                          size: 11,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    aciklama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: colors.textMuted.withValues(alpha: 0.9),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  AI ASISTAN KARTI
// ──────────────────────────────────────────────────────────────────

class _AiAsistanKart extends StatelessWidget {
  final VoidCallback onTap;
  const _AiAsistanKart({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B1F91), Color(0xFF6C3EE8), Color(0xFF9562FF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI İSG Asistanı',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kanun, yönetmelik ve risk değerlendirmesi için',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF69FF47),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Aktif',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  SECTION TITLE
// ──────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final AppColors colors;

  const _SectionTitle({required this.title, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: colors.accent.withValues(alpha: 0.55),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: colors.text.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  "DAHA FAZLASI" SAYFASI
// ══════════════════════════════════════════════════════════════════

class _DigerlerPage extends StatelessWidget {
  const _DigerlerPage();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Daha Fazlası',
          style: GoogleFonts.outfit(
            color: colors.text,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colors.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'ÖZELLİKLER', colors: colors),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _DigerItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Takvim',
                  sublabel: 'Yaklaşan son tarihler',
                  color: const Color(0xFF81C784),
                  onTap: () => Navigator.push(
                      context, _fadeRoute(const TakvimPage())),
                ),
                _DigerItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Raporlar',
                  sublabel: 'Denetim özetleri',
                  color: const Color(0xFFCE93D8),
                  onTap: () => Navigator.push(
                      context, _fadeRoute(const RaporlarPage())),
                ),
                _DigerItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'AI Asistan',
                  sublabel: 'İSG uzmanı chatbot',
                  color: const Color(0xFF7C4DFF),
                  onTap: () => Navigator.push(
                      context, _fadeRoute(const AiAsistanPage())),
                ),
                _DigerItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Profil',
                  sublabel: 'Kullanıcı bilgilerim',
                  color: const Color(0xFF4FC3F7),
                  onTap: () => Navigator.push(
                      context, _fadeRoute(const ProfilPage())),
                ),
                _DigerItem(
                  icon: Icons.settings_outlined,
                  label: 'Ayarlar',
                  sublabel: 'Tema, güvenlik, yedek',
                  color: const Color(0xFFFFB74D),
                  onTap: () => Navigator.push(
                      context, _fadeRoute(const AyarlarPage())),
                ),
                _DigerItem(
                  icon: Icons.open_in_browser_rounded,
                  label: 'İSG Katip',
                  sublabel: 'Bakanlık sistemi',
                  color: const Color(0xFF80DEEA),
                  isExternal: true,
                  onTap: () async {
                    final uri =
                        Uri.parse('https://isgkatip.csgb.gov.tr');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(title: 'DESTEK', colors: colors),
            const SizedBox(height: 14),
            _GeriBildirimButon(colors: colors),
            const SizedBox(height: 8),
            _RamakKalaButon(colors: colors),
            const SizedBox(height: 28),
            Center(
              child: Column(
                children: [
                  Text(
                    'PehlivanİSG v1.0.0',
                    style: GoogleFonts.inter(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'İSG Yönetim ve Denetim Sistemi',
                    style: GoogleFonts.inter(
                      color: colors.textMuted.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;
  final bool isExternal;

  const _DigerItem({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
    this.isExternal = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (isExternal)
                  Icon(
                    Icons.open_in_new,
                    color: colors.textMuted.withValues(alpha: 0.5),
                    size: 12,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: colors.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GeriBildirimButon extends StatelessWidget {
  final AppColors colors;
  const _GeriBildirimButon({required this.colors});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(
          scheme: 'mailto',
          path: 'fa.pehlivan53@gmail.com',
          queryParameters: {'subject': 'PehlivanİSG - Geri Bildirim'},
        );
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.rate_review_outlined,
                  color: colors.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geri Bildirim Gönder',
                    style: GoogleFonts.inter(
                      color: colors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'fa.pehlivan53@gmail.com',
                    style: GoogleFonts.inter(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _RamakKalaButon extends StatelessWidget {
  final AppColors colors;
  const _RamakKalaButon({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ramak Kala',
                  style: GoogleFonts.inter(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Yakında geliyor...',
                  style: GoogleFonts.inter(
                    color: colors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Yakında',
              style: GoogleFonts.inter(
                color: Colors.orange,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
//  FADE ROUTE (smooth sayfa geçişi)
// ──────────────────────────────────────────────────────────────────

Route<T> _fadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ),
        child: child,
      );
    },
  );
}
