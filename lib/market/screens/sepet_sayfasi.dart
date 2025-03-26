import 'package:flutter/material.dart';
import 'siparis_sayfasi.dart';

class SepetSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> sepet;

  const SepetSayfasi({super.key, required this.sepet});

  @override
  Sepetsayfasistate createState() => Sepetsayfasistate();
}

class Sepetsayfasistate extends State<SepetSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepet'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Sepetteki Ürünler:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.sepet.length,
                itemBuilder: (context, index) {
                  final urun = widget.sepet[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      title: Text(urun['ürün-adi']),
                      subtitle: Text('Fiyat: ${urun['fiyat']} TL, Adet: ${urun['adet']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              setState(() {
                                if (urun['adet'] > 1) {
                                  urun['adet'] -= 1; // Adedi azalt
                                } else {
                                  widget.sepet.removeAt(index); // Ürünü listeden çıkar
                                }
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                urun['adet'] += 1; // Adedi artır
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                widget.sepet.removeAt(index); // Ürünü listeden çıkar
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Sepeti temizle
                setState(() {
                  widget.sepet.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Buton rengi
              ),
              child: const Text('Sepeti Temizle'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Sipariş sayfasına yönlendir
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SiparisSayfasi(sepet: widget.sepet), // Kullanıcıdan bilgileri al
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Buton rengi
              ),
              child: const Text('Siparişi Ver'),
            ),
          ],
        ),
      ),
    );
  }
}