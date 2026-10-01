import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'auth_screen.dart';
import 'shell_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final locale = state.locale;
    final isUz = locale == 'uz';
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(40)),
              child: const _WelcomeHero(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.isUzEnabled) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'ru', label: Text('Русский')),
                        ButtonSegment(value: 'uz', label: Text('Uzbek')),
                      ],
                      selected: {locale},
                      onSelectionChanged: (value) =>
                          state.setLocale(value.first),
                    ),
                    const SizedBox(height: 14),
                  ],
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    icon: const Icon(Icons.phone_iphone_outlined),
                    label: Text(isUz
                        ? 'Telefon orqali kirish'
                        : 'Войти по номеру телефона'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await state.finishOnboarding();
                      if (!context.mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ShellScreen()),
                      );
                    },
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(isUz
                        ? 'Mehmon sifatida davom etish'
                        : 'Продолжить как гость'),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isUz
                        ? 'Davom etish orqali xizmat shartlariga rozilik bildirasiz'
                        : 'Продолжая, вы соглашаетесь с условиями сервиса',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0x80141414),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/welcome_sushi.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000),
                Color(0x22000000),
                Color(0xCC0E150C),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
