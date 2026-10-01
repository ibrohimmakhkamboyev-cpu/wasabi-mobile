import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/app_models.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';
import 'map_picker_screen.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(isUz ? 'Manzillar' : 'Адреса доставки'),
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF86B914), Color(0xFF4E8204)],
          ),
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          onPressed: () => _showAddressForm(context),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: Text(isUz ? 'Qo‘shish' : 'Добавить'),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _AddressesBackground()),
          state.addresses.isEmpty
              ? EmptyState(
                  icon: Icons.location_on_outlined,
                  title: isUz ? 'Manzillar yo‘q' : 'Адресов пока нет',
                  text: isUz
                      ? 'Yetkazish uchun bir nechta manzil saqlashingiz mumkin.'
                      : 'Добавьте несколько адресов и выберите основной.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final addresses = [
                      ...state.addresses.where((address) => address.isPrimary),
                      ...state.addresses.where((address) => !address.isPrimary),
                    ];
                    final address = addresses[index];
                    return _AddressListItem(
                      address: address,
                      isUz: isUz,
                      onPrimary: () => state.setPrimaryAddress(address.id),
                      onEdit: () => _showAddressForm(context, address: address),
                      onDelete: () => state.deleteAddress(address.id),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: state.addresses.length,
                ),
        ],
      ),
    );
  }
}

class _AddressesBackground extends StatefulWidget {
  const _AddressesBackground();

  @override
  State<_AddressesBackground> createState() => _AddressesBackgroundState();
}

class _AddressListItem extends StatelessWidget {
  const _AddressListItem({
    required this.address,
    required this.isUz,
    required this.onPrimary,
    required this.onEdit,
    required this.onDelete,
  });

  final AddressModel address;
  final bool isUz;
  final VoidCallback onPrimary;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddressCard(
          premium: true,
          address: address,
          selected: address.isPrimary,
          onTap: onPrimary,
        ),
        Transform.translate(
          offset: const Offset(0, -8),
          child: _AddressActionBar(
            children: [
              if (!address.isPrimary)
                _AddressActionChip(
                  icon: Icons.star_rounded,
                  label: isUz ? 'Asosiy qilish' : 'Сделать основным',
                  onTap: onPrimary,
                ),
              _AddressActionChip(
                icon: Icons.edit_outlined,
                label: isUz ? 'Tahrirlash' : 'Изменить',
                onTap: onEdit,
              ),
              _AddressActionChip(
                icon: Icons.delete_outline_rounded,
                label: isUz ? 'O‘chirish' : 'Удалить',
                onTap: onDelete,
                danger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddressActionBar extends StatelessWidget {
  const _AddressActionBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: .76)),
          right: BorderSide(color: Colors.white.withValues(alpha: .76)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: .76)),
        ),
        boxShadow: [
          BoxShadow(
            color: WasabiColors.primary.withValues(alpha: .10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0)
              Container(
                width: 1,
                height: 42,
                color: WasabiColors.primary.withValues(alpha: .12),
              ),
            Expanded(child: children[index]),
          ],
        ],
      ),
    );
  }
}

