import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:gastos/screens/ahorro/ahorro_controller.dart';
import 'package:intl/intl.dart';
import 'package:gastos/screens/ahorro/ahorro_detalle_screen.dart';

class AhorroScreen extends StatelessWidget {
  const AhorroScreen({super.key});

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  Widget _progressBar(double value, {double height = 10, List<Color> colors = const [Color(0xFF6366F1), Color(0xFFA855F7)], Color background = const Color(0xFFF3F4F6)}) {
    final v = value.clamp(0.0, 1.0);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCreateGoalSheet(BuildContext context, AhorroController controller) {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    String type = 'normal';
    double computedWeekly = 0.0;
    bool saving = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) => Container(
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
                children: [
                  const Text('Nueva meta de ahorro', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre de la meta', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto objetivo', border: OutlineInputBorder()),
                onChanged: (_) {
                  if (type == '52_weeks') {
                    final t = double.tryParse(targetCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                    setState(() => computedWeekly = t > 0 ? (t / 52) : 0.0);
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Libre'),
                    selected: type == 'normal',
                    onSelected: (_) {
                      setState(() {
                        type = 'normal';
                        computedWeekly = 0.0;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('52 semanas'),
                    selected: type == '52_weeks',
                    onSelected: (_) {
                      final t = double.tryParse(targetCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                      setState(() {
                        type = '52_weeks';
                        computedWeekly = t > 0 ? (t / 52) : 0.0;
                      });
                    },
                  ),
                ],
              ),
              if (type == '52_weeks') ...[
                const SizedBox(height: 10),
                Text('Depósito semanal estimado: ${_fmt(computedWeekly)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () async {
                  if (saving) return;
                  setState(() => saving = true);
                  try {
                    final name = nameCtrl.text.trim();
                    final target = double.tryParse(targetCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                    if (name.isEmpty || target <= 0) {
                      Get.snackbar('Datos incompletos', 'Ingresa un nombre y monto objetivo válido',
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      await controller.createGoal(name: name, target: target, type: type);
                      Get.back();
                    }
                  } catch (e) {
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
                          child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                        )
                      : const Text('Guardar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _openDepositSheet(BuildContext context, AhorroController controller, SavingsGoal goal) {
    final depositCtrl = TextEditingController(
      text: goal.type == '52_weeks' && (goal.weeklyAmount ?? 0) > 0 ? goal.weeklyAmount!.toStringAsFixed(2) : '',
    );
    bool saving = false;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (ctx, setState) => Container(
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
                children: [
                  const Text('Agregar depósito', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 14),
              Text(goal.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              TextField(
                controller: depositCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Monto a depositar', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () async {
                  if (saving) return;
                  setState(() => saving = true);
                  try {
                    final amt = double.tryParse(depositCtrl.text.trim().replaceAll(',', '')) ?? 0.0;
                    if (amt <= 0) {
                      Get.snackbar('Monto inválido', 'Ingresa un monto mayor a cero', snackPosition: SnackPosition.BOTTOM);
                    } else {
                      await controller.addDeposit(goal, amt);
                      Get.back();
                    }
                  } catch (e) {
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
                          child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.white),
                        )
                      : const Text('Guardar depósito',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AhorroController>(
      init: AhorroController(),
      builder: (controller) {
        final totalTarget = controller.totalTarget;
        final totalSaved = controller.totalSaved;
        final progress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;
        return Scaffold(
          appBar: AppBar(title: const Text('Ahorro')),

          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(18)),
                        gradient: LinearGradient(
                          colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Resumen de ahorro',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 8),
                          Text('Ahorrado: ${_fmt(totalSaved)}',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
                          const SizedBox(height: 4),
                          Text('Falta: ${_fmt((totalTarget - totalSaved).clamp(0.0, double.infinity))}',
                              style:
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 12),
                          _progressBar(progress, height: 10, colors: const [Colors.white, Colors.white], background: Colors.white24),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: controller.goals.isEmpty
                          ? const Center(child: Text('No hay metas de ahorro'))
                          : ListView.separated(
                              itemCount: controller.goals.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final g = controller.goals[i];
                                final p = g.targetAmount > 0
                                    ? (g.savedAmount / g.targetAmount).clamp(0.0, 1.0)
                                    : 0.0;
                                return GestureDetector(
                                  onTap: () => Get.to(() => AhorroDetalleScreen(goal: g)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 6)),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 4)),
                                            ],
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.savings_outlined, color: Colors.white),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  g.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                                ),
                                              ),
                                              if (g.type == '52_weeks') ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.22),
                                                    borderRadius: const BorderRadius.all(Radius.circular(999)),
                                                  ),
                                                  child: const Text(
                                                    '52 semanas',
                                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                                                  ),
                                                ),
                                              ],
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.white),
                                                onPressed: () => controller.deleteGoal(g.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Ahorrado: ${_fmt(g.savedAmount)} / ${_fmt(g.targetAmount)}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Expanded(child: _progressBar(p, height: 8)),
                                            const SizedBox(width: 8),
                                            Text('${(p * 100).round()}%',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                          ],
                                        ),
                                        if (g.type == '52_weeks') ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            'Semanas: ${(g.weeksCompleted ?? 0)}/52${(g.weeklyAmount ?? 0) > 0 ? ' • Depósito semanal: ${_fmt(g.weeklyAmount!)}' : ''}',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                                          ),
                                        ],
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: GestureDetector(
                                            onTap: () => _openDepositSheet(context, controller, g),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.all(Radius.circular(14)),
                                                gradient: LinearGradient(
                                                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Color(0x22000000),
                                                      blurRadius: 8,
                                                      offset: Offset(0, 4)),
                                                ],
                                              ),
                                              child: const Text(
                                                'Depositar',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w700),
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
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: GestureDetector(
                  onTap: () => _openCreateGoalSheet(context, controller),
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
                        BoxShadow(color: Color(0x33000000), blurRadius: 12, offset: Offset(0, 6)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white),
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
