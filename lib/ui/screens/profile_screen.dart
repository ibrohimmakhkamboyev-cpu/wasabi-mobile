import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/wasabi_page_background.dart';
import 'addresses_screen.dart';
import 'auth_screen.dart';
import 'mailings_screen.dart';
import 'orders_screen.dart';
import 'saved_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.reserveBottomNavSpace = false});

  final bool? reserveBottomNavSpace;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ScrollController _scrollController;

  @override
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(keepScrollOffset: false);
  }

  @override
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    if (!state.isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyState(
                icon: Icons.person_outline,
                title: isUz ? 'Profilga kiring' : 'Войдите в профиль',
                text: isUz
                    ? 'Bonuslar, manzillar va buyurtmalar tarixi uchun.'
                    : 'Для бонусов, адресов доставки и истории заказов.',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const AuthScreen())),
                icon: const Icon(Icons.login),
                label: Text(isUz ? 'Kirish' : 'Войти'),
              ),
            ],
          ),
        ),
      );
    }

    final user = state.user!;
    final addressCount = state.addresses.length;
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 820;
          final dense = constraints.maxHeight < 735;

          final bottomNavClearance =
              widget.reserveBottomNavSpace == true ? 136.0 : 92.0;
          final topProfilePadding = widget.reserveBottomNavSpace == true
              ? (dense ? 28.0 : (compact ? 30.0 : 32.0))
              : (dense ? 6.0 : (compact ? 12.0 : 26.0));

          return ColoredBox(
            color: Colors.transparent,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: bottomNavClearance),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      34,
                      topProfilePadding,
                      34,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHeroCard(
                          compact: compact,
                          dense: dense,
                          name: user.name.isEmpty
                              ? (isUz ? 'Mehmon' : 'Гость')
                              : user.name,
                          phone: user.phone,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen(),
                            ),
                          ),
                        ),
                        SizedBox(height: dense ? 14 : (compact ? 16 : 18)),
                        _ProfileGroup(
                          compact: compact,
                          dense: dense,
                          children: [
                            _ProfileTile(
                              key: const ValueKey('profile-tile-addresses'),
                              compact: compact,
                              dense: dense,
                              icon: Icons.location_on_outlined,
                              title: isUz
                                  ? 'Yetkazish manzillari'
                                  : 'Адреса доставки',
                              subtitle: isUz
                                  ? '$addressCount manzil saqlangan'
                                  : '$addressCount адрес сохранен',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddressesScreen(),
                                ),
                              ),
                            ),
                            _ProfileTile(
                              compact: compact,
                              dense: dense,
                              icon: Icons.receipt_long_outlined,
                              title: isUz
                                  ? 'Buyurtmalar tarixi'
                                  : 'История заказов',
                              subtitle: isUz
                                  ? 'Avvalgi buyurtmalar va holati'
                                  : 'Предыдущие заказы и статус',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const OrdersScreen(),
                                ),
                              ),
                            ),
                            _ProfileTile(
                              compact: compact,
                              dense: dense,
                              icon: Icons.favorite_border_rounded,
                              title: isUz ? 'Saqlanganlar' : 'Сохраненные',
                              subtitle: isUz
                                  ? '${state.savedCount} mahsulot saqlangan'
                                  : '${state.savedCount} товаров сохранено',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const SavedScreen(),
                                ),
                              ),
                            ),
                            _ProfileTile(
                              compact: compact,
                              dense: dense,
                              icon: Icons.mail_outline_rounded,
                              title: isUz ? 'Xabarlar' : 'Рассылки',
                              subtitle: isUz
                                  ? 'Admin paneldan yuborilgan xabarlar'
                                  : 'Сообщения из админ-панели',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MailingsScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: dense ? 12 : (compact ? 14 : 16)),
                        _ProfileTile(
                          compact: compact,
                          dense: dense,
                          icon: state.themeMode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          title: state.themeMode == ThemeMode.dark
                              ? (isUz ? 'Oq rejim' : 'Светлый режим')
                              : (isUz ? 'Qorong‘i rejim' : 'Темный режим'),
                          subtitle: state.themeMode == ThemeMode.dark
                              ? (isUz
                                  ? 'Ilovani oq rangga o‘tkazish'
                                  : 'Переключить приложение на светлую тему')
                              : (isUz
                                  ? 'Ilovani qorong‘i rangga o‘tkazish'
                                  : 'Переключить приложение на темную тему'),
                          onTap: state.toggleThemeMode,
                        ),
                        SizedBox(height: dense ? 10 : (compact ? 12 : 14)),
                        _ProfileLanguageCard(
                          locale: state.locale,
                          isUzEnabled: state.isUzEnabled,
                          onChanged: (value) => state.setLocale(value),
                        ),
                        SizedBox(height: dense ? 12 : (compact ? 14 : 16)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _ProfileDangerButton(
                              dense: dense,
                              compact: compact,
                              icon: Icons.delete_outline_rounded,
                              label: isUz
                                  ? 'Akkauntni o‘chirish'
                                  : 'Удалить аккаунт',
                              onPressed: () => _confirmDeleteAccount(context),
                            ),
                            const SizedBox(height: 12),
                            _ProfileDangerButton(
                              dense: dense,
                              compact: compact,
                              icon: Icons.logout_rounded,
                              label: isUz ? 'Chiqish' : 'Выйти',
                              onPressed: () async {
                                await state.logout();
                                if (!context.mounted) return;
                                showWasabiMessage(
                                  context,
                                  isUz ? 'Chiqildi' : 'Вы вышли из аккаунта',
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final state = AppScope.of(context, listen: false);
    final isUz = state.locale == 'uz';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isUz ? 'Akkauntni o‘chirish' : 'Удалить аккаунт'),
        content: Text(
          isUz
              ? 'Akkaunt ma’lumotlari ushbu qurilmadan o‘chiriladi.'
              : 'Данные аккаунта будут удалены с этого устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(isUz ? 'Bekor qilish' : 'Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD43C33),
            ),
            child: Text(isUz ? 'O‘chirish' : 'Удалить'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await state.logout();
    if (!context.mounted) return;
    showWasabiMessage(
      context,
      isUz ? 'Akkaunt o‘chirildi' : 'Аккаунт удален',
    );
  }
}

class _ProfileDangerButton extends StatelessWidget {
  const _ProfileDangerButton({
    required this.dense,
    required this.compact,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool dense;
  final bool compact;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(dense ? 46 : (compact ? 50 : 58)),
        foregroundColor: const Color(0xFFD43C33),
        side: BorderSide(
          color: const Color(0xFFD43C33).withValues(alpha: 0.35),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: TextStyle(
          fontSize: dense ? 14 : (compact ? 15 : 16),
          fontWeight: FontWeight.w900,
        ),
      ),
      icon: Icon(icon),
      label: FittedBox(child: Text(label)),
    );
  }
}

class _ProfileLanguageCard extends StatelessWidget {
  const _ProfileLanguageCard({
    required this.locale,
    required this.isUzEnabled,
    required this.onChanged,
  });

  final String locale;
  final bool isUzEnabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isUz = locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF11170D) : Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .30)
              : const Color(0xFFE6E3D6),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .36)
                : const Color(0x14000000),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0B0F08) : const Color(0xFFF6F7EF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? WasabiColors.primary.withValues(alpha: .18)
                    : const Color(0xFFE6E3D6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LanguageOption(
                    label: 'Русский',
                    flag: '🇷🇺',
                    selected: !isUz,
                    onTap: () => onChanged('ru'),
                  ),
                ),
                Expanded(
                  child: _LanguageOption(
                    label: 'Uzbek',
                    flag: '🇺🇿',
                    selected: isUz,
                    onTap: isUzEnabled ? () => onChanged('uz') : null,
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

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String flag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected
          ? WasabiColors.primary
          : isDark
              ? const Color(0xFF172010)
              : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : isDark
                            ? Colors.white.withValues(alpha: .78)
                            : WasabiColors.dark,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(
                  Icons.check_rounded,
                  color: selected ? Colors.white : WasabiColors.primary,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = AppScope.of(context, listen: false).user;
    _name = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final user = state.user;
    final isUz = state.locale == 'uz';
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(child: WasabiPageBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;
                final maxWidth =
                    constraints.maxWidth > 640 ? 600.0 : double.infinity;
                final horizontal = compact ? 20.0 : 30.0;

                return Stack(
                  children: [
                    const Positioned(
                      top: 6,
                      right: 0,
                      child: IgnorePointer(child: _ProfileEditLeafAccent()),
                    ),
                    SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding:
                          EdgeInsets.fromLTRB(horizontal, 20, horizontal, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _ProfileEditHeader(
                                compact: compact,
                                title: isUz
                                    ? 'Profilni tahrirlash'
                                    : 'Редактировать профиль',
                                subtitle: isUz
                                    ? 'Ma’lumotlaringizni yangilang'
                                    : 'Обновите свои данные',
                                onBack: () => Navigator.of(context).maybePop(),
                              ),
                              SizedBox(height: compact ? 28 : 36),
                              _ProfileEditNameCard(
                                compact: compact,
                                controller: _name,
                                label: isUz ? 'Ism' : 'Имя',
                                saveLabel: isUz ? 'Saqlash' : 'Сохранить',
                                saving: _saving,
                                onSave: _saveName,
                              ),
                              SizedBox(height: compact ? 20 : 26),
                              _ProfileEditPhoneCard(
                                compact: compact,
                                title:
                                    isUz ? 'Telefon raqami' : 'Номер телефона',
                                phone: user.phone,
                                verifiedLabel:
                                    isUz ? 'Tasdiqlangan' : 'Подтвержден',
                                actionLabel: isUz
                                    ? 'Telefon raqamini o‘zgartirish'
                                    : 'Изменить номер телефона',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfilePhoneChangeScreen(
                                      initialPhone: _editablePhone(user.phone),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: compact ? 20 : 26),
                              const _ProfileEditTrustDivider(),
                              SizedBox(height: compact ? 24 : 34),
                              _ProfileEditPromoCard(compact: compact),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveName() async {
    final state = AppScope.of(context, listen: false);
    final user = state.user;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await state.updateProfile(name: _name.text.trim(), phone: user.phone);
      if (!mounted) return;
      showWasabiMessage(
        context,
        state.locale == 'uz' ? 'Profil saqlandi' : 'Профиль сохранен',
      );
    } catch (error) {
      if (!mounted) return;
      showWasabiMessage(
        context,
        _profileErrorText(error, state.locale),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ProfileEditHeader extends StatelessWidget {
  const _ProfileEditHeader({
    required this.compact,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final bool compact;
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Material(
          color: isDark ? const Color(0xFF11180D) : Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          shadowColor: const Color(0x18000000),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onBack,
            child: SizedBox.square(
              dimension: compact ? 58 : 68,
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF151A15),
                size: compact ? 24 : 28,
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 18 : 28),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF142214),
                  fontSize: compact ? 26 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: .68)
                      : const Color(0xFF74736F),
                  fontSize: compact ? 17 : 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileEditNameCard extends StatelessWidget {
  const _ProfileEditNameCard({
    required this.compact,
    required this.controller,
    required this.label,
    required this.saveLabel,
    required this.saving,
    required this.onSave,
  });

  final bool compact;
  final TextEditingController controller;
  final String label;
  final String saveLabel;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ProfileEditCard(
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 24,
        compact ? 20 : 28,
        compact ? 16 : 24,
        compact ? 20 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ProfileEditCircleIcon(
                icon: Icons.person_outline_rounded,
                size: compact ? 54 : 64,
                iconSize: compact ? 28 : 34,
                background: isDark
                    ? WasabiColors.primary.withValues(alpha: .16)
                    : const Color(0xFFF1F7DF),
                color: WasabiColors.primary,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: compact ? 14 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: WasabiColors.primary,
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compact ? 'Profil nomi' : 'Profil ko‘rinadigan nomi',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: .60)
                              : WasabiColors.muted,
                          fontSize: compact ? 12 : 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 18 : 24),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF171717),
              fontSize: compact ? 22 : 26,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: .40)
                    : WasabiColors.muted,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: compact ? 18 : 22,
                vertical: compact ? 15 : 18,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ProfileEditCircleIcon(
                  icon: Icons.edit_outlined,
                  size: compact ? 40 : 46,
                  iconSize: compact ? 22 : 26,
                  background: isDark
                      ? WasabiColors.primary.withValues(alpha: .18)
                      : const Color(0xFFF0F6DE),
                  color: WasabiColors.primary,
                ),
              ),
              suffixIconConstraints: BoxConstraints(
                minWidth: compact ? 56 : 64,
                minHeight: compact ? 56 : 64,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF0B1008) : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: isDark
                      ? WasabiColors.primary.withValues(alpha: .26)
                      : const Color(0xFFE2E5E7),
                  width: 1.4,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: WasabiColors.primary,
                  width: 1.8,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 22 : 28),
          _ProfileEditSaveButton(
            compact: compact,
            saving: saving,
            label: saveLabel,
            onTap: saving ? null : onSave,
          ),
        ],
      ),
    );
  }
}

class _ProfileEditPhoneCard extends StatelessWidget {
  const _ProfileEditPhoneCard({
    required this.compact,
    required this.title,
    required this.phone,
    required this.verifiedLabel,
    required this.actionLabel,
    required this.onTap,
  });

  final bool compact;
  final String title;
  final String phone;
  final String verifiedLabel;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ProfileEditCard(
      padding: EdgeInsets.all(compact ? 20 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF151A15),
              fontSize: compact ? 25 : 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: compact ? 28 : 38),
          Row(
            children: [
              _ProfileEditCircleIcon(
                icon: Icons.phone_outlined,
                size: compact ? 58 : 66,
                iconSize: compact ? 28 : 34,
                background: isDark
                    ? WasabiColors.primary.withValues(alpha: .16)
                    : const Color(0xFFF0F6DE),
                color: WasabiColors.primary,
              ),
              SizedBox(width: compact ? 14 : 20),
              Expanded(
                child: Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF171717),
                    fontSize: compact ? 18 : 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(width: compact ? 10 : 14),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 14,
                      vertical: compact ? 7 : 9,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? WasabiColors.primary.withValues(alpha: .18)
                          : const Color(0xFFEFF4DF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: WasabiColors.primary,
                          size: compact ? 17 : 21,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          verifiedLabel,
                          style: TextStyle(
                            color: WasabiColors.primary,
                            fontSize: compact ? 13 : 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 26 : 34),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              minimumSize: Size.fromHeight(compact ? 62 : 78),
              backgroundColor: isDark ? const Color(0xFF0B1008) : Colors.white,
              foregroundColor: isDark ? Colors.white : const Color(0xFF141414),
              side: BorderSide(
                color: isDark
                    ? WasabiColors.primary.withValues(alpha: .24)
                    : const Color(0xFFE2E5E7),
                width: 1.3,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 24),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sms_outlined,
                  color: WasabiColors.primary,
                  size: compact ? 26 : 31,
                ),
                SizedBox(width: compact ? 14 : 22),
                Expanded(
                  child: Text(
                    actionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 18 : 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color:
                      isDark ? WasabiColors.primary : const Color(0xFF111111),
                  size: compact ? 30 : 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileEditPromoCard extends StatelessWidget {
  const _ProfileEditPromoCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ProfileEditCard(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 28,
        compact ? 34 : 46,
        compact ? 20 : 28,
        compact ? 30 : 38,
      ),
      child: Column(
        children: [
          Text(
            'Wasabi Sushi bilan tez va oson buyurtma qiling!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF182018),
              fontSize: compact ? 18 : 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: compact ? 22 : 28),
          Icon(
            Icons.favorite_rounded,
            color: const Color(0xFFA8CE70),
            size: compact ? 30 : 36,
          ),
        ],
      ),
    );
  }
}

class _ProfileEditSaveButton extends StatelessWidget {
  const _ProfileEditSaveButton({
    required this.compact,
    required this.saving,
    required this.label,
    required this.onTap,
  });

  final bool compact;
  final bool saving;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: compact ? 66 : 78,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF9BCB53), Color(0xFF5D960E)],
          ),
          boxShadow: [
            BoxShadow(
              color: WasabiColors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (saving)
                  const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.save_outlined,
                    color: Colors.white,
                    size: compact ? 25 : 30,
                  ),
                SizedBox(width: compact ? 14 : 18),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 21 : 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileEditTrustDivider extends StatelessWidget {
  const _ProfileEditTrustDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const Expanded(child: _DashedLine()),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? WasabiColors.primary.withValues(alpha: .16)
                  : const Color(0xFFF0F6DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: WasabiColors.primary,
              size: 42,
            ),
          ),
          const Expanded(child: _DashedLine()),
        ],
      ),
    );
  }
}

class _ProfileEditCard extends StatelessWidget {
  const _ProfileEditCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F140C) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF13200E), Color(0xFF0B1008)],
              )
            : null,
        border: Border.all(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .24)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: .34)
                : const Color(0x0F6F771F),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProfileEditCircleIcon extends StatelessWidget {
  const _ProfileEditCircleIcon({
    required this.icon,
    required this.size,
    required this.iconSize,
    required this.background,
    required this.color,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color background;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1),
      painter: const _DashedLinePainter(),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8E7BC)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + 8, 0), paint);
      x += 16;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileEditLeafAccent extends StatelessWidget {
  const _ProfileEditLeafAccent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      key: const ValueKey('profile-edit-leaf-art'),
      width: 228,
      height: 126,
      child: CustomPaint(painter: _LeafAccentPainter(isDark: isDark)),
    );
  }
}