class _AddressActionChip extends StatelessWidget {
  const _AddressActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFC62828) : WasabiColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressesBackgroundState extends State<_AddressesBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          const Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _AddressesBackgroundPainter(progress: .5),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = Curves.easeInOut.transform(_controller.value);
              final sparkle = 0.3 +
                  0.7 * (0.5 + 0.5 * math.sin(_controller.value * math.pi * 4));
              return Stack(
                children: [
                  _FloatingAddressIcon(
                    icon: Icons.eco_rounded,
                    left: .86,
                    top: .13,
                    size: 22,
                    opacity: .30,
                    progress: progress,
                  ),
                  _FloatingAddressIcon(
                    icon: Icons.eco_rounded,
                    left: .39,
                    top: .39,
                    size: 15,
                    opacity: .22,
                    progress: 1 - progress,
                  ),
                  _FloatingAddressIcon(
                    icon: Icons.eco_rounded,
                    left: .78,
                    top: .61,
                    size: 21,
                    opacity: .27,
                    progress: progress,
                  ),
                  _FloatingAddressIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: .73,
                    top: .12,
                    size: 15,
                    opacity: sparkle * .42,
                    progress: 0,
                  ),
                  _FloatingAddressIcon(
                    icon: Icons.auto_awesome_rounded,
                    left: .30,
                    top: .34,
                    size: 18,
                    opacity: sparkle * .52,
                    progress: 0,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddressesBackgroundPainter extends CustomPainter {
  const _AddressesBackgroundPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF9DA),
          Color(0xFFF8F7D5),
          Color(0xFFE9F6D2),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    _drawGlows(canvas, size);
    _drawCurves(canvas, size);
    _drawPin(canvas, size);
    _drawPlant(canvas, size);
    _drawWave(canvas, size);
  }

  void _drawGlows(Canvas canvas, Size size) {
    final circles = [
      (Offset(size.width * .84, size.height * .10), size.width * .28, .050),
      (Offset(size.width * .18, size.height * .53), size.width * .30, .040),
      (Offset(size.width * .78, size.height * .76), size.width * .35, .045),
    ];
    for (final c in circles) {
      final rect = Rect.fromCircle(
        center: c.$1,
        radius: c.$2 * (1 + progress * .025),
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [
              WasabiColors.primary.withValues(alpha: c.$3),
              Colors.transparent,
            ],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  void _drawCurves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: .58)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    final first = Path()
      ..moveTo(-size.width * .08, size.height * .54)
      ..cubicTo(size.width * .23, size.height * .62, size.width * .24,
          size.height * .42, size.width * .50, size.height * .45)
      ..cubicTo(size.width * .70, size.height * .47, size.width * .67,
          size.height * .22, size.width * 1.06, size.height * .28);
    canvas.drawPath(first, paint);

    final second = Path()
      ..moveTo(-size.width * .06, size.height * .78)
      ..cubicTo(size.width * .22, size.height * .68, size.width * .44,
          size.height * .78, size.width * .55, size.height * .88)
      ..cubicTo(size.width * .67, size.height * .99, size.width * .85,
          size.height * .91, size.width * 1.08, size.height * .96);
    canvas.drawPath(second, paint..color = Colors.white.withValues(alpha: .46));
  }

  void _drawPin(Canvas canvas, Size size) {
    final center = Offset(size.width * .82, size.height * .36);
    final path = Path()
      ..moveTo(center.dx, center.dy + size.width * .14)
      ..cubicTo(
          center.dx - size.width * .14,
          center.dy - size.width * .02,
          center.dx - size.width * .12,
          center.dy - size.width * .17,
          center.dx,
          center.dy - size.width * .17)
      ..cubicTo(
          center.dx + size.width * .12,
          center.dy - size.width * .17,
          center.dx + size.width * .14,
          center.dy - size.width * .02,
          center.dx,
          center.dy + size.width * .14)
      ..close();
    final paint = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .030)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.width * .05),
      size.width * .035,
      Paint()
        ..color = WasabiColors.primary.withValues(alpha: .025)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  void _drawPlant(Canvas canvas, Size size) {
    final base = Offset(size.width * .055, size.height * .94);
    final stem = Paint()
      ..color = WasabiColors.primary.withValues(alpha: .115)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final mainStem = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        size.width * .075,
        size.height * .88,
        size.width * .115,
        size.height * .83,
        size.width * .155,
        size.height * .76,
      );
    canvas.drawPath(mainStem, stem);

    final branchA = Path()
      ..moveTo(size.width * .085, size.height * .865)
      ..quadraticBezierTo(
        size.width * .055,
        size.height * .835,
        size.width * .030,
        size.height * .800,
      );
    canvas.drawPath(
        branchA, stem..color = WasabiColors.primary.withValues(alpha: .085));

    final branchB = Path()
      ..moveTo(size.width * .105, size.height * .835)
      ..quadraticBezierTo(
        size.width * .155,
        size.height * .805,
        size.width * .205,
        size.height * .785,
      );
    canvas.drawPath(
        branchB, stem..color = WasabiColors.primary.withValues(alpha: .095));

    for (final leaf in [
      (Offset(size.width * .150, size.height * .775), .18, .050, .135),
      (Offset(size.width * .203, size.height * .785), 1.05, .055, .105),
      (Offset(size.width * .035, size.height * .805), -.70, .060, .100),
      (Offset(size.width * .070, size.height * .895), -.38, .057, .080),
      (Offset(size.width * .125, size.height * .835), .55, .050, .090),
    ]) {
      _drawLeaf(canvas, leaf.$1, leaf.$2, size.width * leaf.$3, leaf.$4);
    }
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    double rotation,
    double radius,
    double opacity,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -radius)
      ..cubicTo(
          radius * 1.15, -radius * .45, radius * 1.05, radius * .70, 0, radius)
      ..cubicTo(-radius * 1.05, radius * .70, -radius * 1.15, -radius * .45, 0,
          -radius);
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius * 1.2);
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFA8C95A).withValues(alpha: opacity),
            WasabiColors.primary.withValues(alpha: opacity * .72),
          ],
        ).createShader(bounds)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .4),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -radius * .64)
        ..lineTo(0, radius * .58),
      Paint()
        ..color = Colors.white.withValues(alpha: opacity * .40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  void _drawWave(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * .875)
      ..cubicTo(size.width * .24, size.height * .835, size.width * .48,
          size.height * .935, size.width, size.height * .835)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = WasabiColors.primary.withValues(alpha: .055),
    );
  }

  @override
  bool shouldRepaint(covariant _AddressesBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _FloatingAddressIcon extends StatelessWidget {
  const _FloatingAddressIcon({
    required this.icon,
    required this.left,
    required this.top,
    required this.size,
    required this.opacity,
    required this.progress,
  });

  final IconData icon;
  final double left;
  final double top;
  final double size;
  final double opacity;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final color = icon == Icons.auto_awesome_rounded
        ? WasabiColors.secondary
        : WasabiColors.primary;
    return Positioned(
      left: screen.width * left,
      top: screen.height * top,
      child: Transform.translate(
        offset: Offset(0, (progress - .5) * 12),
        child: Icon(
          icon,
          color: color.withValues(alpha: opacity),
          size: size,
          shadows: [
            Shadow(
                color: color.withValues(alpha: opacity * .25), blurRadius: 8),
          ],
        ),
      ),
    );
  }
}

