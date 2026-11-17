import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/carousel_banner.dart';
import '../widgets/inventory_card.dart';
import '../widgets/search_field.dart';

/// Beranda: Search Bar, Carousel Slider, dan 3 bagian scroll horizontal
/// (Semua Data, Kategori Peralatan, Status).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InventoryService _service = InventoryService();
  late final Stream<List<Map<String, dynamic>>> _stream =
      _service.itemsStream();
  late final String? _uid;
  late final Stream<List<Map<String, dynamic>>>? _borrowStream;
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  String _category = 'Semua';
  String _status = 'Semua';

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final uid = _uid;
    _borrowStream = uid == null ? null : _service.borrowingsStream(uid);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _cari(List<Map<String, dynamic>> all) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((i) {
      final teks = '${i['item_name']} ${i['category']} ${i['code']}'
          .toLowerCase();
      return teks.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Beranda',
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
      body: SafeArea(
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
            if (_borrowStream == null) {
              return _konten(all, const [], loginError: true);
            }

            return StreamBuilder<List<Map<String, dynamic>>>(
              stream: _borrowStream,
              builder: (context, borrowSnapshot) => _konten(
                all,
                borrowSnapshot.data ?? const [],
                riwayatError: borrowSnapshot.error,
                riwayatLoading:
                    !borrowSnapshot.hasData && !borrowSnapshot.hasError,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _konten(
    List<Map<String, dynamic>> all,
    List<Map<String, dynamic>> borrowings, {
    Object? riwayatError,
    bool riwayatLoading = false,
    bool loginError = false,
  }) {
    final hasilCari = _cari(all);
    final kategori = <String>[
      'Semua',
      ...{
        ...kCategories,
        ...all
            .map((e) => (e['category'] ?? '').toString())
            .where((c) => c.isNotEmpty),
      },
    ];
    final perKategori = _category == 'Semua'
        ? hasilCari
        : hasilCari.where((e) => e['category'] == _category).toList();
    final perStatus = _status == 'Semua'
        ? hasilCari
        : hasilCari.where((e) => e['status'] == _status).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SearchField(
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              const CarouselBanner(),
              const SizedBox(height: 22),
              if (all.isEmpty)
                const SeedDataBox()
              else ...[
                _bagian(
                  judul: 'Semua Data',
                  ikon: Icons.apps_rounded,
                  warna: AppColors.primary,
                  items: hasilCari,
                  borrowings: borrowings,
                ),
                _bagian(
                  judul: 'Kategori Peralatan',
                  ikon: Icons.category_rounded,
                  warna: AppColors.roseDark,
                  items: perKategori,
                  borrowings: borrowings,
                  filter: _chips(
                    kategori,
                    _category,
                    (v) => setState(() => _category = v),
                  ),
                ),
                _bagian(
                  judul: 'Status',
                  ikon: Icons.fact_check_rounded,
                  warna: AppColors.accent,
                  items: perStatus,
                  borrowings: borrowings,
                  filter: _chips(
                    const ['Semua', 'Available', 'Borrowed'],
                    _status,
                    (v) => setState(() => _status = v),
                  ),
                ),
              ],
              _riwayat(
                borrowings,
                error: loginError
                    ? 'Silakan login untuk melihat riwayat.'
                    : riwayatError,
                loading: riwayatLoading,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _riwayat(
    List<Map<String, dynamic>> borrowings, {
    Object? error,
    bool loading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Riwayat Pinjam & Kembali',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (error != null)
          _kotakRiwayat(Text('Gagal memuat riwayat: $error'))
        else if (loading)
          const Center(child: CircularProgressIndicator())
        else if (borrowings.isEmpty)
          _kotakRiwayat(const Text(
            'Belum ada riwayat peminjaman.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ))
        else
          ...borrowings.map((borrowing) {
            final returned = borrowing['return_date'] != null;
            return Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    returned
                        ? Icons.assignment_return_rounded
                        : Icons.shopping_bag_rounded,
                    color: returned ? AppColors.available : AppColors.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (borrowing['item_name'] ?? '-').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          'Dipinjam: ${formatTanggal(borrowing['borrow_date'])}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          returned
                              ? 'Dikembalikan: ${formatTanggal(borrowing['return_date'])}'
                              : 'Belum dikembalikan',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _kotakRiwayat(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.borrowed : AppColors.available,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<bool> _tanya(String judul, String pesan, String ya, Color warna) async {
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
                backgroundColor: warna, foregroundColor: Colors.white),
            child: Text(ya),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  Future<void> _pinjam(Map<String, dynamic> item) async {
    final uid = _uid;
    if (uid == null) {
      _snack('Silakan login terlebih dahulu', error: true);
      return;
    }

    final ya = await _tanya(
      'Pinjam Barang',
      'Pinjam "${item['item_name']}" sekarang?',
      'Pinjam',
      AppColors.accent,
    );
    if (!ya || !mounted) return;

    try {
      await _service.borrowItem(uid: uid, item: item);
      if (!mounted) return;
      _snack('Berhasil meminjam ${item['item_name']}');
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal meminjam: $e', error: true);
    }
  }

  Future<void> _kembalikan(Map<String, dynamic> item) async {
    final uid = _uid;
    if (uid == null) {
      _snack('Silakan login terlebih dahulu', error: true);
      return;
    }

    final ya = await _tanya(
      'Kembalikan Barang',
      'Kembalikan "${item['item_name']}"?',
      'Kembalikan',
      AppColors.available,
    );
    if (!ya || !mounted) return;

    try {
      await _service.returnItem(
        uid: uid,
        itemId: item['item_id'].toString(),
      );
      if (!mounted) return;
      _snack('${item['item_name']} sudah dikembalikan');
    } catch (e) {
      if (!mounted) return;
      _snack('Gagal mengembalikan: $e', error: true);
    }
  }

  Widget _chips(
      List<String> opsi, String terpilih, ValueChanged<String> onPilih) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: opsi.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final o = opsi[i];
          final aktif = o == terpilih;
          return ChoiceChip(
            label: Text(o),
            selected: aktif,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
                color: aktif ? AppColors.primary : const Color(0xFFF0D8D8)),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: aktif ? Colors.white : AppColors.text,
            ),
            onSelected: (_) => onPilih(o),
          );
        },
      ),
    );
  }

  Widget _bagian({
    required String judul,
    required IconData ikon,
    required Color warna,
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> borrowings,
    Widget? filter,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(ikon, size: 18, color: warna),
            ),
            const SizedBox(width: 10),
            Text(judul,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: warna.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${items.length} barang',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: warna)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (filter != null) ...[filter, const SizedBox(height: 10)],
        SizedBox(
          height: 250,
          child: items.isEmpty
              ? const Center(
                  child: Text('Tidak ada data yang cocok',
                      style: TextStyle(color: AppColors.muted)),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final status = (item['status'] ?? 'Available').toString();
                    final activeBorrowing = borrowings.any(
                      (borrowing) =>
                          borrowing['item_id'] == item['item_id'] &&
                          borrowing['return_date'] == null,
                    );

                    return SizedBox(
                      width: 160,
                      child: InventoryCard(
                        item: item,
                        compact: true,
                        onTap: () => showItemDetail(context, item),
                        onBorrow: status == 'Available'
                            ? () => _pinjam(item)
                            : null,
                        onReturn: status == 'Borrowed' && activeBorrowing
                            ? () => _kembalikan(item)
                            : null,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }
}
