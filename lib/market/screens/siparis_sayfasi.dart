import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'odeme_sayfasi.dart';

class SiparisSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> sepet;

  const SiparisSayfasi({super.key, required this.sepet});

  @override
  SiparisSayfasiStat createState() => SiparisSayfasiStat();
}

class SiparisSayfasiStat extends State<SiparisSayfasi> {
  final Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  String ad = '';
  String soyad = '';
  String adres = '';
  String? teslimatSecimi; // Teslimat seçimi için değişken

  Future<void> _siparisiKaydet() async {
    if (teslimatSecimi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teslimat seçeneğini seçin!')),
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;
    final siparisData = {
      'ad': ad,
      'soyad': soyad,
      'adres': teslimatSecimi == 'evime' ? adres : null,
      'urunler': widget.sepet,
      'teslimatSecimi': teslimatSecimi,
      'tarih': FieldValue.serverTimestamp(),
    };

    await firestore.collection('siparisler').add(siparisData);
    
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
        title: const Text('Sipariş Ver'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      title: const Text('Evime Gönderilsin'),
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
                      title: const Text('Gelip Alacağım'),
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
              const Text('Sepetteki Ürünler:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      ),
                    );
                  },
                ),
              ),
              Text('Toplam Fiyat: ${_toplamFiyat()} TL', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _siparisiKaydet(); // Firestore'a kaydet
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                ),
                child: const Text('Siparişi Ver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}