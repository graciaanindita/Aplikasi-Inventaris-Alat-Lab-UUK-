import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';

/// Gambar barang dari URL. Jika gagal dimuat, tampil ikon kategori.
class ItemImage extends StatelessWidget {
  final String url;
  final String category;

  const ItemImage({super.key, required this.url, required this.category});

  Widget _placeholder() {
    final c = categoryColor(category);
    return Container(
      color: c.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(categoryIcon(category), color: c, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stack) => _placeholder(),
    );
  }
}

/// Lencana status: Available (hijau) / Borrowed (merah).
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final c = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style:
                TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final c = categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(categoryIcon(category), size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            category,
            style:
                TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

/// Kartu barang. compact = true untuk scroll horizontal di Beranda,
/// compact = false untuk daftar di halaman Inventaris (ada tombol aksi).
class InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool compact;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onBorrow;
  final VoidCallback? onReturn;

  const InventoryCard({
    super.key,
    required this.item,
    this.compact = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onBorrow,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final name = (item['item_name'] ?? '-').toString();
    final category = (item['category'] ?? '-').toString();
    final status = (item['status'] ?? 'Available').toString();
    final image = (item['image'] ?? '').toString();
    final code = (item['code'] ?? '-').toString();

    return compact
        ? _compact(name, category, status, image)
        : _list(name, category, status, image, code);
  }

  Widget _compact(String name, String category, String status, String image) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ItemImage(url: image, category: category)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    category,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: categoryColor(category)),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(status: status),
                  if (onBorrow != null || onReturn != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: status == 'Borrowed'
                          ? OutlinedButton(
                              onPressed: onReturn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.borrowed,
                                side: const BorderSide(
                                    color: AppColors.borrowed),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Kembalikan',
                                  style: TextStyle(fontSize: 11)),
                            )
                          : ElevatedButton(
                              onPressed: onBorrow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                elevation: 0,
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Pinjam',
                                  style: TextStyle(fontSize: 11)),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
      String name, String category, String status, String image, String code) {
    final hasMenu = onEdit != null || onDelete != null;
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: ItemImage(url: image, category: category),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text),
                          ),
                        ),
                        if (hasMenu)
                          SizedBox(
                            width: 28,
                            height: 24,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert_rounded,
                                  size: 20, color: AppColors.muted),
                              onSelected: (v) {
                                if (v == 'edit') onEdit?.call();
                                if (v == 'delete') onDelete?.call();
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'edit',
                                    child: Row(children: [
                                      Icon(Icons.edit_rounded,
                                          size: 18, color: AppColors.primary),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ])),
                                PopupMenuItem(
                                    value: 'delete',
                                    child: Row(children: [
                                      Icon(Icons.delete_rounded,
                                          size: 18, color: AppColors.borrowed),
                                      SizedBox(width: 8),
                                      Text('Hapus'),
                                    ])),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(code,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _CategoryChip(category: category),
                        StatusBadge(status: status),
                      ],
                    ),
                    if (onBorrow != null || onReturn != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 34,
                        child: status == 'Borrowed'
                            ? OutlinedButton.icon(
                                onPressed: onReturn,
                                icon: const Icon(Icons.assignment_return_rounded,
                                    size: 16),
                                label: const Text('Kembalikan',
                                    style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.borrowed,
                                  side: const BorderSide(
                                      color: AppColors.borrowed),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: onBorrow,
                                icon: const Icon(Icons.shopping_bag_rounded,
                                    size: 16),
                                label: const Text('Pinjam',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menampilkan detail barang (bottom sheet).
void showItemDetail(BuildContext context, Map<String, dynamic> item) {
  final name = (item['item_name'] ?? '-').toString();
  final category = (item['category'] ?? '-').toString();
  final status = (item['status'] ?? 'Available').toString();

  Widget row(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style:
                      const TextStyle(color: AppColors.muted, fontSize: 13)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: ItemImage(
                      url: (item['image'] ?? '').toString(),
                      category: category),
                ),
              ),
              const SizedBox(height: 16),
              Text(name,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text)),
              const SizedBox(height: 8),
              StatusBadge(status: status),
              const SizedBox(height: 16),
              row('Kode', (item['code'] ?? '-').toString()),
              row('Kategori', category),
              row('Spesifikasi', (item['spesification'] ?? '-').toString()),
              row('Ditambahkan', formatTanggal(item['created_at'])),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Kotak "data kosong" dengan tombol untuk mengisi data dummy ke Firestore.
class SeedDataBox extends StatefulWidget {
  const SeedDataBox({super.key});

  @override
  State<SeedDataBox> createState() => _SeedDataBoxState();
}

class _SeedDataBoxState extends State<SeedDataBox> {
  bool _loading = false;

  Future<void> _seed() async {
    setState(() => _loading = true);
    try {
      await InventoryService().seedDummyData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengisi data dummy: $e'),
            backgroundColor: AppColors.borrowed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 56, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text('Belum ada data inventaris',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Isi data dummy ke Firestore atau tambah barang manual.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loading ? null : _seed,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome_rounded),
            label: const Text('Isi Data Dummy'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
