// import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class Movement {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final double amount; // negativo = gasto, positivo = entrada
  final IconData icon;
  final Color color; // color base para el icon container

  Movement({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.icon,
    required this.color,
  });
}

enum PeriodFilter { thisMonth, lastMonth, all }

class HomeController extends GetxController {
  final box = GetStorage();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<Movement> movements = [];
  double totalSavings = 0.0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subMovs;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subSavings;

  // Filtro de periodo (por defecto: este mes)
  PeriodFilter periodFilter = PeriodFilter.thisMonth;

  // Totales del mes (en tiempo real, calculados sobre la lista de movimientos)
  double get totalSpentThisMonth {
    final now = DateTime.now();
    return movements
        .where((m) => m.amount < 0 && m.date.month == now.month && m.date.year == now.year)
        .fold(0.0, (sum, m) => sum + m.amount.abs());
  }

  double get totalIncomeThisMonth {
    final now = DateTime.now();
    return movements
        .where((m) => m.amount > 0 && m.date.month == now.month && m.date.year == now.year)
        .fold(0.0, (sum, m) => sum + m.amount);
  }

  // Lista ordenada por fecha desc
  List<Movement> get allMovementsSorted {
    final list = <Movement>[...movements];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  int get totalTransactions => movements.length;

  String get todayEs {
    final now = DateTime.now();
    const dias = ['lunes','martes','miércoles','jueves','viernes','sábado','domingo'];
    const meses = ['enero','febrero','marzo','abril','mayo','junio','julio','agosto','septiembre','octubre','noviembre','diciembre'];
    final dia = dias[now.weekday - 1];
    final mes = meses[now.month - 1];
    return 'Hoy, $dia, ${now.day} de $mes';
  }

  @override
  void onInit() {
    super.onInit();
    _listenMovements();
    _listenSavings();
    update();
  }

  void _listenMovements() {
    _subMovs = _db
        .collection('movimientos')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        // .orderBy('date', descending: true) // eliminado para evitar índices
        .snapshots()
        .listen((snap) {
      movements
        ..clear()
        ..addAll(snap.docs.map((d) {
          final data = d.data();
          DateTime date;
          final ts = data['date'];
          if (ts is Timestamp) {
            date = ts.toDate();
          } else if (ts is DateTime) {
            date = ts;
          } else {
            date = DateTime.now();
          }
          double _toDouble(dynamic v) {
            if (v == null) return 0.0;
            if (v is int) return v.toDouble();
            if (v is double) return v;
            if (v is String) return double.tryParse(v) ?? 0.0;
            return 0.0;
          }
          final amount = _toDouble(data['amount']);
          final categoryName = (data['categoryName'] ?? '').toString();
          final colorValue = data['categoryColor'] is int ? data['categoryColor'] as int : 0xFF93C5FD;
          final color = Color(colorValue);
          final icon = amount < 0 ? LucideIcons.arrow_down_right : LucideIcons.arrow_up_right;
          return Movement(
            id: d.id,
            title: (data['title'] ?? '').toString(),
            category: categoryName,
            date: date,
            amount: amount,
            icon: icon,
            color: color,
          );
        }));
      movements.sort((a, b) => b.date.compareTo(a.date)); // orden descendente en cliente
      update();
    });
  }

  void _listenSavings() {
    _subSavings = _db
        .collection('ahorros')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        .snapshots()
        .listen((snap) {
      double sum = 0.0;
      for (final d in snap.docs) {
        final data = d.data();
        double _toDouble(dynamic v) {
          if (v == null) return 0.0;
          if (v is int) return v.toDouble();
          if (v is double) return v;
          if (v is String) return double.tryParse(v) ?? 0.0;
          return 0.0;
        }
        sum += _toDouble(data['savedAmount']);
      }
      totalSavings = sum;
      update();
    });
  }

  Future<void> createMovement({
    required String title,
    required double amount,
    required String categoryId,
    required String categoryName,
    required String categoryEmoji,
    required Color categoryColor,
  }) async {
    await _db.collection('movimientos').add({
      'auth_uid': box.read('auth_uid'),
      'title': title,
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
      'type': amount >= 0 ? 'income' : 'expense',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryEmoji': categoryEmoji,
      'categoryColor': categoryColor.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMovement(String id) async {
    await _db.collection('movimientos').doc(id).delete();
  }

  @override
  void onClose() {
    _subMovs?.cancel();
    _subSavings?.cancel();
    super.onClose();
  }

  // ====== Helpers de rango y filtros ======
  DateTime _startOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime _endOfThisMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  DateTime _startOfLastMonth() {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    return DateTime(prev.year, prev.month, 1);
  }

  DateTime _endOfLastMonth() {
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    return DateTime(prev.year, prev.month + 1, 0, 23, 59, 59, 999);
  }

  List<Movement> get filteredMovements {
    if (periodFilter == PeriodFilter.all) return movements;
    late DateTime start;
    late DateTime end;
    switch (periodFilter) {
      case PeriodFilter.thisMonth:
        start = _startOfThisMonth();
        end = _endOfThisMonth();
        break;
      case PeriodFilter.lastMonth:
        start = _startOfLastMonth();
        end = _endOfLastMonth();
        break;
      case PeriodFilter.all:
        // handled arriba
        start = DateTime(1970);
        end = DateTime(2100);
        break;
    }
    return movements.where((m) {
      final d = m.date;
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  List<Movement> get filteredMovementsSorted {
    final list = <Movement>[...filteredMovements];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  double get totalSpentFiltered {
    return filteredMovements
        .where((m) => m.amount < 0)
        .fold(0.0, (sum, m) => sum + m.amount.abs());
  }

  double get totalIncomeFiltered {
    return filteredMovements
        .where((m) => m.amount > 0)
        .fold(0.0, (sum, m) => sum + m.amount);
  }

  int get totalTransactionsFiltered => filteredMovements.length;

  void setPeriod(PeriodFilter p) {
    periodFilter = p;
    update();
  }
}
