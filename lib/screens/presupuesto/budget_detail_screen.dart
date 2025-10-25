import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'presupuesto_controller.dart';
import 'budget_detail_controller.dart';

class BudgetDetailScreen extends StatelessWidget {
  final Budget budget;
  const BudgetDetailScreen({super.key, required this.budget});

  String _fmt(double v) {
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<BudgetDetailController>(
      init: BudgetDetailController(budget: budget),
      builder: (ctrl) {
        final theme = Theme.of(context);
        final totalPlanned = ctrl.totalPlanned;
        final totalSpent = ctrl.totalSpent;
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: false,
            title: Text(budget.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: Colors.black.withOpacity(0.06)),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(
                title: 'Resumen del presupuesto',
                budgetLimit: ctrl.parentLimit,
                budgetSpent: ctrl.parentSpent,
                itemsPlanned: totalPlanned,
                itemsSpent: totalSpent,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Partidas', style: theme.textTheme.titleMedium),
                  GestureDetector(
                    onTap: () => _openCreateItemSheet(context, ctrl),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      ),
                      child: const Row(
                        children: [
                          Icon(LucideIcons.plus, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Nueva partida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (ctrl.items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text('No hay partidas aún. Crea la primera arriba.'),
                )
              else
                ...ctrl.items.map((it) => _ItemRow(
                      item: it,
                      onAddSpent: () => _openAddItemSpentSheet(context, ctrl, it),
                      fmt: _fmt,
                    )),
            ],
          ),
        );
      },
    );
  }

  void _openCreateItemSheet(BuildContext context, BudgetDetailController ctrl) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Nueva partida', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.file_text, size: 18, color: Colors.black54),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Nombre de la partida (Alquiler, Luz…) ',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.dollar_sign, size: 18, color: Colors.black54),
                      const SizedBox(width: 10),
                      const Text('\$ ', style: TextStyle(color: Colors.black87)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'Monto planificado',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final name = nameCtrl.text.trim();
                    final planned = double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                    if (name.isEmpty || planned <= 0) {
                      Get.snackbar('Datos incompletos', 'Completa el nombre y monto', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    await ctrl.createItem(name: name, plannedAmount: planned);
                    Get.back();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Crear partida', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }

  void _openAddItemSpentSheet(BuildContext context, BudgetDetailController ctrl, BudgetItem item) {
    final amountCtrl = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Añadir gasto a ${item.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.dollar_sign, size: 18, color: Colors.black54),
                      const SizedBox(width: 10),
                      const Text('\$ ', style: TextStyle(color: Colors.black87)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            hintText: 'Monto',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                    if (amount <= 0) {
                      Get.snackbar('Monto inválido', 'Ingresa un monto mayor a 0', snackPosition: SnackPosition.BOTTOM);
                      return;
                    }
                    await ctrl.addSpentToItem(item, amount);
                    Get.back();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Añadir gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double budgetLimit;
  final double budgetSpent;
  final double itemsPlanned;
  final double itemsSpent;
  const _SummaryCard({
    required this.title,
    required this.budgetLimit,
    required this.budgetSpent,
    required this.itemsPlanned,
    required this.itemsSpent,
  });

  String _fmt(double v) {
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = budgetLimit > 0 ? (budgetSpent / budgetLimit).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Límite: \$${_fmt(budgetLimit)}')),
              Expanded(child: Text('Gastado: \$${_fmt(budgetSpent)}')),
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(value: ratio),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Planificado items: \$${_fmt(itemsPlanned)}')),
              Expanded(child: Text('Gastado items: \$${_fmt(itemsSpent)}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final BudgetItem item;
  final VoidCallback onAddSpent;
  final String Function(double) fmt;
  const _ItemRow({required this.item, required this.onAddSpent, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = item.plannedAmount > 0 ? (item.spentAmount / item.plannedAmount).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Plan: \$${fmt(item.plannedAmount)} · Gastado: \$${fmt(item.spentAmount)}',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onAddSpent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.plus, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text('Añadir gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          _ProgressBar(value: ratio),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth * value;
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: width,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(999)),
              gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22C55E)], begin: Alignment.centerLeft, end: Alignment.centerRight),
            ),
          ),
        );
      }),
    );
  }
}