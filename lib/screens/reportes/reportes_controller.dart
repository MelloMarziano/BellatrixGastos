import 'dart:async';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

class ReportDateTotal {
  final DateTime day;
  final double total;
  final int count;
  ReportDateTotal({required this.day, required this.total, required this.count});
}

class ReportCategoryTotal {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final double total;
  final int count;
  ReportCategoryTotal({
    required this.id,
    required this.name,
    required this.emoji,
    required this.color,
    required this.total,
    required this.count,
  });
}

class ReportesController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final box = GetStorage();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  // Filtros
  String type = 'all'; // all | expense | income
  String group = 'date'; // date | category
  late DateTime startDate;
  late DateTime endDate;

  // Datos
  List<Map<String, dynamic>> _all = []; // movimientos crudos
  List<Map<String, dynamic>> filtered = [];
  List<ReportDateTotal> byDate = [];
  List<ReportCategoryTotal> byCategory = [];
  double totalAmount = 0.0;
  int totalCount = 0;

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate = DateTime(now.year, now.month, 1);
    endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = _db
        .collection('movimientos')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        // .orderBy('date', descending: true) // eliminado para evitar índices
        .snapshots()
        .listen((snap) {
      _all = snap.docs.map((d) {
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
        return {
          'id': d.id,
          'title': (data['title'] ?? '').toString(),
          'categoryId': (data['categoryId'] ?? '').toString(),
          'categoryName': (data['categoryName'] ?? '').toString(),
          'categoryEmoji': (data['categoryEmoji'] ?? '🏷️').toString(),
          'categoryColor': data['categoryColor'] is int ? data['categoryColor'] as int : 0xFF93C5FD,
          'amount': _toDouble(data['amount']),
          'date': date,
          'type': (data['type'] ?? 'expense').toString(),
        };
      }).toList();
      // Orden descendente por fecha en cliente
      _all.sort((a, b) {
        final ad = a['date'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b['date'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
      _recompute();
    });
  }

  void setType(String t) {
    type = t;
    _recompute();
  }

  void setGroup(String g) {
    group = g;
    update();
  }

  void setStartDate(DateTime d) {
    startDate = DateTime(d.year, d.month, d.day);
    _recompute();
  }

  void setEndDate(DateTime d) {
    endDate = DateTime(d.year, d.month, d.day, 23, 59, 59);
    _recompute();
  }

  void _recompute() {
    filtered = _all.where((m) {
      final DateTime date = m['date'] as DateTime;
      final double amount = m['amount'] as double;
      final String t = type;
      final bool inRange = !date.isBefore(startDate) && !date.isAfter(endDate);
      final bool typeOk = t == 'all' ? true : (t == 'expense' ? amount < 0 : amount > 0);
      return inRange && typeOk;
    }).toList();

    totalCount = filtered.length;
    if (type == 'expense') {
      totalAmount = filtered.fold(0.0, (s, m) => s + (m['amount'] as double).abs());
      totalAmount = -totalAmount; // mostrar con signo negativo
    } else if (type == 'income') {
      totalAmount = filtered.fold(0.0, (s, m) => s + (m['amount'] as double));
    } else {
      totalAmount = filtered.fold(0.0, (s, m) => s + (m['amount'] as double));
    }

    if (group == 'date') {
      _groupByDate();
    } else {
      _groupByCategory();
    }
    update();
  }

  void _groupByDate() {
    final Map<String, double> sum = {};
    final Map<String, int> count = {};
    final Map<String, DateTime> dayRef = {};
    for (final m in filtered) {
      final date = m['date'] as DateTime;
      final key = '${date.year}-${date.month}-${date.day}';
      double val = m['amount'] as double;
      if (type == 'expense') val = -val.abs();
      sum[key] = (sum[key] ?? 0.0) + val;
      count[key] = (count[key] ?? 0) + 1;
      dayRef[key] = DateTime(date.year, date.month, date.day);
    }
    final items = sum.keys.map((k) => ReportDateTotal(day: dayRef[k]!, total: sum[k]!, count: count[k]!)).toList();
    items.sort((a, b) => b.day.compareTo(a.day));
    byDate = items;
    byCategory = [];
  }

  void _groupByCategory() {
    final Map<String, double> sum = {};
    final Map<String, int> count = {};
    final Map<String, Map<String, dynamic>> catData = {};
    for (final m in filtered) {
      final id = (m['categoryId'] ?? '') as String;
      final name = (m['categoryName'] ?? '') as String;
      final emoji = (m['categoryEmoji'] ?? '🏷️') as String;
      final colorValue = (m['categoryColor'] ?? 0xFF93C5FD) as int;
      double val = m['amount'] as double;
      if (type == 'expense') val = -val.abs();
      sum[id] = (sum[id] ?? 0.0) + val;
      count[id] = (count[id] ?? 0) + 1;
      catData[id] = {'name': name, 'emoji': emoji, 'color': Color(colorValue)};
    }
    final items = sum.keys.map((id) {
      final meta = catData[id]!;
      return ReportCategoryTotal(
        id: id,
        name: meta['name'] as String,
        emoji: meta['emoji'] as String,
        color: meta['color'] as Color,
        total: sum[id]!,
        count: count[id]!,
      );
    }).toList();
    items.sort((a, b) => b.total.compareTo(a.total));
    byCategory = items;
    byDate = [];
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
