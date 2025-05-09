import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'odeme_sayfasi.dart';
import 'package:lottie/lottie.dart';

class SiparisSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> sepet;

  const SiparisSayfasi({super.key, required this.sepet});

  @override
  SiparisSayfasiStat createState() => SiparisSayfasiStat();
}

class SiparisSayfasiStat extends State<SiparisSayfasi> with SingleTickerProviderStateMixin {
  final Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  String ad = '';
  String soyad = '';
  String adres = '';
  String? teslimatSecimi; // Teslimat seçimi için değişken
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _siparisiKaydet() async {
    if (teslimatSecimi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teslimat seçeneğini seçin!')),
      );
      return;
    }

    // Stok kontrolü
    for (var urun in widget.sepet) {
      final doc = await FirebaseFirestore.instance
          .collection('urunler')
          .doc(urun['barkod'])
          .get();

      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${urun['urunAdi']} ürünü bulunamadı')),
        );
        return;
      }

      final urunData = doc.data() as Map<String, dynamic>;
      final stokAdedi = urunData['stokMiktari'] as int? ?? 0;
      final siparisAdedi = urun['adet'] as int? ?? 1;

      if (stokAdedi < siparisAdedi) {
         if(!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${urun['urunAdi']} için yeterli stok yok! Mevcut stok: $stokAdedi')),
        );
        return;
      }
    }

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // Siparişi kaydet
    final siparisRef = firestore.collection('siparisler').doc();
    final siparisData = {
      'ad': ad,
      'soyad': soyad,
      'adres': teslimatSecimi == 'evime' ? adres : null,
      'urunler': widget.sepet,
      'teslimatSecimi': teslimatSecimi,
      'tarih': FieldValue.serverTimestamp(),
      'durum': 'Sipariş Verildi',
    };
    batch.set(siparisRef, siparisData);

    // Stokları güncelle
    for (var urun in widget.sepet) {
      final urunRef = firestore.collection('urunler').doc(urun['barkod']);
      final doc = await urunRef.get();
      final urunData = doc.data() as Map<String, dynamic>;
      final stokAdedi = urunData['stokMiktari'] as int? ?? 0;
      final siparisAdedi = urun['adet'] as int? ?? 1;

      batch.update(urunRef, {
        'stokMiktari': stokAdedi - siparisAdedi,
      });
    }

    try {
      await batch.commit();
      
      if (!mounted) return;

      logger.d('Sipariş Firestore\'a kaydedildi: $siparisData');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş başarıyla verildi!')),
      );

      // Ödeme sayfasına yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OdemeSayfasi(
            sepet: widget.sepet,
            teslimatSecimi: teslimatSecimi,
          ),
        ),
      );
    } catch (e) {
      logger.e('Sipariş kaydedilirken hata: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş kaydedilirken bir hata oluştu')),
      );
    }
  }

  double _toplamFiyat() {
    double toplam = 0.0;
    for (var urun in widget.sepet) {
      toplam += (urun['fiyat'] is String ? double.tryParse(urun['fiyat']) ?? 0.0 : (urun['fiyat'] as num).toDouble()) * (urun['adet'] as int);
    }
    return toplam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _controller,
          child: const Text('Sipariş Ver'),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FadeTransition(
          opacity: _controller,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Ad'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen adınızı girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    ad = value;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Soyad'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen soyadınızı girin';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    soyad = value;
                  },
                ),
                // Teslimat Seçenekleri
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Evime Gönder'),
                        leading: Radio<String>(
                          value: 'evime',
                          groupValue: teslimatSecimi,
                          onChanged: (value) {
                            setState(() {
                              teslimatSecimi = value;
                            });
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('Gelip Al'),
                        leading: Radio<String>(
                          value: 'gelip_al',
                          groupValue: teslimatSecimi,
                          onChanged: (value) {
                            setState(() {
                              teslimatSecimi = value;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                // Adres alanı, sadece evime gönder seçeneği aktifken gösterilecek
                if (teslimatSecimi == 'evime') ...[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Adres'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Lütfen adresinizi girin';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      adres = value;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: const Text('Sepetteki Ürünler:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.sepet.length,
                    itemBuilder: (context, index) {
                      final urun = widget.sepet[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        child: ListTile(
                          title: Text(urun['urunAdi']),
                          subtitle: Text('Fiyat: ${urun['fiyat']} TL, Adet: ${urun['adet']}'),
                        ),
                      );
                    },
                  ),
                ),
                Text('Toplam Fiyat: ${_toplamFiyat()} TL', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _siparisiKaydet();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: const Text('Siparişi Ver'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}