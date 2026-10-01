import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yandex_maps_mapkit_lite/init.dart' as yandex_mapkit;

import 'config/app_config.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/screens/maintenance_screen.dart';
import 'ui/screens/shell_screen.dart';
import 'ui/screens/welcome_screen.dart';
import 'ui/widgets/common.dart';
import 'ui/widgets/wasabi_page_background.dart';
import 'ui/widgets/wessabi_entrance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final mapkitApiKey = AppConfig.yandexMapkitApiKey;
  if (mapkitApiKey.isNotEmpty) {
    await yandex_mapkit.initMapkit(apiKey: mapkitApiKey);
  }
  final state = AppState();
  runApp(AppScope(state: state, child: const WasabiApp()));
  unawaited(state.init());
}

class WasabiApp extends StatelessWidget {
  const WasabiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wasabi Sushi',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: state.themeMode,
      locale: Locale(state.locale),
      supportedLocales: const [
        Locale('ru'),
        Locale('uz'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: !state.initialized
          ? const _StartupScreen()
          : !state.settings.siteEnabled
              ? MaintenanceScreen(locale: state.locale)
              : state.onboardingDone
                  ? const _StartupEntranceGate(child: ShellScreen())
                  : const WelcomeScreen(),
    );
  }
}

class _StartupEntranceGate extends StatefulWidget {
  const _StartupEntranceGate({required this.child});

  final Widget child;

  @override
  State<_StartupEntranceGate> createState() => _StartupEntranceGateState();
}

class _StartupEntranceGateState extends State<_StartupEntranceGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showEntrance = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: WessabiEntrance.duration,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final state = AppScope.of(context);
    // Do not replay the costly launch sequence on every warm/debug restart.
    // A completed launch is remembered just like it is in the release app.
    if (!state.entranceSeen) {
      _showEntrance = true;
      _controller.value = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_prepareAndPlay());
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _prepareAndPlay() async {
    // Start decoding the only bitmap up front without delaying the first
    // frame. The image remains cached for the logo transition.
    unawaited(precacheImage(const AssetImage('logo.png'), context));
    await _controller.forward();
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    await AppScope.of(context, listen: false).markEntranceSeen();
    if (!mounted) return;
    setState(() => _showEntrance = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        WessabiHomeOpeningScope(
          animation: _controller,
          child: widget.child,
        ),
        if (_showEntrance)
          Positioned.fill(
            child: AbsorbPointer(
              child: WessabiEntrance(animation: _controller),
            ),
          ),
      ],
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Stack(
        children: [
          Positioned.fill(child: WasabiPageBackground()),
          SafeArea(
            child: Center(
              child: SizedBox.square(
                dimension: 26,
                child: CircularProgressIndicator(
                  color: WasabiColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
