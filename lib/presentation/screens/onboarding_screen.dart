import 'package:flutter/material.dart';

import 'package:wojob/core/theme/app_colors.dart';
import 'package:wojob/presentation/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final Future<void> Function() onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      eyebrow: 'ASISTENCIA SIMPLE',
      title: 'Control de asistencia',
      description:
          'Registra la hora de entrada y salida de cada jornada. El empleado '
          'puede marcar su asistencia y el administrador consultar el historial '
          'del equipo desde la sala.',
      icon: Icons.fact_check_outlined,
      detailIcon: Icons.check_circle,
      detail: 'Marcación registrada',
    ),
    _OnboardingPageData(
      eyebrow: 'REGISTROS CONFIABLES',
      title: 'Ubicación GPS',
      description:
          'Cada marcación registra la ubicación GPS y requiere una fotografía. '
          'Así el historial muestra cuándo, dónde y con qué evidencia se '
          'realizó el registro.',
      icon: Icons.location_on_outlined,
      detailIcon: Icons.camera_alt_outlined,
      detail: 'Foto y ubicación',
    ),
    _OnboardingPageData(
      eyebrow: 'EQUIPO ORGANIZADO',
      title: 'Gestión de horarios',
      description:
          'El administrador crea salas, gestiona solicitudes de ingreso y '
          'asigna turnos. Cada empleado puede consultar los horarios de su '
          'equipo desde su propia sala.',
      icon: Icons.calendar_month_outlined,
      detailIcon: Icons.schedule,
      detail: 'Salas, turnos y equipo',
    ),
  ];

  final _pageController = PageController();
  int _currentPage = 0;
  bool _isCompleting = false;

  static const _pageCount = 4;
  bool get _isLastPage => _currentPage == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isLastPage) {
      setState(() => _isCompleting = true);
      try {
        await widget.onComplete();
      } catch (error, stackTrace) {
        debugPrint('No se pudo completar el onboarding: $error');
        debugPrintStack(stackTrace: stackTrace);
        if (mounted) {
          setState(() => _isCompleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo guardar el inicio. Inténtalo nuevamente.',
              ),
            ),
          );
        }
      }
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 92,
                          height: 34,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_currentPage + 1} de $_pageCount',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.62,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ASÍ FUNCIONA WOJOB',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pageCount,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      itemBuilder: (context, index) {
                        if (index == _pages.length) {
                          return _WelcomePage(isDark: isDark);
                        }
                        return _FeaturePage(
                          data: _pages[index],
                          isDark: isDark,
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    onPressed: _isCompleting ? null : _next,
                    label: _isCompleting
                        ? 'Guardando…'
                        : _isLastPage
                        ? 'Comenzar'
                        : 'Siguiente',
                    icon: _isLastPage ? Icons.arrow_forward : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({required this.data, required this.isDark});

  final _OnboardingPageData data;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.43).clamp(
          170.0,
          280.0,
        );
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: illustrationHeight,
                  child: _Illustration(data: data),
                ),
                const SizedBox(height: 28),
                Text(
                  data.eyebrow,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: isDark ? 0.76 : 0.68,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: AspectRatio(
        aspectRatio: 1.22,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            Container(
              width: 166,
              height: 166,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.brandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Icon(data.icon, color: Colors.white, size: 72),
            ),
            Positioned(
              top: 24,
              right: 12,
              child: _FloatingBadge(
                icon: Icons.work_outline,
                color: theme.colorScheme.surface,
              ),
            ),
            Positioned(
              bottom: 20,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(data.detailIcon, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      data.detail,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: AppColors.primary, size: 26),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 36,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/logo.png',
                width: 220,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '¡Bienvenido a WoJob!',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Todo listo para ayudarte a organizar la asistencia y los '
                'horarios de tu equipo.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
    required this.detailIcon,
    required this.detail,
  });

  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;
  final IconData detailIcon;
  final String detail;
}
