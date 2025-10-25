import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

import 'ahorro_controller.dart';

class AhorroDetalleScreen extends StatelessWidget {
  final SavingsGoal goal;
  const AhorroDetalleScreen({super.key, required this.goal});

  String _fmt(double v) => NumberFormat('#,##0.00', 'en_US').format(v);

  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(goal.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
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
                  const Text(
                    'Resumen',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ahorrado: ${_fmt(goal.savedAmount)} / ${_fmt(goal.targetAmount)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('ahorros')
                  .doc(goal.id)
                  .collection('movimientos')
                  .where('auth_uid', isEqualTo: GetStorage().read('auth_uid'))
                  // .orderBy('date', descending: true) // eliminado para evitar índices
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Sin movimientos registrados'));
                }
                final sorted = docs.toList()
                  ..sort((a, b) {
                    DateTime aDate;
                    final aTs = a.data()['date'];
                    if (aTs is Timestamp) {
                      aDate = aTs.toDate();
                    } else if (aTs is DateTime) {
                      aDate = aTs;
                    } else {
                      aDate = DateTime.fromMillisecondsSinceEpoch(0);
                    }
                    DateTime bDate;
                    final bTs = b.data()['date'];
                    if (bTs is Timestamp) {
                      bDate = bTs.toDate();
                    } else if (bTs is DateTime) {
                      bDate = bTs;
                    } else {
                      bDate = DateTime.fromMillisecondsSinceEpoch(0);
                    }
                    return bDate.compareTo(aDate); // descendente
                  });
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final data = sorted[i].data();
                    double amount = 0.0;
                    final rawAmount = data['amount'];
                    if (rawAmount is int) amount = rawAmount.toDouble();
                    else if (rawAmount is double) amount = rawAmount;
                    else if (rawAmount is String) amount = double.tryParse(rawAmount) ?? 0.0;
                    DateTime date;
                    final ts = data['date'];
                    if (ts is Timestamp) {
                      date = ts.toDate();
                    } else if (ts is DateTime) {
                      date = ts;
                    } else {
                      date = DateTime.now();
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(10)),
                              gradient: LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Depósito',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _fmtDate(date),
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _fmt(amount),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}