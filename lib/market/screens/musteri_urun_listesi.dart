import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'siparis_sayfasi.dart';

class MusteriUrunListesi extends StatefulWidget {
  final List<Map<String, dynamic>> sepet;

  const MusteriUrunListesi({super.key, required this.sepet});

  @override
  State<MusteriUrunListesi> createState() => _MusteriUrunListesiState();
}

class _MusteriUrunListesiState extends State<MusteriUrunListesi> {
  final Logger logger = Logger();
  final TextEditingController _aramaController = TextEditingController();
  String _aramaMetni = '';
  String? _secilenKategori;

  void _sepeteEkle(Map<String, dynamic> urun) {
    final existingProductIndex = widget.sepet.indexWhere((item) => item['barkod'] == urun['barkod']);
    if (existingProductIndex >= 0) {
      setState(() {
        widget.sepet[existingProductIndex]['adet'] += 1;
      });
    } else {
      setState(() {
        widget.sepet.add({...urun, 'adet': 1});
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${urun['ürün-adi']} sepete eklendi!')),
    );
  }

  void _siparisVer() {
    if (widget.sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sepetiniz boş!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiparisSayfasi(sepet: widget.sepet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünlerimiz'),
        backgroundColor: Colors.teal,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: _siparisVer,
              ),
              if (widget.sepet.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      widget.sepet.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('urunler')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Bir hata oluştu'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Benzersiz markaları topla
              final markalar = snapshot.data!.docs
                  .map((doc) => (doc.data() as Map<String, dynamic>)['marka'] as String?)
                  .where((marka) => marka != null)
                  .toSet()
                  .toList();

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: const Text('Tümü'),
                        selected: _secilenKategori == null,
                        onSelected: (selected) {
                          setState(() {
                            _secilenKategori = null;
                          });
                        },
                      ),
                    ),
                    ...markalar.map((marka) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(marka!),
                        selected: _secilenKategori == marka,
                        onSelected: (selected) {
                          setState(() {
                            _secilenKategori = selected ? marka : null;
                          });
                        },
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('urunler')
                  .snapshots(),
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
                  final kategoriKontrol = _secilenKategori == null || data['marka'] == _secilenKategori;

                  return kategoriKontrol && (urunAdi.contains(aramaMetni) ||
                      marka.contains(aramaMetni) ||
                      barkod.contains(aramaMetni));
                }).toList();

                if (urunler.isEmpty) {
                  return const Center(
                    child: Text(
                      'Ürün bulunamadı',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: urunler.length,
                  itemBuilder: (context, index) {
                    final urun = urunler[index].data() as Map<String, dynamic>;
                    final indirimliFiyat = urun['indirimliFiyat']?.toString();
                    final kampanya = urun['kampanya'];

                    return Card(
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.shopping_bag,
                                  size: 50,
                                  color: Colors.teal,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  urun['ürün-adi'] ?? 'İsimsiz Ürün',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  urun['marka'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (indirimliFiyat != null && indirimliFiyat != '0') ...[
                                  Text(
                                    '${urun['fiyat']} TL',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '$indirimliFiyat TL',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ] else
                                  Text(
                                    '${urun['fiyat']} TL',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                if (kampanya != null && kampanya.toString().isNotEmpty)
                                  Text(
                                    kampanya.toString(),
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _sepeteEkle(urun),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal,
                                ),
                                child: const Text('Sepete Ekle'),
                              ),
                            ),
                          ),
                        ],
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