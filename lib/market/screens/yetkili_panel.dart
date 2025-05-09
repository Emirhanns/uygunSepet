import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'urun_ekleme_sayfasi.dart';
import 'urun_listesi.dart';
import 'kaldirilan_urunler_listesi.dart';
import 'ikmal_gerektiren_urunler.dart';
import 'satis_grafigi.dart';
import 'siparisler_paneli.dart';

class YetkiliPanel extends StatefulWidget {
  final String? barkod;

  const YetkiliPanel({super.key, this.barkod});

  @override
  State<YetkiliPanel> createState() => _YetkiliPanelState();
}

class _YetkiliPanelState extends State<YetkiliPanel> {
  final Logger logger = Logger();
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

  Future<void> _cikisYap() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('yetkili', false);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetkili Paneli'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            onPressed: _cikisYap,
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.admin_panel_settings,
                size: 100,
                color: Colors.teal,
              ),
              const SizedBox(height: 32),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.add_shopping_cart, color: Colors.teal),
                  title: const Text('Yeni Ürün Ekle'),
                  subtitle: const Text('Sisteme yeni ürün eklemek için tıklayın'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UrunEklemeSayfasi(barkod: widget.barkod),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.edit, color: Colors.teal),
                  title: const Text('Ürünleri Düzenle'),
                  subtitle: const Text('Mevcut ürünleri düzenlemek için tıklayın'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UrunListesi(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.teal),
                  title: const Text('Kaldırılan Ürünler'),
                  subtitle: const Text('Kaldırılan ürünleri görüntülemek için tıklayın'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KaldirilanUrunlerListesi(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.teal),
                  title: const Text('İkmal Gerektiren Ürünler'),
                  subtitle: const Text('Stok miktarı azalan ürünleri görüntülemek için tıklayın'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IkmalGerektirenUrunler(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.teal),
                  title: const Text('Satış Grafiği'),
                  subtitle: const Text('Satış istatistiklerini görüntülemek için tıklayın'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SatisGrafigi(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long, color: Colors.teal),
                  title: const Text('Siparişler'),
                  subtitle: const Text('Verilen siparişleri görüntüle ve durumunu güncelle'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SiparislerPaneli(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 