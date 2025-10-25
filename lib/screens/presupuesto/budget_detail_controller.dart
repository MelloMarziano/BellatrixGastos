import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'presupuesto_controller.dart';

class BudgetDetailController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final box = GetStorage();
  final Budget budget;
  List<BudgetItem> items = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _budgetSub;

  // Reflect parent budget live values
  double parentLimit;
  double parentSpent;

  BudgetDetailController({required this.budget})
      : parentLimit = budget.limitAmount,
        parentSpent = budget.spentAmount;

  double get totalPlanned => items.fold(0.0, (p, i) => p + i.plannedAmount);
  double get totalSpent => items.fold(0.0, (p, i) => p + i.spentAmount);

  @override
  void onInit() {
    super.onInit();
    _sub = _db
        .collection('presupuestos')
        .doc(budget.id)
        .collection('items')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        // .orderBy('createdAt', descending: false) // eliminado para evitar índices
        .snapshots()
        .listen((snap) {
      items = snap.docs.map((d) => BudgetItem.fromDoc(d)).toList();
      items.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate); // ascendente
      });
      update();
    });

    _budgetSub = _db
        .collection('presupuestos')
        .doc(budget.id)
        .snapshots()
        .listen((doc) {
      final data = doc.data() ?? {};
      double _toDouble(dynamic v) {
        if (v == null) return 0.0;
        if (v is int) return v.toDouble();
        if (v is double) return v;
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }
      parentLimit = _toDouble(data['limitAmount']);
      parentSpent = _toDouble(data['spentAmount']);
      update();
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    _budgetSub?.cancel();
    super.onClose();
  }

  Future<void> createItem({
    required String name,
    required double plannedAmount,
    String? category,
    DateTime? dueDate,
  }) async {
    await _db
        .collection('presupuestos')
        .doc(budget.id)
        .collection('items')
        .add({
      'name': name,
      'plannedAmount': plannedAmount,
      'spentAmount': 0.0,
      'category': category,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'createdAt': FieldValue.serverTimestamp(),
      'auth_uid': box.read('auth_uid'),
    });
  }

  Future<void> addSpentToItem(BudgetItem item, double amount) async {
    final itemRef = _db
        .collection('presupuestos')
        .doc(budget.id)
        .collection('items')
        .doc(item.id);
    final budgetRef = _db.collection('presupuestos').doc(budget.id);
    final batch = _db.batch();
    batch.update(itemRef, {
      'spentAmount': FieldValue.increment(amount),
    });
    batch.update(budgetRef, {
      'spentAmount': FieldValue.increment(amount),
    });
    await batch.commit();
  }

  Future<void> deleteItem(String id) async {
    await _db
        .collection('presupuestos')
        .doc(budget.id)
        .collection('items')
        .doc(id)
        .delete();
  }
}