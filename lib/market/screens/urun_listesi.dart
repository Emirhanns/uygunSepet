import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'urun_ekleme_sayfasi.dart';

class UrunListesi extends StatefulWidget {
  const UrunListesi({super.key});

  @override
  State<UrunListesi> createState() => _UrunListesiState();
}

class _UrunListesiState extends State<UrunListesi> {
  final Logger logger = Logger();
  final TextEditingController _aramaController = TextEditingController();
  bool _yetkiliMi = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _urunler = [];
  
  // Filtreleme değişkenleri
  String _secilenMarka = '';
  String _secilenKategori = '';
  double? _minFiyat;
  double? _maxFiyat;
  List<String> _markalar = [];
  List<String> _kategoriler = [];

  @override
  void initState() {
    super.initState();
    _yetkiliKontrol();
    _urunleriGetir();
  }

  Future<void> _yetkiliKontrol() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _yetkiliMi = prefs.getBool('yetkili') ?? false;
    });

    if (!_yetkiliMi) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu sayfaya erişim yetkiniz yok')),
      );
    }
  }

  Future<void> _urunleriGetir() async {
    setState(() => _yukleniyor = true);
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('urunler')
          .where('status', isEqualTo: 1)
          .get();

      setState(() {
        _urunler = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'urunAdi': data['urunAdi'] ?? 'İsimsiz Ürün',
            'marka': data['marka'] ?? '',
            'kategori': data['kategori'] ?? '',
            'fiyat': (data['fiyat'] ?? 0.0).toDouble(),
            'stokMiktari': data['stokMiktari'] ?? 0,
            'minimumStokMiktari': data['minimumStokMiktari'] ?? 0,
            'barkod': data['barkod'] ?? '',
          };
        }).toList();

        // Marka ve kategorileri topla
        _markalar = _urunler.map((e) => e['marka'] as String).toSet().toList()..sort();
        _kategoriler = _urunler.map((e) => e['kategori'] as String).toSet().toList()..sort();
        
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ürünler yüklenirken hata oluştu: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _filtrelenmisUrunler() {
    return _urunler.where((urun) {
      bool markaUygun = _secilenMarka.isEmpty || urun['marka'] == _secilenMarka;
      bool kategoriUygun = _secilenKategori.isEmpty || urun['kategori'] == _secilenKategori;
      bool fiyatUygun = true;
      
      if (_minFiyat != null) {
        fiyatUygun = fiyatUygun && urun['fiyat'] >= _minFiyat!;
      }
      if (_maxFiyat != null) {
        fiyatUygun = fiyatUygun && urun['fiyat'] <= _maxFiyat!;
      }

      return markaUygun && kategoriUygun && fiyatUygun;
    }).toList();
  }

  Future<void> _fiyatAraligiSec() async {
    final TextEditingController minController = TextEditingController();
    final TextEditingController maxController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fiyat Aralığı Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              decoration: const InputDecoration(labelText: 'Minimum Fiyat'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: maxController,
              decoration: const InputDecoration(labelText: 'Maksimum Fiyat'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minFiyat = double.tryParse(minController.text);
                _maxFiyat = double.tryParse(maxController.text);
              });
              Navigator.pop(context);
            },
            child: const Text('Uygula'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _minFiyat = null;
                _maxFiyat = null;
              });
              Navigator.pop(context);
            },
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  Future<void> _urunSil(String barkod) async {
    try {
      await _firestore.collection('urunler').doc(barkod).update({'status': 0});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün başarıyla kaldırıldı')),
      );
      _urunleriGetir();
    } catch (e) {
      logger.e('Ürün kaldırılırken hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün kaldırılırken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtreliUrunler = _filtrelenmisUrunler();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Listesi'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Filtreleme Seçenekleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _secilenMarka.isEmpty ? null : _secilenMarka,
                        decoration: const InputDecoration(
                          labelText: 'Marka',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tümü'),
                          ),
                          ..._markalar.map((marka) => DropdownMenuItem(
                                value: marka,
                                child: Text(marka),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _secilenMarka = value ?? '');
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _secilenKategori.isEmpty ? null : _secilenKategori,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Tümü'),
                          ),
                          ..._kategoriler.map((kategori) => DropdownMenuItem(
                                value: kategori,
                                child: Text(kategori),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() => _secilenKategori = value ?? '');
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fiyatAraligiSec,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          _minFiyat != null || _maxFiyat != null
                              ? 'Fiyat: ${_minFiyat?.toStringAsFixed(2) ?? "Min"} - ${_maxFiyat?.toStringAsFixed(2) ?? "Max"} TL'
                              : 'Fiyat Aralığı Seç',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _secilenMarka = '';
                                _secilenKategori = '';
                                _minFiyat = null;
                                _maxFiyat = null;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Filtreleri Temizle'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Uygula'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : filtreliUrunler.isEmpty
              ? const Center(child: Text('Ürün bulunamadı'))
              : ListView.builder(
                  itemCount: filtreliUrunler.length,
                  itemBuilder: (context, index) {
                    final urun = filtreliUrunler[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          urun['urunAdi'] ?? 'İsimsiz Ürün',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Marka: ${urun['marka']}'),
                            Text('Kategori: ${urun['kategori']}'),
                            Text('Barkod: ${urun['barkod']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${urun['fiyat'].toStringAsFixed(2)} TL',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                                Text(
                                  'Stok: ${urun['stokMiktari']}',
                                  style: TextStyle(
                                    color: urun['stokMiktari'] <= 10
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UrunEklemeSayfasi(
                                      barkod: urun['barkod'],
                                    ),
                                  ),
                                ).then((_) => _urunleriGetir());
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Ürünü Sil'),
                                    content: const Text(
                                      'Bu ürünü silmek istediğinizden emin misiniz?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _urunSil(urun['barkod']);
                                        },
                                        child: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }
} 