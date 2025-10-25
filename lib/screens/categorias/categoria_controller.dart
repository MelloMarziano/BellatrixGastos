import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart'
    ;
import 'dart:async';
import 'package:get_storage/get_storage.dart';

class Category {
  final String id;
  final String name;
  final String emoji;
  final Color color;

  Category({required this.id, required this.name, required this.emoji, required this.color});

  factory Category.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Category(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      emoji: (data['emoji'] ?? '🏷️') as String,
      color: Color(((data['color'] ?? 0xFF6366F1) as int)),
    );
  }
}

class CategoriaController extends GetxController {
  // Lista de categorías en memoria (llenada por Firestore)
  final List<Category> categories = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final box = GetStorage();

  // Estado del formulario
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController customEmojiCtrl = TextEditingController();

  final List<String> emojiOptions = const [
    // Lista reducida y ordenada (originales mejor alineados)
    '🍔', '🚗', '🎮', '💊', '🛒', '🏠',
    '✈️', '📱', '👕', '🎬', '📚', '🏆',
  ];

  final List<Color> colorPalette = const [
    Color(0xFFFF4F7D), // rojo/rosa
    Color(0xFFF59E0B), // naranja
    Color(0xFF34D399), // verde
    Color(0xFF3B82F6), // azul
    Color(0xFFA78BFA), // morado
    Color(0xFFF472B6), // fucsia
  ];

  String selectedEmoji = '🍔';
  Color selectedColor = const Color(0xFFFF4F7D);
bool isSaving = false;

  StreamSubscription<QuerySnapshot>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _db
        .collection('categorias')
        .where('auth_uid', isEqualTo: box.read('auth_uid'))
        // .orderBy('createdAt', descending: true) // eliminado para evitar índices
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs.toList();
      docs.sort((a, b) {
        final aData = (a.data() as Map<String, dynamic>);
        final bData = (b.data() as Map<String, dynamic>);
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
        return bDate.compareTo(aDate); // orden descendente
      });
      categories
        ..clear()
        ..addAll(docs.map((d) => Category.fromDoc(d)));
      update();
    });
  }

  void setSelectedEmoji(String e) {
    selectedEmoji = e;
    update(['sheet']);
  }

  void setSelectedColor(Color c) {
    selectedColor = c;
    update(['sheet']);
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection('categorias').doc(id).delete();
  }

  void openCreateCategorySheet() {
    nameCtrl.clear();
    customEmojiCtrl.clear();
    selectedEmoji = emojiOptions.first;
    selectedColor = colorPalette.first;

    _openCategorySheet(title: 'Crear Categoría', actionLabel: 'Crear', onConfirm: _onCreateCategory);
  }

  void openEditCategorySheet(Category cat) {
    nameCtrl.text = cat.name;
    customEmojiCtrl.text = '';
    selectedEmoji = cat.emoji;
    selectedColor = cat.color;

    _openCategorySheet(
      title: 'Editar Categoría',
      actionLabel: 'Guardar',
      onConfirm: () => _onUpdateCategory(cat.id),
    );
  }

  void _openCategorySheet({required String title, required String actionLabel, required Future<void> Function() onConfirm}) {
    Get.bottomSheet(
      Container(
        width: double.infinity,
        height: MediaQuery.of(Get.context!).size.height * 0.8,
        color: Colors.white,
        child: GetBuilder<CategoriaController>(
          id: 'sheet',
          builder: (_) {
            final String effectiveEmoji =
                (customEmojiCtrl.text.trim().isNotEmpty)
                ? customEmojiCtrl.text.trim()
                : selectedEmoji;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Nombre',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ej: Restaurantes',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Icono',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          effectiveEmoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Elige uno o pega el tuyo'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: emojiOptions.length,
                    itemBuilder: (context, index) {
                      final e = emojiOptions[index];
                      final bool isSelected =
                          e == selectedEmoji &&
                          customEmojiCtrl.text.trim().isEmpty;
                      return GestureDetector(
                        onTap: () => setSelectedEmoji(e),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(e, style: const TextStyle(fontSize: 26)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customEmojiCtrl,
                    onChanged: (_) => update(['sheet']),
                    decoration: InputDecoration(
                      labelText: 'Emoji personalizado (opcional)',
                      hintText: 'Pega cualquier emoji como 🎯 o 🦄',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Color',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    children: colorPalette.map((c) {
                      final bool selected = c.value == selectedColor.value;
                      return GestureDetector(
                        onTap: () => setSelectedColor(c),
                        child: Container(
                          width: 56,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF111827)
                                  : const Color(0xFFE5E7EB),
                              width: selected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () async {
                      if (isSaving) return;
                      isSaving = true;
                      update(['sheet']);
                      try {
                        await onConfirm();
                        Get.back();
                      } catch (e) {
                        Get.snackbar(
                          'Error',
                          'No se pudo guardar',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      } finally {
                        isSaving = false;
                        update(['sheet']);
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
                      child: isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              actionLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                     ),
                   ),
                ],
              ),
            );
          },
        ),
      ),
      isScrollControlled: true,
      enableDrag: true,
    );
  }

  Future<void> _onCreateCategory() async {
    final name = nameCtrl.text.trim();
    final emoji = customEmojiCtrl.text.trim().isNotEmpty
        ? customEmojiCtrl.text.trim()
        : selectedEmoji;

    if (name.isEmpty) {
      Get.snackbar(
        'Nombre requerido',
        'Ingresa un nombre de categoría',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _db.collection('categorias').add({
      'auth_uid': box.read('auth_uid'),
      'name': name,
      'emoji': emoji,
      'color': selectedColor.value,
      'createdAt': FieldValue.serverTimestamp(),
    });

    Get.back();
  }

  Future<void> _onUpdateCategory(String id) async {
    final name = nameCtrl.text.trim();
    final emoji = customEmojiCtrl.text.trim().isNotEmpty
        ? customEmojiCtrl.text.trim()
        : selectedEmoji;

    if (name.isEmpty) {
      Get.snackbar(
        'Nombre requerido',
        'Ingresa un nombre de categoría',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await _db.collection('categorias').doc(id).update({
      'name': name,
      'emoji': emoji,
      'color': selectedColor.value,
    });

    Get.back();
  }

  @override
  void onClose() {
    _sub?.cancel();
    nameCtrl.dispose();
    customEmojiCtrl.dispose();
    super.onClose();
  }
}
