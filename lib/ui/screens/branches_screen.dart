import 'package:flutter/material.dart';

import '../../services/native_bridge.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final isUz = state.locale == 'uz';
    return Scaffold(
      appBar: AppBar(title: Text(isUz ? 'Filiallar' : 'Филиалы')),
      body: state.branches.isEmpty
          ? EmptyState(
              icon: Icons.storefront_outlined,
              title: isUz ? 'Filiallar topilmadi' : 'Филиалы не найдены',
              text: isUz
                  ? 'Ma’lumot backend orqali keladi.'
                  : 'Список филиалов загружается из админки сайта.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final branch = state.branches[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          branch.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        _InfoLine(
                            icon: Icons.location_on_outlined,
                            text: branch.address),
                        if (branch.workTime != null)
                          _InfoLine(
                              icon: Icons.schedule, text: branch.workTime!),
                        if (branch.phone != null)
                          _InfoLine(
                              icon: Icons.phone_outlined, text: branch.phone!),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    branch.lat == null || branch.lng == null
                                        ? null
                                        : () => NativeBridge.openUrl(
                                              'https://maps.google.com/?q=${branch.lat},${branch.lng}',
                                            ),
                                icon: const Icon(Icons.map_outlined),
                                label: Text(isUz ? 'Xarita' : 'На карте'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: branch.phone == null
                                    ? null
                                    : () => NativeBridge.openUrl(
                                        'tel:${branch.phone}'),
                                icon: const Icon(Icons.call_outlined),
                                label: Text(isUz ? 'Qo‘ng‘iroq' : 'Позвонить'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: state.branches.length,
            ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: WasabiColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