class _LeafAccentPainter extends CustomPainter {
  const _LeafAccentPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final opacityScale = isDark ? .44 : 1.0;
    final branchShadow = Paint()
      ..color = const Color(0x16D6C27F).withValues(alpha: .086 * opacityScale)
      ..strokeWidth = 4.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final branch = Paint()
      ..color = const Color(0x99B8CF7A).withValues(alpha: .60 * opacityScale)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leafFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFDDEAB6).withValues(alpha: .50 * opacityScale),
          const Color(0xFFB9D475).withValues(alpha: .70 * opacityScale),
        ],
      ).createShader(Offset.zero & size);
    final vein = Paint()
      ..color = const Color(0xFFA7BF6F).withValues(alpha: .30 * opacityScale)
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sparkle = Paint()
      ..color = const Color(0xFFDCBC57).withValues(alpha: .66 * opacityScale)
      ..style = PaintingStyle.fill;

    final branchPath = Path()
      ..moveTo(size.width * 0.06, size.height * 0.88)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.72,
        size.width * 0.42,
        size.height * 0.48,
        size.width * 1.02,
        size.height * 0.14,
      );
    canvas.drawPath(branchPath.shift(const Offset(0, 3)), branchShadow);
    canvas.drawPath(branchPath, branch);

    void leaf(Offset center, Size leafSize, double angle) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final leafPath = Path()
        ..moveTo(-leafSize.width * 0.50, 0)
        ..quadraticBezierTo(
          -leafSize.width * 0.12,
          -leafSize.height * 0.74,
          leafSize.width * 0.52,
          -leafSize.height * 0.04,
        )
        ..quadraticBezierTo(
          leafSize.width * 0.10,
          leafSize.height * 0.72,
          -leafSize.width * 0.50,
          0,
        );
      canvas.drawPath(leafPath, leafFill);
      canvas.drawLine(
        Offset(-leafSize.width * 0.32, 0),
        Offset(leafSize.width * 0.34, -leafSize.height * 0.02),
        vein,
      );
      canvas.restore();
    }

    leaf(
      Offset(size.width * 0.55, size.height * 0.52),
      const Size(38, 22),
      0.18,
    );
    leaf(
      Offset(size.width * 0.68, size.height * 0.44),
      const Size(40, 24),
      0.42,
    );
    leaf(
      Offset(size.width * 0.80, size.height * 0.35),
      const Size(39, 23),
      0.74,
    );
    leaf(
      Offset(size.width * 0.91, size.height * 0.26),
      const Size(34, 21),
      0.98,
    );
    leaf(
      Offset(size.width * 0.96, size.height * 0.49),
      const Size(30, 18),
      0.22,
    );
    leaf(
      Offset(size.width * 0.40, size.height * 0.66),
      const Size(34, 21),
      0.04,
    );

    void diamond(Offset center, double radius) {
      final path = Path()
        ..moveTo(center.dx, center.dy - radius)
        ..lineTo(center.dx + radius, center.dy)
        ..lineTo(center.dx, center.dy + radius)
        ..lineTo(center.dx - radius, center.dy)
        ..close();
      canvas.drawPath(path, sparkle);
    }

    diamond(Offset(size.width * 0.50, size.height * 0.12), 3.2);
    diamond(Offset(size.width * 0.90, size.height * 0.06), 4.8);
    canvas.drawCircle(
      Offset(size.width * 0.58, size.height * 0.00),
      4,
      Paint()
        ..color = const Color(0xFFD7B04E).withValues(alpha: .72 * opacityScale),
    );
  }

  @override
  bool shouldRepaint(covariant _LeafAccentPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class ProfilePhoneChangeScreen extends StatefulWidget {
  const ProfilePhoneChangeScreen({super.key, this.initialPhone = ''});

  final String initialPhone;

  @override
  State<ProfilePhoneChangeScreen> createState() =>
      _ProfilePhoneChangeScreenState();
}

class _ProfilePhoneChangeScreenState extends State<ProfilePhoneChangeScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  Timer? _resendTimer;
  bool _loading = false;
  _PhoneChangeStep _step = _PhoneChangeStep.currentPhone;
  bool _smsCodeInvalid = false;
  // The server keeps an OTP resend lock for 60 seconds.  Keeping this in
  // sync prevents an enabled button from immediately being rejected.
  int _resendSeconds = 60;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phone.dispose();
    _code.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_step == _PhoneChangeStep.currentCode ||
        _step == _PhoneChangeStep.newCode) {
      final isCurrentCode = _step == _PhoneChangeStep.currentCode;
      return Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF090D07) : const Color(0xFFFFF9DA),
        body: _ProfileAuthBackdrop(
          child: SafeArea(
            child: _ProfileSmsPanel(
              title: isUz ? 'Telefon tasdiqlash' : 'Подтверждение номера',
              subtitle: isCurrentCode
                  ? (isUz
                      ? 'Hozirgi raqamingizga yuborilgan SMS kodni kiriting'
                      : 'Введите SMS-код, отправленный на текущий номер')
                  : (isUz
                      ? 'Yangi raqamingizga yuborilgan SMS kodni kiriting'
                      : 'Введите SMS-код, отправленный на новый номер'),
              phone: _formatPhone(_activePhone()),
              controller: _code,
              loading: _loading,
              hasError: _smsCodeInvalid,
              resendSeconds: _resendSeconds,
              resendLabel:
                  isUz ? 'Kodni qayta yuborish' : 'Отправить код повторно',
              onBack: () => setState(() {
                _step = isCurrentCode
                    ? _PhoneChangeStep.currentPhone
                    : _PhoneChangeStep.newPhone;
                _smsCodeInvalid = false;
              }),
              onVerify: _verify,
              onCodeChanged: () => setState(() => _smsCodeInvalid = false),
              onResend: _sendCode,
            ),
          ),
        ),
      );
    }

    final confirmingCurrent = _step == _PhoneChangeStep.currentPhone;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050804) : const Color(0xFFFFF9DA),
      body: Stack(
        children: [
          const Positioned.fill(child: WasabiPageBackground()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 26),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PhoneChangeHeader(
                          title: isUz
                              ? 'Telefonni o‘zgartirish'
                              : 'Изменить телефон',
                          subtitle: confirmingCurrent
                              ? (isUz
                                  ? 'Xavfsizlik uchun avval eski raqamni tasdiqlang'
                                  : 'Для безопасности подтвердите текущий номер')
                              : (isUz
                                  ? 'Endi yangi telefon raqamini kiriting'
                                  : 'Теперь введите новый номер телефона'),
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(height: 24),
                        _PhoneChangeCard(
                          icon: confirmingCurrent
                              ? Icons.verified_user_outlined
                              : Icons.phone_iphone_rounded,
                          eyebrow: confirmingCurrent
                              ? (isUz ? '1-qadam' : 'Шаг 1')
                              : (isUz ? '2-qadam' : 'Шаг 2'),
                          title: confirmingCurrent
                              ? (isUz
                                  ? 'Joriy raqamni tasdiqlang'
                                  : 'Подтвердите текущий номер')
                              : (isUz
                                  ? 'Yangi raqamni kiriting'
                                  : 'Введите новый номер'),
                          subtitle: confirmingCurrent
                              ? (isUz
                                  ? 'SMS kod shu raqamga yuboriladi'
                                  : 'SMS-код будет отправлен на этот номер')
                              : (isUz
                                  ? 'Raqam +998 kodi bilan saqlanadi'
                                  : 'Номер сохранится с кодом +998'),
                          child: confirmingCurrent
                              ? _CurrentPhoneDisplay(
                                  phone: _formatPhone(_currentPhone()),
                                )
                              : _ProfilePhoneField(
                                  controller: _phone,
                                  label: isUz ? 'Telefon' : 'Телефон',
                                ),
                        ),
                        const SizedBox(height: 18),
                        _PhoneChangeSendButton(
                          key: const ValueKey('phone-change-send-code'),
                          loading: _loading,
                          label:
                              isUz ? 'SMS kod yuborish' : 'Отправить SMS-код',
                          onTap: _loading ? null : _sendCode,
                        ),
                        const SizedBox(height: 16),
                        _PhoneChangeNote(
                          text: confirmingCurrent
                              ? (isUz
                                  ? 'Eski raqam tasdiqlangandan keyin yangi raqamni kiritasiz.'
                                  : 'После подтверждения текущего номера вы введете новый.')
                              : (isUz
                                  ? 'Yangi raqam ham SMS kod bilan tasdiqlanadi.'
                                  : 'Новый номер тоже нужно подтвердить SMS-кодом.'),
                        ),
                        const SizedBox(height: 22),
                        _PhoneChangeSecurityPanel(
                          title: isUz
                              ? 'Xavfsiz almashtirish'
                              : 'Безопасная смена',
                          text: confirmingCurrent
                              ? (isUz
                                  ? 'Bu tekshiruv profilingizni himoya qiladi va raqamni faqat siz o‘zgartira olishingizni tasdiqlaydi.'
                                  : 'Эта проверка защищает профиль и подтверждает, что номер меняете именно вы.')
                              : (isUz
                                  ? 'Yangi raqam tasdiqlangandan keyin u profilingizga ulanadi.'
                                  : 'После подтверждения новый номер будет привязан к профилю.'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (_loading) return;
    final confirmingCurrent = _step == _PhoneChangeStep.currentPhone ||
        _step == _PhoneChangeStep.currentCode;
    final state = AppScope.of(context, listen: false);
    setState(() => _loading = true);
    try {
      if (confirmingCurrent) {
        await state.sendProfileCurrentPhoneCode(_currentPhone());
      } else {
        await state.sendProfilePhoneChangeCode(_activePhone());
      }
      if (!mounted) return;
      setState(() {
        _code.clear();
        _smsCodeInvalid = false;
        _step = confirmingCurrent
            ? _PhoneChangeStep.currentCode
            : _PhoneChangeStep.newCode;
      });
      _startTimer();
    } catch (error) {
      if (!mounted) return;
      showWasabiMessage(
        context,
        _profileErrorText(error, state.locale),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final state = AppScope.of(context, listen: false);
    final code = _code.text.replaceAll(RegExp(r'\D'), '');
    if (code.length < 6) {
      setState(() => _smsCodeInvalid = true);
      return;
    }
    setState(() => _loading = true);
    try {
      if (_step == _PhoneChangeStep.currentCode) {
        await state.verifyProfileCurrentPhone(
          phone: _currentPhone(),
          code: code,
        );
        if (!mounted) return;
        _resendTimer?.cancel();
        setState(() {
          _code.clear();
          _smsCodeInvalid = false;
          _resendSeconds = 60;
          _step = _PhoneChangeStep.newPhone;
        });
        return;
      }
      await state.verifyProfilePhoneChange(phone: _activePhone(), code: code);
      if (!mounted) return;
      Navigator.of(context).pop();
      showWasabiMessage(
        context,
        state.locale == 'uz'
            ? 'Telefon raqami o‘zgartirildi'
            : 'Номер телефона обновлен',
      );
    } catch (error) {
      if (!mounted) return;
      if (_profileSmsCodeError(error)) {
        setState(() => _smsCodeInvalid = true);
      }
      showWasabiMessage(
        context,
        _profileErrorText(error, state.locale),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  String _currentPhone() => _phoneStringValue(widget.initialPhone);

  String _activePhone() {
    if (_step == _PhoneChangeStep.currentPhone ||
        _step == _PhoneChangeStep.currentCode) {
      return _currentPhone();
    }
    return _phoneValue(_phone);
  }
}

enum _PhoneChangeStep { currentPhone, currentCode, newPhone, newCode }

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.compact,
    required this.dense,
    required this.name,
    required this.phone,
    required this.onTap,
  });

  final bool compact;
  final bool dense;
  final String name;
  final String phone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const ValueKey('profile-hero-card'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: dense ? 112 : (compact ? 118 : 122),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF79AC39), Color(0xFF446E17), Color(0xFF183A0D)],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x262E5B14),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 20 : (compact ? 22 : 24),
              vertical: dense ? 18 : (compact ? 20 : 22),
            ),
            child: Row(
              children: [
                Container(
                  width: dense ? 64 : (compact ? 68 : 74),
                  height: dense ? 64 : (compact ? 68 : 74),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEFF7DD).withValues(alpha: 0.92),
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: WasabiColors.primary,
                    size: dense ? 38 : (compact ? 40 : 44),
                  ),
                ),
                SizedBox(width: dense ? 18 : (compact ? 20 : 22)),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dense ? 21 : (compact ? 22 : 24),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: dense ? 2 : 4),
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.96),
                          fontSize: dense ? 13 : (compact ? 14 : 15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: dense ? 30 : (compact ? 34 : 38),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({
    required this.compact,
    required this.dense,
    required this.children,
  });

  final bool compact;
  final bool dense;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1)
            SizedBox(height: dense ? 10 : (compact ? 12 : 14)),
        ],
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    super.key,
    required this.compact,
    required this.dense,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool compact;
  final bool dense;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF12180E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? WasabiColors.primary.withValues(alpha: .26)
                : Colors.transparent,
          ),
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF182211), Color(0xFF0F140C)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: .34)
                  : const Color(0x14000000),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 14 : (compact ? 16 : 18),
              vertical: dense ? 14 : (compact ? 15 : 17),
            ),
            child: Row(
              children: [
                Container(
                  width: dense ? 52 : (compact ? 54 : 58),
                  height: dense ? 52 : (compact ? 54 : 58),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark
                        ? WasabiColors.primary.withValues(alpha: .16)
                        : WasabiColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? WasabiColors.primary.withValues(alpha: .26)
                          : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: WasabiColors.primary,
                    size: dense ? 24 : (compact ? 25 : 27),
                  ),
                ),
                SizedBox(width: dense ? 18 : (compact ? 19 : 20)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : WasabiColors.dark,
                          fontSize: dense ? 16 : (compact ? 17 : 18),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: dense ? 2 : 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: .62)
                              : WasabiColors.muted,
                          fontSize: dense ? 14 : (compact ? 14.5 : 15),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? WasabiColors.primary.withValues(alpha: .72)
                      : WasabiColors.muted,
                  size: dense ? 28 : (compact ? 30 : 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneChangeHeader extends StatelessWidget {
  const _PhoneChangeHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : WasabiColors.dark;
    final subtitleColor =
        isDark ? Colors.white.withValues(alpha: .62) : WasabiColors.muted;
    return Row(
      children: [
        Material(
          color: isDark ? Colors.white.withValues(alpha: .08) : Colors.white,
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: titleColor,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhoneChangeCard extends StatelessWidget {
  const _PhoneChangeCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : WasabiColors.dark;
    final detailColor =
        isDark ? Colors.white.withValues(alpha: .62) : WasabiColors.muted;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF17240F), Color(0xFF0D130A)]
              : const [Color(0xFFFFFFFF), Color(0xFFF4F8E9)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: WasabiColors.primary.withValues(alpha: .34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: WasabiColors.primary.withValues(alpha: .18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: WasabiColors.primary.withValues(alpha: .32),
                  ),
                ),
                child: Icon(icon, color: WasabiColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: TextStyle(
                        color: WasabiColors.primary.withValues(alpha: .82),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: TextStyle(
              color: detailColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _CurrentPhoneDisplay extends StatelessWidget {
  const _CurrentPhoneDisplay({required this.phone});

  final String phone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: .24) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: WasabiColors.primary.withValues(alpha: .38)),
      ),
      child: Row(
        children: [
          const Icon(Icons.phone_in_talk_rounded, color: WasabiColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : WasabiColors.dark,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            color: WasabiColors.primary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _PhoneChangeSendButton extends StatelessWidget {
  const _PhoneChangeSendButton({
    super.key,
    required this.loading,
    required this.label,
    required this.onTap,
  });

  final bool loading;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF83B707), Color(0xFF578D04)],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (loading)
                  const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(Icons.sms_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneChangeNote extends StatelessWidget {
  const _PhoneChangeNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: WasabiColors.primary,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: .58)
                  : WasabiColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneChangeSecurityPanel extends StatelessWidget {
  const _PhoneChangeSecurityPanel({required this.title, required this.text});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : WasabiColors.dark;
    final detailColor =
        isDark ? Colors.white.withValues(alpha: .62) : WasabiColors.muted;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E140B).withValues(alpha: .92)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: WasabiColors.primary.withValues(alpha: .22)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF101A0C), Color(0xFF070A06)]
              : const [Color(0xFFFFFFFF), Color(0xFFF5F8EA)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WasabiColors.primary.withValues(alpha: .16),
              shape: BoxShape.circle,
              border: Border.all(
                color: WasabiColors.primary.withValues(alpha: .28),
              ),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: WasabiColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: detailColor,
                    height: 1.35,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _ProfileAuthBackdrop extends StatelessWidget {
  const _ProfileAuthBackdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [
                      Color(0xFF0B1008),
                      Color(0xFF17200D),
                      Color(0xFF10170C)
                    ]
                  : const [
                      Color(0xFFFFFDF1),
                      Color(0xFFF3F8DD),
                      Color(0xFFFFF6D3)
                    ],
            ),
          ),
        ),
        _ProfileBackdropOrb(
          top: -105,
          right: -78,
          size: 250,
          color: WasabiColors.primary.withValues(alpha: isDark ? .19 : .14),
        ),
        _ProfileBackdropOrb(
          top: 210,
          left: -104,
          size: 210,
          color: WasabiColors.secondary.withValues(alpha: isDark ? .08 : .10),
        ),
        _ProfileBackdropOrb(
          bottom: -125,
          right: -35,
          size: 285,
          color: WasabiColors.primary.withValues(alpha: isDark ? .13 : .09),
        ),
        child,
      ],
    );
  }
}

class _ProfileBackdropOrb extends StatelessWidget {
  const _ProfileBackdropOrb({
    required this.size,
    required this.color,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: isDark
                ? WasabiColors.primary.withValues(alpha: .20)
                : Colors.white.withValues(alpha: .48),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _ProfileSmsPanel extends StatelessWidget {
  const _ProfileSmsPanel({
    required this.title,
    required this.subtitle,
    required this.phone,
    required this.controller,
    required this.loading,
    required this.hasError,
    required this.resendSeconds,
    required this.resendLabel,
    required this.onBack,
    required this.onVerify,
    required this.onCodeChanged,
    required this.onResend,
  });

  final String title;
  final String subtitle;
  final String phone;
  final TextEditingController controller;
  final bool loading;
  final bool hasError;
  final int resendSeconds;
  final String resendLabel;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onCodeChanged;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : WasabiColors.dark;
    final mutedColor =
        isDark ? Colors.white.withValues(alpha: .66) : WasabiColors.muted;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: WasabiColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          const _ProfileSmsHeroIcon(),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            phone,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: WasabiColors.primary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          _ProfileOtpCodeInput(
            controller: controller,
            enabled: !loading,
            hasError: hasError,
            onChanged: onCodeChanged,
            onCompleted: onVerify,
          ),
          const SizedBox(height: 18),
          if (resendSeconds > 0)
            Text(
              '${(resendSeconds ~/ 60).toString().padLeft(2, '0')}:${(resendSeconds % 60).toString().padLeft(2, '0')}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: WasabiColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            )
          else
            TextButton(
              onPressed: loading ? null : onResend,
              child: Text(resendLabel),
            ),
          const SizedBox(height: 34),
          const _ProfileSecureVerificationCard(),
        ],
      ),
    );
  }
}

class _ProfilePhoneField extends StatelessWidget {
  const _ProfilePhoneField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : WasabiColors.dark;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color:
              isDark ? Colors.white.withValues(alpha: .58) : WasabiColors.muted,
          fontWeight: FontWeight.w800,
        ),
        filled: true,
        fillColor: isDark ? Colors.black.withValues(alpha: .24) : Colors.white,
        prefixIcon: const Icon(
          Icons.phone_outlined,
          color: WasabiColors.primary,
        ),
        prefixText: '+998 ',
        prefixStyle: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w900,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: WasabiColors.primary.withValues(alpha: .38),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: WasabiColors.primary, width: 1.4),
        ),
      ),
    );
  }
}

