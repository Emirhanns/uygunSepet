import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class KaldirilanUrunlerListesi extends StatefulWidget {
  const KaldirilanUrunlerListesi({super.key});

  @override
  State<KaldirilanUrunlerListesi> createState() => _KaldirilanUrunlerListesiState();
}

class _KaldirilanUrunlerListesiState extends State<KaldirilanUrunlerListesi> {
  final Logger logger = Logger();

  Future<void> _urunuGeriEkle(String barkod) async {
    try {
      await FirebaseFirestore.instance
          .collection('urunler')
          .doc(barkod)
          .update({'status': 1});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün başarıyla geri eklendi')),
      );
    } catch (e) {
      logger.e('Ürün geri eklenirken hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün geri eklenirken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kaldırılan Ürünler'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('urunler')
            .where('status', isEqualTo: 0)
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

          var urunler = snapshot.data!.docs;

          if (urunler.isEmpty) {
            return const Center(
              child: Text(
                'Kaldırılan ürün bulunmamaktadır',
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
                    urun['urunAdi'] ?? 'İsimsiz Ürün',
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
                  trailing: ElevatedButton(
                    onPressed: () => _urunuGeriEkle(urun['barkod']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Geri Ekle'),
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
} 