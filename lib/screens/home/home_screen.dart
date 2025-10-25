import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:get_storage/get_storage.dart';
import 'home_controller.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatAmount(double value) {
    final absFormatted = NumberFormat('#,##0.00', 'es').format(value.abs());
    final sign = value < 0 ? '-' : '+';
    return '$sign\$$absFormatted';
  }

  String _monthShort(int month) {
    const meses = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return meses[(month - 1).clamp(0, 11)];
  }

  void _openCreateMovementSheet(
    BuildContext context,
    HomeController controller,
  ) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String type = 'expense';
    String? selectedCategoryId;
    String? selectedCategoryName;
    String? selectedCategoryEmoji;
    Color? selectedCategoryColor;
    bool saving = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.9,
            padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Nuevo movimiento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => type = 'expense'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: type == 'expense'
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFEF4444),
                                        Color(0xFFF97316),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFE5E7EB),
                                        Color(0xFFE5E7EB),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Gasto',
                              style: TextStyle(
                                color: type == 'expense'
                                    ? Colors.white
                                    : const Color(0xFF374151),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => type = 'income'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: type == 'income'
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF22C55E),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFE5E7EB),
                                        Color(0xFFE5E7EB),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Entrada',
                              style: TextStyle(
                                color: type == 'income'
                                    ? Colors.white
                                    : const Color(0xFF374151),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Categoría',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('categorias')
                        .where('auth_uid', isEqualTo: GetStorage().read('auth_uid'))
                        // .orderBy('createdAt', descending: true) // eliminado para evitar índices
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Text('No hay categorías creadas');
                      }
                      final sorted = docs.toList()
                        ..sort((a, b) {
                          final aData = a.data();
                          final bData = b.data();
                          DateTime aDate;
                          final aTs = aData['createdAt'];
                          if (aTs is Timestamp) {
                            aDate = aTs.toDate();
                          } else if (aTs is DateTime) {
                            aDate = aTs;
                          } else {
                            aDate = DateTime.fromMillisecondsSinceEpoch(0);
                          }
                          DateTime bDate;
                          final bTs = bData['createdAt'];
                          if (bTs is Timestamp) {
                            bDate = bTs.toDate();
                          } else if (bTs is DateTime) {
                            bDate = bTs;
                          } else {
                            bDate = DateTime.fromMillisecondsSinceEpoch(0);
                          }
                          return bDate.compareTo(aDate); // descendente
                        });
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 1.0,
                            ),
                        itemCount: sorted.length,
                        itemBuilder: (context, i) {
                          final d = sorted[i];
                          final data = d.data();
                          final name = (data['name'] ?? '').toString();
                          final emoji = (data['emoji'] ?? '🏷️').toString();
                          final color = Color(
                            (data['color'] ?? 0xFF6366F1) as int,
                          );
                          final isSelected = selectedCategoryId == d.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryId = d.id;
                                selectedCategoryName = name;
                                selectedCategoryEmoji = emoji;
                                selectedCategoryColor = color;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4F46E5)
                                      : const Color(0xFFE5E7EB),
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      if (saving) return;
                      setState(() => saving = true);
                      try {
                        final title = titleCtrl.text.trim();
                        final amount =
                            double.tryParse(
                              amountCtrl.text.trim().replaceAll(',', ''),
                            ) ??
                            0.0;
                        if (title.isEmpty ||
                            amount <= 0 ||
                            selectedCategoryId == null) {
                          Get.snackbar(
                            'Datos incompletos',
                            'Ingresa título, monto y categoría',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        } else {
                          final signedAmount = type == 'expense'
                              ? -amount
                              : amount;
                          await controller.createMovement(
                            title: title,
                            amount: signedAmount,
                            categoryId: selectedCategoryId!,
                            categoryName: selectedCategoryName!,
                            categoryEmoji: selectedCategoryEmoji!,
                            categoryColor: selectedCategoryColor!,
                          );
                          Get.back();
                        }
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'No se pudo guardar',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } finally {
                        setState(() => saving = false);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                        gradient: LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: saving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HomeController>(
      init: HomeController(),
      builder: (controller) {
        final periodLabel = () {
          switch (controller.periodFilter) {
            case PeriodFilter.thisMonth:
              return 'Este mes';
            case PeriodFilter.lastMonth:
              return 'Mes pasado';
            case PeriodFilter.all:
              return 'Siempre';
          }
        }();
        return DefaultTabController(
          length: 2,
          child: Stack(
            children: [
              SafeArea(
                top: true,
                bottom: false,
                child: Container(
                  color: Color(0xFFf6f7f9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.todayEs,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.setPeriod(PeriodFilter.thisMonth),
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: controller.periodFilter == PeriodFilter.thisMonth
                                          ? const LinearGradient(
                                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: controller.periodFilter == PeriodFilter.thisMonth
                                          ? null
                                          : const Color(0xFFE5E7EB),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Este mes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: controller.periodFilter == PeriodFilter.thisMonth
                                              ? Colors.white
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.setPeriod(PeriodFilter.lastMonth),
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: controller.periodFilter == PeriodFilter.lastMonth
                                          ? const LinearGradient(
                                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: controller.periodFilter == PeriodFilter.lastMonth
                                          ? null
                                          : const Color(0xFFE5E7EB),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Mes pasado',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: controller.periodFilter == PeriodFilter.lastMonth
                                              ? Colors.white
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => controller.setPeriod(PeriodFilter.all),
                                  child: Container(
                                    height: 36,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: controller.periodFilter == PeriodFilter.all
                                          ? const LinearGradient(
                                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: controller.periodFilter == PeriodFilter.all
                                          ? null
                                          : const Color(0xFFE5E7EB),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Siempre',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: controller.periodFilter == PeriodFilter.all
                                              ? Colors.white
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 112,
                              child: _SummaryCard(
                                title: 'TOTAL GASTADO',
                                value: _formatAmount(
                                  -controller.totalSpentFiltered,
                                ),
                                subtitle: periodLabel,
                                gradientColors: const [
                                  Color(0xFFEF4444),
                                  Color(0xFFF97316),
                                ],
                                icon: LucideIcons.arrow_down_right,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 112,
                              child: _SummaryCard(
                                title: 'TOTAL ENTRADAS',
                                value: _formatAmount(
                                  controller.totalIncomeFiltered,
                                ),
                                subtitle: periodLabel,
                                gradientColors: const [
                                  Color(0xFF10B981),
                                  Color(0xFF22C55E),
                                ],
                                icon: LucideIcons.arrow_up_right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 112,
                              child: _SummaryCard(
                                title: 'DISPONIBLE',
                                value: _formatAmount(
                                  controller.totalIncomeFiltered - controller.totalSpentFiltered,
                                ),
                                subtitle: periodLabel,
                                gradientColors: const [
                                  Color(0xFF6366F1),
                                  Color(0xFFA855F7),
                                ],
                                icon: LucideIcons.calculator,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 112,
                              child: _SummaryCard(
                                title: 'TOTAL AHORRADO',
                                value: _formatAmount(controller.totalSavings),
                                subtitle: 'Tiempo real',
                                gradientColors: const [
                                  Color(0xFF2563EB),
                                  Color(0xFF3B82F6),
                                ],
                                icon: LucideIcons.wallet,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Movimientos Recientes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${controller.totalTransactionsFiltered} movimientos',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // QUITO TABS Y MUESTRO LISTA COMBINADA
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: controller.filteredMovementsSorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final m = controller.filteredMovementsSorted[index];
                           return _MovementItem(
                             title: m.title,
                             category: m.category,
                             dateLabel:
                                 '${m.date.day} ${_monthShort(m.date.month)}',
                             amountLabel: _formatAmount(m.amount),
                             amountColor: m.amount < 0
                                 ? const Color(0xFFEF4444)
                                 : const Color(0xFF10B981),
                             icon: m.icon,
                             iconBg: m.color,
                             onDelete: () => controller.deleteMovement(m.id),
                           );
                         },
                       ),
                    ),
                  ],
                ),
              ),
              ),
              Positioned(
                right: 16,
                bottom: 16,
                child: GestureDetector(
                  onTap: () => _openCreateMovementSheet(context, controller),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.plus,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.gradientColors,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final List<Color> gradientColors;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            bottom: 10,
            child: IgnorePointer(
              ignoring: true,
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.18),
                size: 80,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  const _MovementItem({
    required this.title,
    required this.category,
    required this.dateLabel,
    required this.amountLabel,
    required this.amountColor,
    required this.icon,
    required this.iconBg,
    required this.onDelete,
  });

  final String title;
  final String category;
  final String dateLabel;
  final String amountLabel;
  final Color amountColor;
  final IconData icon;
  final Color iconBg;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [iconBg.withOpacity(0.9), iconBg.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  LucideIcons.trash,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
