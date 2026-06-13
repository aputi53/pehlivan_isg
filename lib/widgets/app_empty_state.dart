import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pehlivan_isg/services/theme_service.dart';

/// Boş liste durumu için yeniden kullanılabilir widget.
class AppEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconColor,
  });

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final iconColor = widget.iconColor ?? colors.accent;

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedBuilder(
        animation: _slideAnim,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: child,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon dairesi
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.08),
                    border: Border.all(
                        color: iconColor.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Icon(widget.icon, color: iconColor, size: 42),
                ),
                const SizedBox(height: 20),
                // Başlık
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: colors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Alt başlık
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: colors.textMuted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
                // Aksiyon butonu
                if (widget.action != null) ...[
                  const SizedBox(height: 24),
                  widget.action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shimmer yükleme iskelet widget'ı.
class AppShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const AppShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, i) {
        return _ShimmerItem(
          colors: colors,
          height: itemHeight,
          delay: i * 60,
        );
      },
    );
  }
}

class _ShimmerItem extends StatefulWidget {
  final AppColors colors;
  final double height;
  final int delay;
  const _ShimmerItem(
      {required this.colors, required this.height, required this.delay});

  @override
  State<_ShimmerItem> createState() => _ShimmerItemState();
}

class _ShimmerItemState extends State<_ShimmerItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final shimmerValue =
            (((_ctrl.value * 2) + (widget.delay / 1000)).remainder(2));
        final t = shimmerValue < 1 ? shimmerValue : 2 - shimmerValue;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.colors.card,
                Color.lerp(widget.colors.card, widget.colors.cardDark, t)!,
                widget.colors.card,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}
