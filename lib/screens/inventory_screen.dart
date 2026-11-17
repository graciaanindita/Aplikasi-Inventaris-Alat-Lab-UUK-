import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/inventory_card.dart';
import '../widgets/search_field.dart';

/// Inventaris: daftar real-time dengan aksi Tambah, Edit, dan Hapus.
class InventoryScreen extends StatefulWidget {
  final bool isOwner;

  const InventoryScreen({super.key, required this.isOwner});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final InventoryService _service = InventoryService();
  late final Stream<List<Map<String, dynamic>>> _stream = _service
      .itemsStream();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _snack(String pesan, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: error ? AppColors.borrowed : AppColors.available,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _tanya(
    String judul,
    String pesan,
    String ya,
    Color warna,
  ) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(judul, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: warna,
              foregroundColor: Colors.white,
            ),
            child: Text(ya),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  String? _wajib(String? v) => (v ?? '').trim().isEmpty ? 'Wajib diisi' : null;

  String? _url(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Wajib diisi';
    if (!t.startsWith('http://') && !t.startsWith('https://')) {
      return 'Harus berupa link URL (http/https)';
    }
    return null;
  }

  /// Form untuk menambah barang baru atau mengedit barang yang sudah ada.
  Future<void> _tampilkanForm([Map<String, dynamic>? item]) async {
    if (!widget.isOwner) {
      _snack('Hanya owner yang dapat mengelola inventaris', error: true);
      return;
    }
    if (item?['status'] == 'Borrowed') {
      _snack('Barang sedang dipinjam dan tidak bisa diedit', error: true);
      return;
    }

    final String? editId;
    if (item == null) {
      editId = null;
    } else {
      final value = item['item_id'];
      if (value is! String || value.isEmpty) {
        _snack('ID barang tidak valid', error: true);
        return;
      }
      editId = value;
    }
    final isEdit = editId != null;

    final formKey = GlobalKey<FormState>();
    final namaC = TextEditingController(
      text: item?['item_name']?.toString() ?? '',
    );
    final kodeC = TextEditingController(text: item?['code']?.toString() ?? '');
    final gambarC = TextEditingController(
      text: item?['image']?.toString() ?? '',
    );
    final spesC = TextEditingController(
      text: item?['spesification']?.toString() ?? '',
    );

    final kategoriLama = item?['category']?.toString() ?? '';
    final daftarKategori = <String>{
      ...kCategories,
      if (kategoriLama.isNotEmpty) kategoriLama,
    }.toList();
    String kategori = kategoriLama.isNotEmpty
        ? kategoriLama
        : kCategories.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          isEdit ? 'Edit Barang' : 'Tambah Barang',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaC,
                    decoration: appInput(
                      'Nama Barang',
                      Icons.inventory_2_rounded,
                    ),
                    validator: _wajib,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: kodeC,
                    decoration: appInput('Kode Barang', Icons.qr_code_rounded),
                    validator: _wajib,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: kategori,
                    isExpanded: true,
                    decoration: appInput('Kategori', Icons.category_rounded),
                    items: daftarKategori
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => kategori = v ?? kategori,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: gambarC,
                    keyboardType: TextInputType.url,
                    decoration: appInput(
                      'Link URL Gambar',
                      Icons.image_rounded,
                    ),
                    validator: _url,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: spesC,
                    maxLines: 3,
                    decoration: appInput(
                      'Spesifikasi',
                      Icons.description_rounded,
                    ),
                    validator: _wajib,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'item_name': namaC.text.trim(),
                'category': kategori,
                'code': kodeC.text.trim(),
                'image': gambarC.text.trim(),
                'spesification': spesC.text.trim(),
                if (!isEdit) 'status': 'Available',
              };
              final navigator = Navigator.of(dialogContext);
              try {
                if (editId == null) {
                  await _service.addItem(data);
                } else {
                  await _service.updateItem(editId, data);
                }
                navigator.pop();
                if (!mounted) return;
                _snack(
                  isEdit
                      ? 'Barang berhasil diperbarui'
                      : 'Barang berhasil ditambahkan',
                );
              } catch (e) {
                if (!mounted) return;
                _snack('Gagal menyimpan: $e', error: true);
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _hapus(Map<String, dynamic> item) async {
    if (!widget.isOwner) {
      _snack('Hanya owner yang dapat mengelola inventaris', error: true);
      return;
    }
    if (item['status'] == 'Borrowed') {
      _snack('Barang sedang dipinjam dan tidak bisa dihapus', error: true);
      return;
    }

    final ya = await _tanya(
      'Hapus Barang',
      'Yakin ingin menghapus "${item['item_name']}"?',
      'Hapus',
      AppColors.borrowed,
    );
    if (!ya) return;
    try {
      await _service.deleteItem(item['item_id'].toString());
      if (!mounted) return;
      _snack('Barang berhasil dihapus');
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal menghapus: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventaris',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: appGradient),
        ),
      ),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: () => _tampilkanForm(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Produk'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SearchField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _stream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat data. Periksa Rules Firestore.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final all = snapshot.data!;
                if (all.isEmpty) {
                  return Center(
                    child: Text(
                      widget.isOwner
                          ? 'Belum ada produk. Tekan "Tambah Produk" untuk mulai.'
                          : 'Belum ada produk.',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  );
                }

                final q = _query.trim().toLowerCase();
                final items = q.isEmpty
                    ? all
                    : all.where((i) {
                        final teks =
                            '${i['item_name']} ${i['category']} ${i['code']}'
                                .toLowerCase();
                        return teks.contains(q);
                      }).toList();

                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada data yang cocok',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  );
                }
                // Daftar inventaris
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final canManage =
                        widget.isOwner && item['status'] != 'Borrowed';
                    return InventoryCard(
                      item: item,
                      onTap: () => showItemDetail(context, item),
                      onEdit: canManage ? () => _tampilkanForm(item) : null,
                      onDelete: canManage ? () => _hapus(item) : null,
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
