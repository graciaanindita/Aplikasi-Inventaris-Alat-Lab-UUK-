import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _waktu(dynamic v) => v is Timestamp ? v.toDate() : DateTime.now();

class InventoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');

  // URL foto barang
  final Map<String, String> _images = {
    'LAB-KMP-001':
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600',
    'LAB-KMP-002':
        'https://images.unsplash.com/photo-1544244015-0df4b3ffc6b0?w=600',
    'LAB-FOT-001':
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=600',
    'LAB-FOT-002':
        'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?w=600',
    'LAB-FOT-003':
        'https://images.unsplash.com/photo-1520390138845-fd2d229dd553?w=600',
    'LAB-AUD-001':
        'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=600',
    'LAB-AUD-002':
        'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=600',
    'LAB-PRN-001':
        'https://images.unsplash.com/photo-1612198188060-c7c2a3b66eae?w=600',
    'LAB-PRS-001':
        'https://images.unsplash.com/photo-1535016120720-40c646be5580?w=600',
  };

  // Menampilkan semua barang secara real-time
  Stream<List<Map<String, dynamic>>> itemsStream() {
    return _items.snapshots().map((snap) {
      final list = snap.docs.map((d) {
        final data = Map<String, dynamic>.from(d.data());
        data['item_id'] = d.id;
        return data;
      }).toList();

      list.sort(
        (a, b) => _waktu(b['created_at']).compareTo(_waktu(a['created_at'])),
      );

      return list;
    });
  }

  // Menambahkan barang
  Future<void> addItem(Map<String, dynamic> data) async {
    final ref = _items.doc();

    await ref.set({
      'item_id': ref.id,
      ...data,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Mengedit barang
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _items.doc(itemId).update(data);
  }

  // Menghapus barang
  Future<void> deleteItem(String itemId) async {
    await _items.doc(itemId).delete();
  }

  // Meminjam barang
  Future<void> borrowItem({
    required String uid,
    required Map<String, dynamic> item,
  }) async {
    final itemId = item['item_id'].toString();
    final borrowRef = _db
        .collection('users')
        .doc(uid)
        .collection('borrowings')
        .doc();
    final itemRef = _items.doc(itemId);

    await _db.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemRef);
      if (!itemSnapshot.exists) {
        throw StateError('Barang tidak ditemukan.');
      }
      if (itemSnapshot.data()?['status'] != 'Available') {
        throw StateError('Barang sedang tidak tersedia.');
      }
      final itemData = itemSnapshot.data()!;

      transaction.set(borrowRef, {
        'borrow_id': borrowRef.id,
        'item_id': itemId,
        'item_name': itemData['item_name'],
        'item_code': itemData['code'],
        'borrow_date': FieldValue.serverTimestamp(),
        'return_date': null,
      });
      transaction.update(itemRef, {
        'status': 'Borrowed',
        'borrower_uid': uid,
      });
    });
  }

  // Mengembalikan barang
  Future<void> returnItem({
    required String uid,
    required String itemId,
  }) async {
    final borrowings = _db
        .collection('users')
        .doc(uid)
        .collection('borrowings');
    final matchingDocs =
        await borrowings.where('item_id', isEqualTo: itemId).get();
    final activeDocs = matchingDocs.docs
        .where((doc) => doc.data()['return_date'] == null)
        .toList();

    if (activeDocs.isEmpty) {
      throw StateError('Tidak ditemukan peminjaman aktif untuk barang ini.');
    }
    if (activeDocs.length > 1) {
      throw StateError('Ditemukan lebih dari satu peminjaman aktif.');
    }

    final itemRef = _items.doc(itemId);
    final borrowingRef = activeDocs.single.reference;

    await _db.runTransaction((transaction) async {
      final itemSnapshot = await transaction.get(itemRef);
      final borrowingSnapshot = await transaction.get(borrowingRef);
      if (!itemSnapshot.exists || !borrowingSnapshot.exists) {
        throw StateError('Data barang atau peminjaman tidak ditemukan.');
      }

      final itemData = itemSnapshot.data()!;
      final borrowingData = borrowingSnapshot.data()!;
      if (itemData['status'] != 'Borrowed' ||
          (itemData['borrower_uid'] != null &&
              itemData['borrower_uid'] != uid) ||
          borrowingData['return_date'] != null) {
        throw StateError('Status peminjaman sudah berubah.');
      }

      transaction.update(borrowingRef, {
        'return_date': FieldValue.serverTimestamp(),
      });
      transaction.update(itemRef, {
        'status': 'Available',
        'borrower_uid': FieldValue.delete(),
      });
    });
  }

  // Riwayat peminjaman
  Stream<List<Map<String, dynamic>>> borrowingsStream(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('borrowings')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Map<String, dynamic>.from(d.data()))
              .toList();

          list.sort(
            (a, b) =>
                _waktu(b['borrow_date']).compareTo(_waktu(a['borrow_date'])),
          );

          return list;
        });
  }

  // Memperbarui foto barang lama di Firestore
  Future<void> updateDummyImages() async {
    for (final entry in _images.entries) {
      final result = await _items.where('code', isEqualTo: entry.key).get();

      for (final doc in result.docs) {
        await doc.reference.update({'image': entry.value});
      }
    }
  }

  // Menambahkan data dummy jika collection masih kosong
  Future<bool> seedDummyData() async {
    final cek = await _items.limit(1).get();

    if (cek.docs.isNotEmpty) return false;

    final data = <Map<String, String>>[
      {
        'item_name': 'Laptop Asus Vivobook',
        'category': 'Komputer',
        'code': 'LAB-KMP-001',
        'status': 'Available',
        'image': _images['LAB-KMP-001']!,
        'spesification': 'Intel Core i5, RAM 8GB, SSD 512GB, layar 14 inci',
      },
      {
        'item_name': 'Tablet Samsung Galaxy Tab',
        'category': 'Komputer',
        'code': 'LAB-KMP-002',
        'status': 'Available',
        'image': _images['LAB-KMP-002']!,
        'spesification': 'Layar 11 inci, Wi-Fi, kamera depan dan belakang',
      },
      {
        'item_name': 'Kamera DSLR Canon EOS',
        'category': 'Fotografi',
        'code': 'LAB-FOT-001',
        'status': 'Available',
        'image': _images['LAB-FOT-001']!,
        'spesification': 'Kamera DSLR, lensa kit, baterai dan tas kamera',
      },
      {
        'item_name': 'Tripod Kamera',
        'category': 'Fotografi',
        'code': 'LAB-FOT-002',
        'status': 'Available',
        'image': _images['LAB-FOT-002']!,
        'spesification': 'Tripod aluminium, tinggi maksimal 160 cm',
      },
      {
        'item_name': 'Ring Light LED',
        'category': 'Fotografi',
        'code': 'LAB-FOT-003',
        'status': 'Available',
        'image': _images['LAB-FOT-003']!,
        'spesification': 'Ring light LED dengan pengatur kecerahan dan tripod',
      },
      {
        'item_name': 'Speaker Aktif',
        'category': 'Audio',
        'code': 'LAB-AUD-001',
        'status': 'Available',
        'image': _images['LAB-AUD-001']!,
        'spesification': 'Speaker aktif dengan koneksi Bluetooth dan kabel daya',
      },
      {
        'item_name': 'Mikrofon Wireless',
        'category': 'Audio',
        'code': 'LAB-AUD-002',
        'status': 'Available',
        'image': _images['LAB-AUD-002']!,
        'spesification': 'Mikrofon wireless dengan receiver dan baterai',
      },
      {
        'item_name': 'Printer Epson EcoTank',
        'category': 'Komputer',
        'code': 'LAB-PRN-001',
        'status': 'Available',
        'image': _images['LAB-PRN-001']!,
        'spesification': 'Printer ink tank multifungsi untuk cetak dan scan',
      },
      {
        'item_name': 'Proyektor Epson',
        'category': 'Presentasi',
        'code': 'LAB-PRS-001',
        'status': 'Available',
        'image': _images['LAB-PRS-001']!,
        'spesification': '3600 lumens, resolusi XGA, input HDMI dan VGA',
      },
    ];

    final batch = _db.batch();
    final now = DateTime.now();

    for (var i = 0; i < data.length; i++) {
      final ref = _items.doc();

      batch.set(ref, {
        'item_id': ref.id,
        ...data[i],
        'created_at': Timestamp.fromDate(now.subtract(Duration(minutes: i))),
      });
    }

    await batch.commit();
    return true;
  }
}
