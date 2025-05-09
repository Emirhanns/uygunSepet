import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IkmalGerektirenUrunler extends StatefulWidget {
  const IkmalGerektirenUrunler({super.key});

  @override
  State<IkmalGerektirenUrunler> createState() => _IkmalGerektirenUrunlerState();
}

class _IkmalGerektirenUrunlerState extends State<IkmalGerektirenUrunler> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _yukleniyor = true;
  List<Map<String, dynamic>> _urunler = [];

  @override
  void initState() {
    super.initState();
    _urunleriGetir();
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
            'stokMiktari': data['stokMiktari'] ?? 0,
            'minimumStokMiktari': data['minimumStokMiktari'] ?? 0,
            'barkod': data['barkod'] ?? '',
            'fiyat': data['fiyat'] ?? 0.0,
          };
        }).where((urun) => urun['stokMiktari'] <= urun['minimumStokMiktari']).toList();
        
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İkmal Gerektiren Ürünler'),
        backgroundColor: Colors.teal,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _urunler.isEmpty
              ? const Center(child: Text('İkmal gerektiren ürün bulunmamaktadır'))
              : ListView.builder(
                  itemCount: _urunler.length,
                  itemBuilder: (context, index) {
                    final urun = _urunler[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(
                          urun['urunAdi'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Barkod: ${urun['barkod']}\nFiyat: ${urun['fiyat']} TL',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Stok: ${urun['stokMiktari']}',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Min: ${urun['minimumStokMiktari']}',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
} 