import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../widgets/wasabi_page_background.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key, required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final isUz = locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? WasabiColors.darkText : WasabiColors.dark;
    final mutedColor = isDark ? WasabiColors.darkMuted : WasabiColors.muted;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const WasabiPageBackground(animate: true),
          const _MaintenanceArtwork(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(26, 30, 26, 26),
                    decoration: BoxDecoration(
                      color: (isDark
                              ? WasabiColors.darkSurface
                              : Colors.white)
                          .withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: WasabiColors.primary.withValues(alpha: .34),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 78,
                          height: 78,
                          decoration: const BoxDecoration(
                            color: WasabiColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.construction_rounded,
                            color: Colors.white,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isUz ? 'Texnik tanaffus' : 'Технический перерыв',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isUz
                              ? 'Ilova vaqtincha yangilanmoqda. Tez orada siz bilan yana uchrashamiz.'
                              : 'Приложение временно обновляется. Мы скоро вернёмся.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: mutedColor,
                            fontSize: 16,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: WasabiColors.primary.withValues(alpha: .10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: WasabiColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isUz
                                      ? 'Xizmat sifatini yaxshilayapmiz'
                                      : 'Мы улучшаем сервис для вас',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceArtwork extends StatelessWidget {
  const _MaintenanceArtwork();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -52,
            child: _Orb(size: 220, color: WasabiColors.primary.withValues(alpha: .12)),
          ),
          Positioned(
            bottom: -68,
            left: -62,
            child: _Orb(size: 188, color: WasabiColors.secondary.withValues(alpha: .12)),
          ),
          Positioned(
            top: 118,
            left: 30,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: WasabiColors.secondary.withValues(alpha: .44),
              size: 22,
            ),
          ),
          Positioned(
            bottom: 136,
            right: 32,
            child: Icon(
              Icons.eco_rounded,
              color: WasabiColors.primary.withValues(alpha: .35),
              size: 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
