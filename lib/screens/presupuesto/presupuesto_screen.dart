import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_storage/get_storage.dart';
import 'presupuesto_controller.dart';
import 'budget_detail_screen.dart';

String _fmt(num v) {
  final d = v.toDouble();
  return d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 2);
}

class PresupuestoScreen extends StatelessWidget {
  const PresupuestoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PresupuestoController>(
      init: PresupuestoController(),
      builder: (controller) => Scaffold(
        backgroundColor: const Color(0xFFF2F5F9),
        appBar: AppBar(
          title: const Text('Presupuesto'),
          elevation: 0,
          backgroundColor: const Color(0xFFF2F5F9),
          foregroundColor: Colors.black87,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Summary(controller: controller),
                const SizedBox(height: 12),
                ...controller.budgets
                    .map((b) => _BudgetCard(
                          budget: b,
                          onAddSpent: () => _openAddSpentSheet(context, controller, b),
                          onOpenDetail: () => Get.to(() => BudgetDetailScreen(budget: b)),
                          onDelete: () => _confirmDeleteBudget(context, controller, b),
                        ))
                    .toList(),
                const SizedBox(height: 100),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: GestureDetector(
                onTap: () => _openCreateBudgetSheet(context, controller),
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
                      BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.plus, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateBudgetSheet(BuildContext context, PresupuestoController controller) {
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController();
    String type = 'monthly';
    DateTime startDate = DateTime.now();
    bool saving = false;

    Get.bottomSheet(
      StatefulBuilder(builder: (ctx, setState) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        String dateLabel = '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
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
                Center(
                  child: Container(
                    width: 70,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Nuevo Presupuesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),

                const Text('Nombre del presupuesto', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej: Presupuesto mensual, Vacaciones...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Monto límite', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: limitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

                const SizedBox(height: 16),
                const Text('Tipo de presupuesto', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => type = 'daily'),
                        child: _SegmentButton(label: 'Diario', icon: LucideIcons.calendar, selected: type == 'daily'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => type = 'monthly'),
                        child: _SegmentButton(label: 'Mensual', icon: LucideIcons.trending_up, selected: type == 'monthly'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => type = 'activity'),
                        child: _SegmentButton(label: 'Actividad', icon: LucideIcons.target, selected: type == 'activity'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('Fecha inicio', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  readOnly: true,
                  controller: TextEditingController(text: dateLabel),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                            dateLabel = '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';
                          });
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    if (saving) return;
                    setState(() => saving = true);
                    try {
                      final name = nameCtrl.text.trim();
                      final limit = double.tryParse(limitCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                      if (name.isEmpty || limit <= 0) {
                        Get.snackbar('Datos incompletos', 'Ingresa nombre y límite', snackPosition: SnackPosition.BOTTOM);
                      } else {
                        await controller.createBudget(name: name, limitAmount: limit, period: type);
                        Get.back();
                      }
                    } catch (_) {
                      Get.snackbar('Error', 'No se pudo guardar', snackPosition: SnackPosition.BOTTOM);
                    } finally {
                      setState(() => saving = false);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: const Color(0xFFA7BFFA),
                    ),
                    alignment: Alignment.center,
                    child: saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                        : const Text('Crear Presupuesto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
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

  void _openAddSpentSheet(BuildContext context, PresupuestoController controller, Budget budget) {
    final amountCtrl = TextEditingController();
    bool saving = false;
    Get.bottomSheet(
      StatefulBuilder(builder: (ctx, setState) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
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
                    Text('Añadir gasto a ${budget.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(onTap: () => Get.back(), child: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Monto',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    if (saving) return;
                    setState(() => saving = true);
                    try {
                      final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                      if (amount <= 0) {
                        Get.snackbar('Monto inválido', 'Ingresa un monto mayor a 0', snackPosition: SnackPosition.BOTTOM);
                      } else {
                        await controller.addSpent(budget, amount);
                        Get.back();
                      }
                    } catch (_) {
                      Get.snackbar('Error', 'No se pudo guardar', snackPosition: SnackPosition.BOTTOM);
                    } finally {
                      setState(() => saving = false);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(18)),
                      gradient: LinearGradient(colors: [Color(0xFF10B981), Color(0xFF22C55E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    ),
                    alignment: Alignment.center,
                    child: saving
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                        : const Text('Añadir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
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

  void _confirmDeleteBudget(BuildContext context, PresupuestoController controller, Budget budget) {
    bool deleting = false;
    Get.bottomSheet(
      StatefulBuilder(builder: (ctx, setState) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text('Eliminar presupuesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  Spacer(),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Esta acción no se puede deshacer. Se eliminarán también sus partidas.', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        alignment: Alignment.center,
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (deleting) return;
                        setState(() => deleting = true);
                        try {
                          final db = FirebaseFirestore.instance;
                          
                          final itemsSnap = await db
                          .collection('presupuestos')
                          .doc(budget.id)
                          .collection('items')
                          .where('auth_uid', isEqualTo: GetStorage().read('auth_uid'))
                          .get();
                          final batch = db.batch();
                          for (final doc in itemsSnap.docs) {
                            batch.delete(doc.reference);
                          }
                          await batch.commit();
                          await controller.deleteBudget(budget.id);
                          Get.back();
                        } catch (_) {
                          Get.snackbar('Error', 'No se pudo eliminar', snackPosition: SnackPosition.BOTTOM);
                        } finally {
                          setState(() => deleting = false);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFF97316)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        ),
                        alignment: Alignment.center,
                        child: deleting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white))
                            : const Text('Eliminar presupuesto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}

class _Summary extends StatelessWidget {
  final PresupuestoController controller;
  const _Summary({required this.controller});

  @override
  Widget build(BuildContext context) {
    final spent = controller.totalSpent;
    final limit = controller.totalLimit;
    final remaining = controller.totalRemaining;
    final pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.gauge, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              const Text('Resumen del período', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryTile('Gastado', spent, Colors.red.shade600)),
              Expanded(child: _summaryTile('Límite', limit, Colors.black87)),
              Expanded(child: _summaryTile('Disponible', remaining, Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: pct,
              backgroundColor: const Color(0xFFE8EDF5),
              valueColor: AlwaysStoppedAnimation<Color>(pct < 0.8 ? const Color(0xFF6366F1) : Colors.red.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text('\$${_fmt(value)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final VoidCallback onAddSpent;
  final VoidCallback onOpenDetail;
  final VoidCallback onDelete;
  const _BudgetCard({required this.budget, required this.onAddSpent, required this.onOpenDetail, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = Color(budget.color);
    final pct = budget.limitAmount > 0 ? (budget.spentAmount / budget.limitAmount).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: onOpenDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x11000000), blurRadius: 12, offset: Offset(0, 4)),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(LucideIcons.badge_percent, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    budget.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.35)),
                  ),
                  child: Text(
                    budget.period == 'weekly' ? 'Semanal' : 'Mensual',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.35)),
                    ),
                    child: const Icon(LucideIcons.trash, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Gastado: \$${_fmt(budget.spentAmount)}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    ),
                    Text('Límite: \$${_fmt(budget.limitAmount)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: pct,
                    backgroundColor: const Color(0xFFE8EDF5),
                    valueColor: AlwaysStoppedAnimation<Color>(pct < 0.8 ? color : Colors.red.shade400),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Disponible: \$${_fmt((budget.limitAmount - budget.spentAmount).clamp(0.0, double.infinity))}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    Text('${(pct * 100).round()}%', style: TextStyle(fontSize: 12, color: pct < 0.8 ? Colors.black54 : Colors.red.shade600)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    GestureDetector(
                      onTap: onAddSpent,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Añadir gasto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  const _SegmentButton({required this.label, required this.icon, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2563F3) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: selected ? const Color(0xFF2563F3) : const Color(0xFFE5E7EB)),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? Colors.white : const Color(0xFF374151)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}