Future<void> _showAddressForm(BuildContext context, {AddressModel? address}) {
  final state = AppScope.of(context, listen: false);
  final addressController = TextEditingController(text: address?.address ?? '');
  final entrance = TextEditingController(text: address?.entrance ?? '');
  final floor = TextEditingController(text: address?.floor ?? '');
  final apartment = TextEditingController(text: address?.apartment ?? '');
  final intercom = TextEditingController(text: address?.intercom ?? '');
  final lat = TextEditingController(
      text: (address?.lat ?? 41.311081).toStringAsFixed(6));
  final lng = TextEditingController(
      text: (address?.lng ?? 69.240562).toStringAsFixed(6));
  final isUz = state.locale == 'uz';
  AddressModel selectedLocation = address ??
      AddressModel(
        id: 'preview',
        address: isUz ? 'Tanlangan manzil' : 'Выбранный адрес',
        lat: 41.311081,
        lng: 69.240562,
      );
  bool primary = address?.isPrimary ?? state.addresses.isEmpty;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          Future<void> pickLocation() async {
            final picked = await Navigator.of(context).push<AddressModel>(
              MaterialPageRoute(
                builder: (_) => MapPickerScreen(
                  initialAddress: selectedLocation,
                  returnSelection: true,
                ),
              ),
            );
            if (picked == null) return;
            setSheetState(() {
              selectedLocation = picked;
              lat.text = picked.lat.toStringAsFixed(6);
              lng.text = picked.lng.toStringAsFixed(6);
            });
          }

          Future<void> saveAddress() async {
            final model = AddressModel(
              id: address?.id ??
                  DateTime.now().microsecondsSinceEpoch.toString(),
              address: addressController.text.trim(),
              lat: double.tryParse(lat.text.replaceAll(',', '.')) ?? 41.311081,
              lng: double.tryParse(lng.text.replaceAll(',', '.')) ?? 69.240562,
              entrance:
                  entrance.text.trim().isEmpty ? null : entrance.text.trim(),
              floor: floor.text.trim().isEmpty ? null : floor.text.trim(),
              apartment:
                  apartment.text.trim().isEmpty ? null : apartment.text.trim(),
              intercom:
                  intercom.text.trim().isEmpty ? null : intercom.text.trim(),
              isPrimary: primary,
            );
            if (model.address.isEmpty) return;
            FocusManager.instance.primaryFocus?.unfocus();
            final navigator = Navigator.of(context);
            navigator.pop();
            await Future<void>.delayed(const Duration(milliseconds: 350));
            await state.upsertAddress(model);
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .90,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFFBE9),
                  Color(0xFFFBF8DE),
                  Color(0xFFEAF5D1),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AddressFormField(
                            controller: addressController,
                            label: isUz ? 'Joy nomi' : 'Название места',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 14),
                          _LocationSelectButton(
                            label: isUz
                                ? 'Lokatsiyani tanlash'
                                : 'Выбрать локацию',
                            onPressed: pickLocation,
                          ),
                          const SizedBox(height: 16),
                          DeliveryRouteCard(
                            compact: true,
                            onOpenMap: pickLocation,
                            address: AddressModel(
                              id: address?.id ?? 'preview',
                              address: selectedLocation.address,
                              lat: double.tryParse(
                                      lat.text.replaceAll(',', '.')) ??
                                  41.311081,
                              lng: double.tryParse(
                                      lng.text.replaceAll(',', '.')) ??
                                  69.240562,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              isUz
                                  ? 'Yetkazib berish xaritasi kuryerga yo‘l va masofani aniq hisoblash uchun kerak.'
                                  : 'Карта доставки нужна, чтобы точно рассчитать маршрут и расстояние для курьера.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: WasabiColors.muted,
                                    fontWeight: FontWeight.w600,
                                    height: 1.28,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _AddressFormField(
                                  controller: entrance,
                                  label: isUz ? 'Podyezd' : 'Подъезд',
                                  icon: Icons.home_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AddressFormField(
                                  controller: floor,
                                  label: isUz ? 'Qavat' : 'Этаж',
                                  icon: Icons.apartment_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _AddressFormField(
                                  controller: apartment,
                                  label: isUz ? 'Kvartira' : 'Квартира',
                                  icon: Icons.door_front_door_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AddressFormField(
                                  controller: intercom,
                                  label: isUz ? 'Domofon' : 'Домофон',
                                  icon: Icons.phone_iphone_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _PrimaryAddressTile(
                            value: primary,
                            onChanged: (value) =>
                                setSheetState(() => primary = value),
                            title: isUz ? 'Asosiy manzil' : 'Основной адрес',
                            subtitle: isUz
                                ? 'Bu manzil keyingi buyurtmalar uchun saqlanadi'
                                : 'Этот адрес сохранится для следующих заказов',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AddressSaveButton(
                    label: isUz ? 'Saqlash' : 'Сохранить',
                    onPressed: saveAddress,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _AddressFormField extends StatelessWidget {
  const _AddressFormField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: WasabiColors.primary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .88),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E4D8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: WasabiColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _LocationSelectButton extends StatelessWidget {
  const _LocationSelectButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          color: WasabiColors.primary.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: WasabiColors.primary.withValues(alpha: .10)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 18),
            const Icon(Icons.map_outlined, color: WasabiColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: WasabiColors.primary, size: 32),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAddressTile extends StatelessWidget {
  const _PrimaryAddressTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: WasabiColors.primary.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: WasabiColors.primary.withValues(alpha: .10)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: WasabiColors.primary.withValues(alpha: .10),
            ),
            child: const Icon(Icons.star_rounded, color: WasabiColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WasabiColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: WasabiColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AddressSaveButton extends StatelessWidget {
  const _AddressSaveButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF82B713), Color(0xFF4F8502)],
        ),
        boxShadow: [
          BoxShadow(
            color: WasabiColors.primary.withValues(alpha: .28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_outlined),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 58),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
