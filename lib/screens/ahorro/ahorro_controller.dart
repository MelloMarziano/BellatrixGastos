import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final String type; // 'normal' | '52_weeks'
  final double? weeklyAmount;
  final int? weeksCompleted;
  final DateTime? createdAt;

  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    required this.type,
    this.weeklyAmount,
    this.weeksCompleted,
    this.createdAt,
  });

  factory SavingsGoal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
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
    return SavingsGoal(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      targetAmount: _toDouble(data['targetAmount']),
      savedAmount: _toDouble(data['savedAmount']),
      type: (data['type'] ?? 'normal').toString(),
      weeklyAmount: data['weeklyAmount'] != null ? _toDouble(data['weeklyAmount']) : null,
      weeksCompleted: data['weeksCompleted'] is int ? data['weeksCompleted'] as int : (int.tryParse('${data['weeksCompleted']}') ?? null),
      createdAt: created,
    );
  }
}

class AhorroController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final box = GetStorage();
  List<SavingsGoal> goals = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  double get totalSaved => goals.fold(0.0, (p, g) => p + g.savedAmount);
  double get totalTarget => goals.fold(0.0, (p, g) => p + g.targetAmount);
  double get totalRemaining => (totalTarget - totalSaved).clamp(0.0, double.infinity);

  @override
  void onInit() {
    super.onInit();
    _sub = _db
        .collection('ahorros')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        // .orderBy('createdAt', descending: false) // eliminado para evitar índices
        .snapshots()
        .listen((snap) {
      goals = snap.docs.map((d) => SavingsGoal.fromDoc(d)).toList();
      goals.sort((a, b) {
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

  Future<void> createGoal({required String name, required double target, String type = 'normal'}) async {
    double? weekly;
    int? weeksCompleted;
    if (type == '52_weeks') {
      weekly = target / 52;
      weeksCompleted = 0;
    }
    await _db.collection('ahorros').add({
      'auth_uid': box.read('auth_uid'),
      'name': name,
      'targetAmount': target,
      'savedAmount': 0.0,
      'type': type,
      'weeklyAmount': weekly,
      'weeksCompleted': weeksCompleted,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addDeposit(SavingsGoal goal, double amount) async {
    final docRef = _db.collection('ahorros').doc(goal.id);
    final updates = <String, dynamic>{'savedAmount': goal.savedAmount + amount};
    if (goal.type == '52_weeks') {
      updates['weeksCompleted'] = (goal.weeksCompleted ?? 0) + 1;
    }
    await docRef.update(updates);
    await docRef.collection('movimientos').add({
      'auth_uid': box.read('auth_uid'),
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
      'type': 'deposit',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteGoal(String id) async {
    await _db.collection('ahorros').doc(id).delete();
  }
}
