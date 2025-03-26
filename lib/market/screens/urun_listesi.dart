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
  String _aramaMetni = '';
  bool _yetkiliMi = false;

  @override
  void initState() {
    super.initState();
    _yetkiliKontrol();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün Listesi'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _aramaController,
              decoration: InputDecoration(
                labelText: 'Ürün Ara',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _aramaMetni.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _aramaController.clear();
                            _aramaMetni = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _aramaMetni = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('urunler').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Bir hata oluştu: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var urunler = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final urunAdi = data['ürün-adi']?.toString().toLowerCase() ?? '';
                  final marka = data['marka']?.toString().toLowerCase() ?? '';
                  final barkod = data['barkod']?.toString().toLowerCase() ?? '';
                  final aramaMetni = _aramaMetni.toLowerCase();

                  return urunAdi.contains(aramaMetni) ||
                      marka.contains(aramaMetni) ||
                      barkod.contains(aramaMetni);
                }).toList();

                if (urunler.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ürün bulunamadı',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: urunler.length,
                  itemBuilder: (context, index) {
                    final urun = urunler[index].data() as Map<String, dynamic>;
                    final indirimliFiyat = urun['indirimliFiyat']?.toString();
                    final kampanya = urun['kampanya'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        title: Text(
                          urun['ürün-adi'] ?? 'İsimsiz Ürün',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Marka: ${urun['marka'] ?? 'Belirtilmemiş'}'),
                            Text('Barkod: ${urun['barkod'] ?? 'Belirtilmemiş'}'),
                            Text('Gramaj: ${urun['gramaj'] ?? 'Belirtilmemiş'}'),
                            Text(
                              'Fiyat: ${urun['fiyat']?.toString() ?? '0'} TL',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (indirimliFiyat != null && indirimliFiyat != '0')
                              Text(
                                'İndirimli Fiyat: $indirimliFiyat TL',
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (kampanya != null && kampanya.toString().isNotEmpty)
                              Text(
                                'Kampanya: $kampanya',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                                );
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
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          final navigator = Navigator.of(context);
                                          final messenger = ScaffoldMessenger.of(context);
                                          try {
                                            await FirebaseFirestore.instance
                                                .collection('urunler')
                                                .doc(urun['barkod'])
                                                .delete();
                                            if (!mounted) return;
                                            navigator.pop();
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text('Ürün başarıyla silindi'),
                                              ),
                                            );
                                          } catch (e) {
                                            logger.e(
                                                'Ürün silinirken hata: $e');
                                            if (!mounted) return;
                                            navigator.pop();
                                            messenger.showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Ürün silinirken bir hata oluştu'),
                                              ),
                                            );
                                          }
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
                        isThreeLine: true,
                      ),
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

  @override
  void dispose() {
    _aramaController.dispose();
    super.dispose();
  }
} 