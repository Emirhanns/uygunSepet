import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:market/market/screens/barkod_okuyucu.dart';
import 'dart:math';

class OdemeSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> sepet;
  final String? teslimatSecimi;

  const OdemeSayfasi({
    super.key,
    required this.sepet,
    this.teslimatSecimi,
  });

  @override
  State<OdemeSayfasi> createState() => _OdemeSayfasiState();
}

class _OdemeSayfasiState extends State<OdemeSayfasi> {
  final Logger logger = Logger();
  String? secilenOdemeYontemi;
  bool isLoading = false;
  final String iban = "TR00 0000 0000 0000 0000 0000 00"; // Sabit IBAN
  final TextEditingController kartNumarasiController = TextEditingController();
  final TextEditingController sonKullanmaController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  String generateSiparisNumarasi() {
    return "SIP-${Random().nextInt(900000) + 100000}"; // 6 haneli sipariş numarası
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ödeme Yöntemi Seçin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Card(
              child: RadioListTile<String>(
                title: const Text('Kredi/Banka Kartı'),
                value: 'kart',
                groupValue: secilenOdemeYontemi,
                onChanged: (value) {
                  setState(() {
                    secilenOdemeYontemi = value;
                  });
                },
              ),
            ),
            if (secilenOdemeYontemi == 'kart') ...[
              TextField(
                controller: kartNumarasiController,
                decoration: const InputDecoration(labelText: 'Kart Numarası'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sonKullanmaController,
                decoration: const InputDecoration(labelText: 'Son Kullanma Tarihi (MM/YY)'),
                keyboardType: TextInputType.datetime,
              ),
              TextField(
                controller: cvvController,
                decoration: const InputDecoration(labelText: 'CVV'),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
            ],
            Card(
              child: RadioListTile<String>(
                title: const Text('IBAN ile Ödeme'),
                value: 'iban',
                groupValue: secilenOdemeYontemi,
                onChanged: (value) {
                  setState(() {
                    secilenOdemeYontemi = value;
                  });
                },
              ),
            ),
            if (secilenOdemeYontemi == 'iban') ...[
              const SizedBox(height: 10),
              Text('IBAN: $iban', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('Sipariş Numarası: ${generateSiparisNumarasi()}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
            if (widget.teslimatSecimi != 'gelip_al') ...[
              Card(
                child: RadioListTile<String>(
                  title: const Text('Kapıda Ödeme'),
                  value: 'kapida',
                  groupValue: secilenOdemeYontemi,
                  onChanged: (value) {
                    setState(() {
                      secilenOdemeYontemi = value;
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: secilenOdemeYontemi == null
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          await Future.delayed(const Duration(seconds: 2));
                          if (!mounted) return;
                          
                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const BarkodOkuyucu(),
                            ),
                            (route) => false,
                          );
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Ödeme başarıyla tamamlandı!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          logger.e('Ödeme işlemi sırasında hata: $e');
                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Ödeme işlemi sırasında bir hata oluştu!'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Ödemeyi Tamamla',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