class _ProfileSmsHeroIcon extends StatelessWidget {
  const _ProfileSmsHeroIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WasabiColors.primary.withValues(alpha: .10),
            ),
          ),
          Positioned(
            left: 54,
            top: 28,
            child: _ProfileSmsDecorDot(size: 18, opacity: .14),
          ),
          Positioned(
            right: 46,
            bottom: 42,
            child: _ProfileSmsDecorDot(size: 18, opacity: .14),
          ),
          Positioned(
            left: 34,
            bottom: 36,
            child: _ProfileSmsDecorDot(size: 22, opacity: .16),
          ),
          Positioned(
            top: 42,
            child: Container(
              width: 78,
              height: 62,
              decoration: BoxDecoration(
                color: WasabiColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: WasabiColors.primary.withValues(alpha: .22),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          Positioned(
            top: 84,
            child: Container(
              width: 106,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2D6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: WasabiColors.primary.withValues(alpha: .20),
                    blurRadius: 26,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                color: WasabiColors.primary,
                size: 46,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSmsDecorDot extends StatelessWidget {
  const _ProfileSmsDecorDot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: WasabiColors.primary.withValues(alpha: opacity),
        ),
      );
}

class _ProfileOtpCodeInput extends StatefulWidget {
  const _ProfileOtpCodeInput({
    required this.controller,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool hasError;
  final VoidCallback onChanged;
  final VoidCallback onCompleted;

  @override
  State<_ProfileOtpCodeInput> createState() => _ProfileOtpCodeInputState();
}

class _ProfileOtpCodeInputState extends State<_ProfileOtpCodeInput> {
  static const _length = 6;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_refresh);
    widget.controller.addListener(_handleControllerChanged);
    _syncCode(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode.removeListener(_refresh);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = widget.hasError
        ? (isDark ? const Color(0xFF2A1111) : const Color(0xFFFFF1F1))
        : Colors.transparent;
    final inactiveBorder = isDark
        ? WasabiColors.primary.withValues(alpha: .34)
        : const Color(0xFFE1E5DB);
    final disabledBorder =
        isDark ? Colors.white.withValues(alpha: .16) : const Color(0xFFE1E5DB);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final availableWidth = constraints.maxWidth - (gap * (_length - 1));
        final boxWidth = (availableWidth / _length).clamp(44.0, 56.0);
        return AutofillGroup(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  enableSuggestions: false,
                  autocorrect: false,
                  maxLength: _length,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_length),
                  ],
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    filled: false,
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: _onChanged,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: widget.enabled ? () => _focusNode.requestFocus() : null,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_length, (index) {
                      final code = widget.controller.text;
                      final digit = index < code.length ? code[index] : '';
                      final borderColor = widget.hasError
                          ? const Color(0xFFE32626)
                          : _focusNode.hasFocus
                              ? WasabiColors.primary
                              : widget.enabled
                                  ? inactiveBorder
                                  : disabledBorder;
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: index == _length - 1 ? 0 : gap,
                        ),
                        child: Container(
                          width: boxWidth,
                          height: boxWidth + 10,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: widget.hasError || _focusNode.hasFocus
                                  ? 2
                                  : 1,
                            ),
                          ),
                          child: Text(
                            digit,
                            style: TextStyle(
                              color: isDark ? Colors.white : WasabiColors.dark,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleControllerChanged() {
    _syncCode(widget.controller.text, notify: false);
  }

  void _onChanged(String value) {
    _syncCode(value);
    widget.onChanged();
    if (widget.controller.text.length == _length) {
      TextInput.finishAutofillContext();
      _focusNode.unfocus();
      widget.onCompleted();
    }
  }

  void _syncCode(String value, {bool notify = true}) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final next =
        digits.length > _length ? digits.substring(0, _length) : digits;
    if (widget.controller.text != next) {
      widget.controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    if (notify && mounted) setState(() {});
  }
}

class _ProfileSecureVerificationCard extends StatelessWidget {
  const _ProfileSecureVerificationCard();

  @override
  Widget build(BuildContext context) {
    final isUz = AppScope.of(context).locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF10150D) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: WasabiColors.stroke),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WasabiColors.primary.withValues(alpha: .12),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: WasabiColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              isUz
                  ? 'Kodni hech kimga bermang. Bu telefon raqamingizni himoya qiladi.'
                  : 'Не передавайте код никому. Он защищает ваш номер.',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: .68)
                    : WasabiColors.muted,
                fontSize: 15,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _phoneValue(TextEditingController controller) {
  return _phoneStringValue(controller.text);
}

String _phoneStringValue(String value) {
  final raw = value.trim();
  if (raw.startsWith('+')) return raw;
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('998')) return '+$digits';
  if (digits.startsWith('9')) return '+998$digits';
  return '+998$digits';
}

String _editablePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('998') && digits.length == 12) {
    return digits.substring(3);
  }
  return digits;
}

String _formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('998')) {
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
        '${digits.substring(10, 12)}';
  }
  return phone;
}

