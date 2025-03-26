import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'siparis_sayfasi.dart';
import 'sepet_sayfasi.dart';
import 'yetkili_giris.dart';
import 'musteri_urun_listesi.dart';

class BarkodOkuyucu extends StatefulWidget {
  const BarkodOkuyucu({super.key});

  @override
  State<BarkodOkuyucu> createState() => _BarkodOkuyucuState();
}

class _BarkodOkuyucuState extends State<BarkodOkuyucu> {
  final Logger logger = Logger();
  String _barkodSonuc = '';
  List<Map<String, dynamic>> sepet = [];
  String? _sonOkunanBarkod;
  String genelDuyuru = "Genel Duyuru: Bugün %10 indirim fırsatını kaçırmayın!"; // Genel duyuru metni
  bool _dialogAcikMi = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? hasLaunched = prefs.getBool('hasLaunched');
    if (hasLaunched == null || !hasLaunched) {
      _showResetWarningDialog();
      await prefs.setBool('hasLaunched', true);
    }
  }

  void _showResetWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uyarı'),
        content: const Text('Aynı ürünü tekrar okutmak için son okunan barkodu sıfırlayabilirsiniz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Future<void> _urunBul(String barkod) async {
    logger.d('Barkod arama: $barkod');
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore.collection('urunler').doc(barkod).get();

    if (doc.exists) {
      final data = doc.data()!;
      logger.d('Ürün bulundu: $data');
      setState(() {
        _dialogAcikMi = true;
      });
      _scannerController?.stop();
      await _showUrunDialog(data);
      setState(() {
        _dialogAcikMi = false;
      });
      _scannerController?.start();
    } else {
      logger.d('Ürün bulunamadı');
      _showNotFoundDialog();
    }
  }

  void _showNotFoundDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ürün Bulunamadı'),
        content: const Text('Böyle bir ürün bulunmamaktadır.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _showUrunDialog(Map<String, dynamic> urun) async {
    await showDialog(
      context: context,
      builder: (context) {
        final ad = urun['ürün-adi'] ?? 'Bilinmiyor';
        final marka = urun['marka'] ?? 'Bilinmiyor';
        final gramaj = urun['gramaj'] ?? 'Bilinmiyor';
        final fiyat = urun['fiyat']?.toString() ?? 'Bilinmiyor';
        final indirimliFiyat = urun['indirimliFiyat']?.toString() ?? 'Bilinmiyor';
        final kampanya = urun['kampanya'] ?? 'Bilinmiyor';

        return AlertDialog(
          title: Text(ad, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Marka: $marka'),
              Text('Gramaj: $gramaj'),
              Text('Fiyat: $fiyat TL', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (indirimliFiyat != '0') ...[
                Text('İndirimli Fiyat: $indirimliFiyat TL', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
              ],
              if (kampanya != 'Bilinmiyor') ...[
                Text('Kampanya: $kampanya'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sepeteEkle(urun);
                _siparisSayfasinaGit(urun);
              },
              child: const Text('Satın Al'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sepeteEkle(urun);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${urun['ürün-adi']} sepete eklendi!')),
                );
              },
              child: const Text('Sepete Ekle'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  void _siparisSayfasinaGit(Map<String, dynamic> urun) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiparisSayfasi(sepet: sepet),
      ),
    );
  }

  void _sepeteEkle(Map<String, dynamic> urun) {
    final existingProductIndex = sepet.indexWhere((item) => item['barkod'] == urun['barkod']);
    if (existingProductIndex >= 0) {
      sepet[existingProductIndex]['adet'] += 1;
    } else {
      sepet.add({...urun, 'adet': 1});
    }
    logger.d('Sepete eklendi: ${urun['ürün-adi']}');
  }

  void _sifirlaBarkod() {
    setState(() {
      _barkodSonuc = '';
      _sonOkunanBarkod = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Okuyucu'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MusteriUrunListesi(sepet: sepet),
                ),
              );
            },
            icon: const Icon(Icons.store),
            tooltip: 'Ürünleri Görüntüle',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YetkiliGiris(barkod: _barkodSonuc.isEmpty ? null : _barkodSonuc),
                ),
              );
            },
            icon: const Icon(Icons.admin_panel_settings),
            tooltip: 'Yetkili İşlemleri',
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SepetSayfasi(sepet: sepet),
                ),
              );
            },
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              genelDuyuru,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.teal, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.hardEdge,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_dialogAcikMi) return;
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  final barkod = barcode.rawValue;
                  if (barkod != null) {
                    if (barkod != _sonOkunanBarkod) {
                      logger.d('Barkod okundu: $barkod');
                      setState(() {
                        _barkodSonuc = barkod;
                        _sonOkunanBarkod = barkod;
                      });
                      _urunBul(barkod);
                    }
                  } else {
                    logger.d('Barkod okunamadı');
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Son Okunan: $_barkodSonuc',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _sifirlaBarkod,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Sıfırla'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }
} 
