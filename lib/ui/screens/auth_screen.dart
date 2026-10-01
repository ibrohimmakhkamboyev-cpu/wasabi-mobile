import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _loginPhone = TextEditingController();
  final _name = TextEditingController();
  final _registerPhone = TextEditingController();
  final _birthday = TextEditingController();
  final _smsCode = TextEditingController();
  String _pendingPhone = '';
  String _pendingName = '';
  String _pendingBirthday = '';
  Timer? _resendTimer;
  bool _loading = false;
  bool _codeSent = false;
  bool _smsCodeInvalid = false;
  int _resendSeconds = 60;
  bool _loginMode = false;

  @override
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  @override
  void dispose() {
    _tabs.dispose();
    _loginPhone.dispose();
    _name.dispose();
    _registerPhone.dispose();
    _birthday.dispose();
    _smsCode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_codeSent) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _AuthBackdrop(
          child: SafeArea(
            child: _SmsVerificationPanel(
              copy: _copy(state.locale),
              phone: _formattedPhone(_pendingPhone),
              controller: _smsCode,
              loading: _loading,
              hasError: _smsCodeInvalid,
              resendSeconds: _resendSeconds,
              onBack: () => setState(() {
                _codeSent = false;
                _smsCodeInvalid = false;
              }),
              onVerify: () => _verifyCode(context),
              onCodeChanged: () => setState(() => _smsCodeInvalid = false),
              onResend: () => _resendCode(context),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _AuthBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    _AuthBackButton(isDark: isDark),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUz ? 'Profil' : 'Личный кабинет',
                            style: TextStyle(
                              color: isDark ? Colors.white : WasabiColors.dark,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.6,
                            ),
                          ),
                          Text(
                            'WASABI SUSHI',
                            style: TextStyle(
                              color:
                                  WasabiColors.primary.withValues(alpha: .78),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _LanguageButton(
                      locale: state.locale,
                      isUzEnabled: state.isUzEnabled,
                      onChanged: state.setLocale,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xEE141B10)
                        : Colors.white.withValues(alpha: .82),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? WasabiColors.primary.withValues(alpha: .30)
                          : Colors.white.withValues(alpha: .9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: .32)
                            : WasabiColors.primary.withValues(alpha: .10),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabs,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    indicator: BoxDecoration(
                      color: WasabiColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: WasabiColors.primary.withValues(alpha: .24),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark
                        ? Colors.white.withValues(alpha: .72)
                        : WasabiColors.dark,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                    tabs: [
                      Tab(text: isUz ? 'Kirish' : 'Вход'),
                      Tab(text: isUz ? "Ro'yxatdan o'tish" : 'Регистрация'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _AuthPanel(
                      children: [
                        _PhoneField(
                          controller: _loginPhone,
                          label: isUz ? 'Telefon' : 'Телефон',
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          onPressed:
                              _loading ? null : () => _sendLoginCode(context),
                          icon: const Icon(Icons.forum_rounded),
                          label: Text(
                            isUz ? 'SMS kod yuborish' : 'Отправить SMS-код',
                          ),
                        ),
                      ],
                    ),
                    _AuthPanel(
                      children: [
                        Text(
                          isUz
                              ? 'Yangi profil uchun telefon raqam va SMS kod kifoya.'
                              : 'Для новой регистрации нужен только телефон и SMS-код.',
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: .68)
                                : WasabiColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: isUz ? 'Ism' : 'Имя',
                            prefixIcon: _AuthFieldIcon(
                              icon: Icons.person_rounded,
                              label: 'Ism',
                              neutral: true,
                              dark: isDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PhoneField(
                          controller: _registerPhone,
                          label: isUz ? 'Telefon' : 'Телефон',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _birthday,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [_BirthdayInputFormatter()],
                          onTap: () => _pickBirthday(context),
                          decoration: InputDecoration(
                            labelText:
                                isUz ? "Tug'ilgan sana" : 'Дата рождения',
                            hintText: '1995-05-20',
                            prefixIcon: _AuthFieldIcon(
                              icon: Icons.cake_rounded,
                              label: "Tug'ilgan sana",
                              dark: isDark,
                            ),
                            suffixIcon: IconButton(
                              tooltip: isUz ? 'Sana tanlash' : 'Выбрать дату',
                              onPressed: () => _pickBirthday(context),
                              icon: _AuthFieldIcon(
                                icon: Icons.calendar_month_rounded,
                                label: 'Sana tanlash',
                                dark: isDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : () => _sendCode(context),
                          icon: const Icon(Icons.forum_rounded),
                          label: Text(isUz ? 'Kod yuborish' : 'Отправить код'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendLoginCode(BuildContext context) async {
    final state = AppScope.of(context, listen: false);
    final phone = _phoneValue(_loginPhone);
    await _run(
      context,
      () => state.sendLoginCode(phone),
      stay: true,
      onError: (error) {
        if (error is! ApiException || error.code != 'CLIENT_NOT_FOUND') {
          return false;
        }
        _registerPhone.text = _editablePhone(phone);
        _tabs.animateTo(1);
        return false;
      },
      onSuccess: () {
        setState(() {
          _loginMode = true;
          _pendingPhone = phone;
          _pendingName = '';
          _pendingBirthday = '';
          _codeSent = true;
        });
        _startResendTimer();
      },
    );
  }

  Future<void> _pickBirthday(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final existing = DateTime.tryParse(_birthday.text);
    final initialDate = existing != null && !existing.isAfter(today)
        ? existing
        : DateTime(today.year - 18, today.month, today.day);
    final isUz = AppScope.of(context, listen: false).locale == 'uz';
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _WasabiBirthdayPicker(
        initialDate: initialDate,
        lastDate: today,
        isUz: isUz,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthday.text = _birthdayValue(selected);
    });
  }

  Future<void> _sendCode(BuildContext context) async {
    final state = AppScope.of(context, listen: false);
    final phone = _phoneValue(_registerPhone);
    var codeMode = 'register';
    await _run(
      context,
      () async {
        codeMode = await state.sendRegisterCode(phone);
      },
      stay: true,
      onError: (error) {
        if (error is! ApiException ||
            error.code != 'CLIENT_ALREADY_REGISTERED') {
          return false;
        }
        _loginPhone.text = _editablePhone(phone);
        _tabs.animateTo(0);
        return false;
      },
      onSuccess: () {
        setState(() {
          _loginMode = codeMode == 'login';
          _pendingPhone = phone;
          _pendingName = _name.text;
          _pendingBirthday = _birthday.text;
          _codeSent = true;
        });
        _startResendTimer();
      },
    );
  }

  Future<void> _resendCode(BuildContext context) async {
    final state = AppScope.of(context, listen: false);
    await _run(
      context,
      () => _loginMode
          ? state.sendLoginCode(_pendingPhone)
          : state.sendRegisterCode(_pendingPhone),
      stay: true,
      onSuccess: _startResendTimer,
    );
  }

  void _startResendTimer() {
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

  Future<void> _verifyCode(BuildContext context) async {
    final state = AppScope.of(context, listen: false);
    await _run(
      context,
      () => _loginMode
          ? state.login(phone: _pendingPhone, smsCode: _smsCode.text)
          : state.register(
              name: _pendingName,
              phone: _pendingPhone,
              birthday: _pendingBirthday,
              smsCode: _smsCode.text,
            ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    bool stay = false,
    String? successMessage,
    VoidCallback? onSuccess,
    bool Function(Object error)? onError,
  }) async {
    setState(() => _loading = true);
    final state = AppScope.of(context, listen: false);
    try {
      await action();
      onSuccess?.call();
      if (!stay) {
        await state.finishOnboarding();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ShellScreen()),
          (_) => false,
        );
      } else if (context.mounted && successMessage != null) {
        showWasabiMessage(context, successMessage);
      }
    } catch (error) {
      if (!context.mounted) return;
      if (_isSmsCodeError(error)) {
        setState(() => _smsCodeInvalid = true);
      }
      final handled = onError?.call(error) ?? false;
      if (handled) return;
      showWasabiMessage(
        context,
        _errorText(error, state.locale),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _WasabiBirthdayPicker extends StatefulWidget {
  const _WasabiBirthdayPicker({
    required this.initialDate,
    required this.lastDate,
    required this.isUz,
  });

  final DateTime initialDate;
  final DateTime lastDate;
  final bool isUz;

  @override
  State<_WasabiBirthdayPicker> createState() => _WasabiBirthdayPickerState();
}

class _WasabiBirthdayPickerState extends State<_WasabiBirthdayPicker> {
  late DateTime _selected = widget.initialDate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? WasabiColors.darkSurfaceHigh : Colors.white;
    final text = isDark ? WasabiColors.darkText : WasabiColors.dark;
    final muted = isDark ? WasabiColors.darkMuted : WasabiColors.muted;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: WasabiColors.primary.withValues(alpha: isDark ? .42 : .25),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .22),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: WasabiColors.primary.withValues(alpha: .13),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cake_outlined,
                      color: WasabiColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isUz ? 'Tug\'ilgan sana' : 'Дата рождения',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isUz
                              ? 'Avval yilni, keyin kunni tanlang'
                              : 'Сначала год, затем день',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: widget.isUz ? 'Yopish' : 'Закрыть',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: muted),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: WasabiColors.primary
                      .withValues(alpha: isDark ? .20 : .10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isUz ? 'Tanlangan sana' : 'Выбранная дата',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _birthdayLabel(_selected, widget.isUz),
                      style: const TextStyle(
                        color: WasabiColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Theme(
                data: Theme.of(context).copyWith(
                  datePickerTheme: DatePickerThemeData(
                    backgroundColor: surface,
                    headerBackgroundColor: surface,
                    headerForegroundColor: text,
                    dayForegroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.disabled)
                          ? muted.withValues(alpha: .35)
                          : text,
                    ),
                    todayForegroundColor:
                        const WidgetStatePropertyAll(WasabiColors.primary),
                    todayBorder: const BorderSide(color: WasabiColors.primary),
                    dayBackgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? WasabiColors.primary
                          : Colors.transparent,
                    ),
                    yearForegroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? Colors.white
                          : WasabiColors.primary,
                    ),
                    yearBackgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? WasabiColors.primary
                          : Colors.transparent,
                    ),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: _selected,
                  firstDate: DateTime(1920),
                  lastDate: widget.lastDate,
                  onDateChanged: (value) => setState(() => _selected = value),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(widget.isUz ? 'Bekor qilish' : 'Отмена'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    child: Text(widget.isUz ? 'Tanlash' : 'Выбрать'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthFieldIcon extends StatelessWidget {
  const _AuthFieldIcon({
    required this.icon,
    required this.label,
    this.neutral = false,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool neutral;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final iconColor = dark
        ? Colors.white.withValues(alpha: .88)
        : neutral
            ? const Color(0xFF3E4735)
            : WasabiColors.primary;
    final background = dark
        ? Colors.white.withValues(alpha: .10)
        : neutral
            ? const Color(0xFFF1F3ED)
            : const Color(0xFFEAF4CF);
    return Semantics(
      label: label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Container(
            key: const Key('auth-field-icon'),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : WasabiColors.dark;
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      inputFormatters: const [_UzbekPhoneInputFormatter()],
      cursorColor: WasabiColors.primary,
      style: TextStyle(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: .72)
              : WasabiColors.primary,
        ),
        floatingLabelStyle: const TextStyle(
          color: WasabiColors.primary,
          fontWeight: FontWeight.w800,
        ),
        prefixIcon: _AuthFieldIcon(
          icon: Icons.phone_rounded,
          label: label,
          dark: isDark,
        ),
        prefixText: '+998 ',
        prefixStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UzbekPhoneInputFormatter extends TextInputFormatter {
  const _UzbekPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // The country code is already rendered by the field. Still accept a full
    // Uzbek number when it is pasted into the editable part.
    if (digits.length > 9 && digits.startsWith('998')) {
      digits = digits.substring(3);
    }

    return _formattedInputValue(
      digits: digits,
      maxDigits: 9,
      groupLengths: const [2, 3, 2, 2],
      separator: ' ',
    );
  }
}

String _birthdayValue(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

String _birthdayLabel(DateTime value, bool isUz) {
  const uzMonths = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];
  const ruMonths = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];
  final month = (isUz ? uzMonths : ruMonths)[value.month - 1];
  return '${value.day} $month ${value.year}';
}

class _BirthdayInputFormatter extends TextInputFormatter {
  const _BirthdayInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _formattedInputValue(
      digits: newValue.text.replaceAll(RegExp(r'\D'), ''),
      maxDigits: 8,
      groupLengths: const [4, 2, 2],
      separator: '-',
    );
  }
}

TextEditingValue _formattedInputValue({
  required String digits,
  required int maxDigits,
  required List<int> groupLengths,
  required String separator,
}) {
  final cappedDigits = digits.substring(0, digits.length.clamp(0, maxDigits));
  final parts = <String>[];
  var offset = 0;

  for (final groupLength in groupLengths) {
    if (offset >= cappedDigits.length) break;
    final end = (offset + groupLength).clamp(0, cappedDigits.length);
    parts.add(cappedDigits.substring(offset, end));
    offset = end;
  }

  final text = parts.join(separator);
  return TextEditingValue(
    text: text,
    selection: TextSelection.collapsed(offset: text.length),
  );
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
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
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 12),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF11150D)
              : Colors.white.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isDark
                ? WasabiColors.primary.withValues(alpha: .28)
                : const Color(0xFFE6E3D6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AuthLanguageChip(
              label: '🇷🇺',
              selected: !isUz,
              enabled: true,
              onTap: () => onChanged('ru'),
            ),
            _AuthLanguageChip(
              label: '🇺🇿',
              selected: isUz,
              enabled: isUzEnabled,
              onTap: () => onChanged('uz'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthLanguageChip extends StatelessWidget {
  const _AuthLanguageChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: selected ? WasabiColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 42,
          height: 32,
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : isDark
                      ? Colors.white.withValues(alpha: enabled ? .72 : .3)
                      : WasabiColors.dark.withValues(alpha: enabled ? .7 : .3),
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
  const _AuthBackButton({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: .10)
          : Colors.white.withValues(alpha: .76),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : WasabiColors.dark,
          ),
        ),
      ),
    );
  }
}

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop({required this.child});

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
        Positioned(
          top: -105,
          right: -78,
          child: _BackdropOrb(
            size: 250,
            color: WasabiColors.primary.withValues(alpha: isDark ? .19 : .14),
          ),
        ),
        Positioned(
          top: 210,
          left: -104,
          child: _BackdropOrb(
            size: 210,
            color: WasabiColors.secondary.withValues(alpha: isDark ? .08 : .10),
          ),
        ),
        Positioned(
          bottom: -125,
          right: -35,
          child: _BackdropOrb(
            size: 285,
            color: WasabiColors.primary.withValues(alpha: isDark ? .13 : .09),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
    );
  }
}

class _SmsVerificationPanel extends StatelessWidget {
  const _SmsVerificationPanel({
    required this.copy,
    required this.phone,
    required this.controller,
    required this.loading,
    required this.hasError,
    required this.resendSeconds,
    required this.onBack,
    required this.onVerify,
    required this.onCodeChanged,
    required this.onResend,
  });

  final _AuthCopy copy;
  final String phone;
  final TextEditingController controller;
  final bool loading;
  final bool hasError;
  final int resendSeconds;
  final VoidCallback onBack;
  final VoidCallback onVerify;
  final VoidCallback onCodeChanged;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : WasabiColors.dark;
    final secondaryText =
        isDark ? Colors.white.withValues(alpha: .72) : WasabiColors.muted;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: loading ? null : onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: WasabiColors.primary,
              tooltip: copy.editPhone,
            ),
          ),
          const SizedBox(height: 10),
          const _SmsHeroIcon(),
          const SizedBox(height: 20),
          Text(
            copy.smsSent,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: primaryText,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.smsSentDetail,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secondaryText,
              fontSize: 16,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  phone,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WasabiColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: loading ? null : onBack,
                icon: const Icon(Icons.edit_outlined),
                color: WasabiColors.primary,
                tooltip: copy.editPhone,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _OtpCodeInput(
            controller: controller,
            enabled: !loading,
            hasError: hasError,
            onChanged: onCodeChanged,
            onCompleted: onVerify,
          ),
          const SizedBox(height: 18),
          if (resendSeconds > 0)
            Text.rich(
              TextSpan(
                text: copy.didntReceive,
                children: [
                  TextSpan(
                    text:
                        '  ${(resendSeconds ~/ 60).toString().padLeft(2, '0')}:${(resendSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: WasabiColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryText.withValues(alpha: .72),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            TextButton(
              onPressed: loading ? null : onResend,
              child: Text(
                copy.resendCode,
                style: const TextStyle(
                  color: WasabiColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          const SizedBox(height: 34),
          _SecureVerificationCard(copy: copy),
        ],
      ),
    );
  }
}

class _SmsHeroIcon extends StatelessWidget {
  const _SmsHeroIcon();

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
            child: _DecorDot(size: 18, opacity: .14),
          ),
          Positioned(
            right: 46,
            bottom: 42,
            child: _DecorDot(size: 18, opacity: .14),
          ),
          Positioned(
            left: 34,
            bottom: 36,
            child: _DecorDot(size: 22, opacity: .16),
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

class _DecorDot extends StatelessWidget {
  const _DecorDot({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: WasabiColors.primary.withValues(alpha: opacity),
      ),
    );
  }
}

class _OtpCodeInput extends StatefulWidget {
  const _OtpCodeInput({
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
  State<_OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<_OtpCodeInput> {
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
    final inactiveBorder =
        isDark ? Colors.white.withValues(alpha: .16) : const Color(0xFFE1E5DB);
    final disabledBorder =
        isDark ? Colors.white.withValues(alpha: .16) : const Color(0xFFE1E5DB);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final boxSize =
            ((constraints.maxWidth - (gap * (_length - 1))) / _length).clamp(
          44.0,
          56.0,
        );
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
                      final isFilled = digit.isNotEmpty;
                      final isActive =
                          _focusNode.hasFocus && index == code.length;
                      final borderColor = widget.hasError
                          ? const Color(0xFFE32626)
                          : isActive
                              ? WasabiColors.primary
                              : isFilled
                                  ? WasabiColors.primary.withValues(alpha: .68)
                                  : widget.enabled
                                      ? inactiveBorder
                                      : disabledBorder;
                      final cellColor = widget.hasError
                          ? fillColor
                          : isFilled
                              ? WasabiColors.primary.withValues(
                                  alpha: isDark ? .20 : .10,
                                )
                              : isActive
                                  ? WasabiColors.primary.withValues(
                                      alpha: isDark ? .16 : .06,
                                    )
                                  : fillColor;
                      return Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: index == _length - 1 ? 0 : gap,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOutCubic,
                          width: boxSize,
                          height: boxSize + 10,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              width: widget.hasError || isActive ? 2 : 1,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: WasabiColors.primary
                                          .withValues(alpha: .20),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            digit,
                            style: TextStyle(
                              color: isDark ? Colors.white : WasabiColors.dark,
                              fontSize: 26,
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

class _SecureVerificationCard extends StatelessWidget {
  const _SecureVerificationCard({required this.copy});

  final _AuthCopy copy;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF10140D).withValues(alpha: .92)
            : WasabiColors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? WasabiColors.primary.withValues(alpha: .24)
              : WasabiColors.stroke,
        ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  copy.secureTitle,
                  style: TextStyle(
                    color: isDark ? Colors.white : WasabiColors.dark,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  copy.secureText,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: .7)
                        : WasabiColors.muted,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
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

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xED161D11)
                : Colors.white.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isDark
                  ? WasabiColors.primary.withValues(alpha: .28)
                  : Colors.white,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: .30)
                    : WasabiColors.primary.withValues(alpha: .10),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ],
    );
  }
}

String _phoneValue(TextEditingController controller) {
  final raw = controller.text.trim();
  if (raw.startsWith('+')) return raw;
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('998')) return '+$digits';
  if (digits.startsWith('9')) return '+998$digits';
  return '+998$digits';
}

String _formattedPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('998')) {
    return '+${digits.substring(0, 3)} ${digits.substring(3, 5)} '
        '${digits.substring(5, 8)} ${digits.substring(8, 10)} '
        '${digits.substring(10, 12)}';
  }
  return phone;
}

String _editablePhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  var localDigits = digits;
  if (digits.startsWith('998') && digits.length > 3) {
    localDigits = digits.substring(3);
  }
  return _formattedInputValue(
    digits: localDigits,
    maxDigits: 9,
    groupLengths: const [2, 3, 2, 2],
    separator: ' ',
  ).text;
}

_AuthCopy _copy(String locale) => locale == 'uz' ? _uzCopy : _ruCopy;

String _errorText(Object error, String locale) {
  final copy = _copy(locale);
  if (error is ApiException) {
    switch (error.code) {
      case 'INVALID_PHONE':
        return copy.invalidPhone;
      case 'CLIENT_ALREADY_REGISTERED':
        return copy.clientAlreadyRegistered;
      case 'CLIENT_NOT_FOUND':
        return copy.clientNotFound;
      case 'INVALID_CREDENTIALS':
        return copy.invalidCredentials;
      case 'PASSWORD_TOO_SHORT':
        return copy.invalidCredentials;
      case 'SMS_CODE_INVALID':
        return copy.smsCodeInvalid;
      case 'SMS_CODE_EXPIRED':
        return copy.smsCodeExpired;
      case 'SMS_CODE_NOT_FOUND':
        return copy.smsCodeNotFound;
      case 'SMS_CODE_TOO_MANY_ATTEMPTS':
        return copy.smsCodeTooManyAttempts;
      case 'SMS_RESEND_TOO_EARLY':
      case 'RATE_LIMITED':
        return copy.smsResendTooEarly;
      case 'SMS_NOT_CONFIGURED':
        return copy.smsNotConfigured;
      case 'SMS_TEMPLATE_NOT_APPROVED':
        return copy.smsTemplateNotApproved;
      case 'SMS_SEND_FAILED':
        return copy.smsSendFailed;
    }
  }
  return error.toString();
}

bool _isSmsCodeError(Object error) {
  return error is ApiException &&
      (error.code?.startsWith('SMS_CODE_') ?? false);
}

class _AuthCopy {
  const _AuthCopy({
    required this.phone,
    required this.smsCode,
    required this.smsSentDetail,
    required this.didntReceive,
    required this.resendCode,
    required this.verifyCode,
    required this.secureTitle,
    required this.secureText,
    required this.editPhone,
    required this.next,
    required this.smsSent,
    required this.invalidPhone,
    required this.clientAlreadyRegistered,
    required this.clientNotFound,
    required this.invalidCredentials,
    required this.smsCodeInvalid,
    required this.smsCodeExpired,
    required this.smsCodeNotFound,
    required this.smsCodeTooManyAttempts,
    required this.smsResendTooEarly,
    required this.smsNotConfigured,
    required this.smsTemplateNotApproved,
    required this.smsSendFailed,
  });

  final String phone;
  final String smsCode;
  final String smsSentDetail;
  final String didntReceive;
  final String resendCode;
  final String verifyCode;
  final String secureTitle;
  final String secureText;
  final String editPhone;
  final String next;
  final String smsSent;
  final String invalidPhone;
  final String clientAlreadyRegistered;
  final String clientNotFound;
  final String invalidCredentials;
  final String smsCodeInvalid;
  final String smsCodeExpired;
  final String smsCodeNotFound;
  final String smsCodeTooManyAttempts;
  final String smsResendTooEarly;
  final String smsNotConfigured;
  final String smsTemplateNotApproved;
  final String smsSendFailed;
}

const _uzCopy = _AuthCopy(
  phone: 'Telefon',
  smsCode: 'SMS kodi',
  smsSentDetail: '6 xonali tasdiqlash kodini telefon raqamingizga yubordik',
  didntReceive: 'Kodni olmadingizmi?',
  resendCode: 'Kodni qayta yuborish',
  verifyCode: 'Tasdiqlash',
  secureTitle: 'Xavfsiz tasdiqlash',
  secureText: 'Telefon raqamingizni hech kim bilan ulashmaymiz.',
  editPhone: 'Telefonni tahrirlash',
  next: 'Keyingi',
  smsSent: 'SMS kodi yuborildi',
  invalidPhone: "Telefon raqami noto'g'ri",
  clientAlreadyRegistered:
      "Telefon raqamingiz oldin ro'yxatdan o'tgan, hisobingizga kiring.",
  clientNotFound: "Bu telefon raqami ro'yxatdan o'tmagan",
  invalidCredentials: "Telefon raqami yoki SMS kodi noto'g'ri",
  smsCodeInvalid: "SMS kodi noto'g'ri",
  smsCodeExpired: 'SMS kodi muddati tugagan',
  smsCodeNotFound: 'Avval SMS kod so‘rang',
  smsCodeTooManyAttempts: 'Urinishlar soni oshib ketdi, yangi kod so‘rang',
  smsResendTooEarly: 'SMS kodni qayta yuborishdan oldin kuting',
  smsNotConfigured: 'SMS xizmati sozlanmagan',
  smsTemplateNotApproved: 'SMS matni tasdiqlanmagan',
  smsSendFailed: 'SMS yuborilmadi',
);

const _ruCopy = _AuthCopy(
  phone: 'Телефон',
  smsCode: 'SMS-код',
  smsSentDetail: 'Мы отправили 6-значный код подтверждения на ваш номер',
  didntReceive: 'Не получили код?',
  resendCode: 'Отправить код повторно',
  verifyCode: 'Подтвердить',
  secureTitle: 'Безопасная проверка',
  secureText: 'Мы никому не передаем ваш номер телефона.',
  editPhone: 'Изменить телефон',
  next: 'Далее',
  smsSent: 'SMS-код отправлен',
  invalidPhone: 'Некорректный номер телефона',
  clientAlreadyRegistered: 'Этот номер уже зарегистрирован, войдите в аккаунт.',
  clientNotFound: 'Этот номер не зарегистрирован',
  invalidCredentials: 'Неверный телефон или SMS-код',
  smsCodeInvalid: 'Неверный SMS-код',
  smsCodeExpired: 'Срок действия SMS-кода истек',
  smsCodeNotFound: 'Сначала запросите SMS-код',
  smsCodeTooManyAttempts: 'Слишком много попыток, запросите новый код',
  smsResendTooEarly: 'Подождите перед повторной отправкой SMS',
  smsNotConfigured: 'SMS-сервис не настроен',
  smsTemplateNotApproved: 'SMS-шаблон не подтвержден',
  smsSendFailed: 'SMS не отправлено',
);
