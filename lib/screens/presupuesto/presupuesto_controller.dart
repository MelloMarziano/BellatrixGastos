import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class Budget {
  final String id;
  final String name;
  final double limitAmount;
  final double spentAmount;
  final String period; // monthly | weekly
  final int color; // ARGB int
  final DateTime? createdAt;

  const Budget({
    required this.id,
    required this.name,
    required this.limitAmount,
    required this.spentAmount,
    required this.period,
    required this.color,
    this.createdAt,
  });

  factory Budget.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    DateTime? created;
    final ts = data['createdAt'];
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    }
    return Budget(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      limitAmount: _toDouble(data['limitAmount']),
      spentAmount: _toDouble(data['spentAmount']),
      period: (data['period'] ?? 'monthly').toString(),
      color: data['color'] is int ? data['color'] as int : 0xFF6366F1,
      createdAt: created,
    );
  }
}

class PresupuestoController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final box = GetStorage();
  List<Budget> budgets = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  double get totalLimit => budgets.fold(0.0, (p, b) => p + b.limitAmount);
  double get totalSpent => budgets.fold(0.0, (p, b) => p + b.spentAmount);
  double get totalRemaining => (totalLimit - totalSpent).clamp(0.0, double.infinity);

  @override
  void onInit() {
    super.onInit();
    _sub = _db
        .collection('presupuestos')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        // .orderBy('createdAt', descending: false) // eliminado para evitar índices
        .snapshots()
        .listen((snap) {
      budgets = snap.docs.map((d) => Budget.fromDoc(d)).toList();
      budgets.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate); // ascendente
      });
      update();
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> createBudget({
    required String name,
    required double limitAmount,
    String period = 'monthly',
    Color color = const Color(0xFF6366F1),
  }) async {
    await _db.collection('presupuestos').add({
      'auth_uid': box.read('auth_uid'),
      'name': name,
      'limitAmount': limitAmount,
      'spentAmount': 0.0,
      'period': period,
      'color': color.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addSpent(Budget budget, double amount) async {
    await _db.collection('presupuestos').doc(budget.id).update({
      'spentAmount': budget.spentAmount + amount,
    });
  }

  Future<void> deleteBudget(String id) async {
    await _db.collection('presupuestos').doc(id).delete();
  }
}

class BudgetItem {
  final String id;
  final String name;
  final double plannedAmount;
  final double spentAmount;
  final String? category;
  final DateTime? dueDate;
  final DateTime? createdAt;

  const BudgetItem({
    required this.id,
    required this.name,
    required this.plannedAmount,
    required this.spentAmount,
    this.category,
    this.dueDate,
    this.createdAt,
  });

  factory BudgetItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }
    DateTime? created;
    final ts = data['createdAt'];
    if (ts is Timestamp) {
      created = ts.toDate();
    } else if (ts is DateTime) {
      created = ts;
    }
    DateTime? due;
    final ds = data['dueDate'];
    if (ds is Timestamp) {
      due = ds.toDate();
    } else if (ds is DateTime) {
      due = ds;
    }
    return BudgetItem(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      plannedAmount: _toDouble(data['plannedAmount']),
      spentAmount: _toDouble(data['spentAmount']),
      category: (data['category'] as String?),
      dueDate: due,
      createdAt: created,
    );
  }
}