String _profileErrorText(Object error, String locale) {
  if (error is ApiException) {
    switch (error.code) {
      case 'INVALID_PHONE':
        return locale == 'uz'
            ? "Telefon raqami noto'g'ri"
            : 'Некорректный номер телефона';
      case 'PHONE_ALREADY_REGISTERED':
        return locale == 'uz'
            ? 'Bu telefon raqami boshqa hisobga ulangan'
            : 'Этот номер уже привязан к другому аккаунту';
      case 'SMS_CODE_INVALID':
        return locale == 'uz' ? "SMS kod noto'g'ri" : 'Неверный SMS-код';
      case 'SMS_CODE_EXPIRED':
        return locale == 'uz'
            ? 'SMS kod muddati tugagan'
            : 'Срок действия SMS-кода истек';
      case 'SMS_CODE_NOT_FOUND':
        return locale == 'uz' ? 'SMS kod topilmadi' : 'SMS-код не найден';
      case 'SMS_CODE_TOO_MANY_ATTEMPTS':
        return locale == 'uz'
            ? "Juda ko'p urinish bo'ldi"
            : 'Слишком много попыток';
      case 'SMS_RESEND_TOO_EARLY':
        return locale == 'uz'
            ? 'Qayta yuborish uchun kuting'
            : 'Подождите перед повторной отправкой';
      case 'CLIENT_UPDATE_FAILED':
        return locale == 'uz'
            ? "Profilni yangilab bo'lmadi"
            : 'Не удалось обновить профиль';
    }
  }
  return error.toString();
}

bool _profileSmsCodeError(Object error) {
  return error is ApiException &&
      (error.code?.startsWith('SMS_CODE_') ?? false);
}
