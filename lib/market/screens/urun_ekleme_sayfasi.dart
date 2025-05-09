import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class UrunEklemeSayfasi extends StatefulWidget {
  final String? barkod;

  const UrunEklemeSayfasi({super.key, this.barkod});

  @override
  State<UrunEklemeSayfasi> createState() => _UrunEklemeSayfasiState();
}

class _UrunEklemeSayfasiState extends State<UrunEklemeSayfasi> {
  final Logger logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _barkodController = TextEditingController();
  final TextEditingController _urunAdiController = TextEditingController();
  final TextEditingController _markaController = TextEditingController();
  final TextEditingController _gramajController = TextEditingController();
  final TextEditingController _fiyatController = TextEditingController();
  final TextEditingController _indirimliFiyatController = TextEditingController();
  final TextEditingController _kampanyaController = TextEditingController();
  final TextEditingController _stokAdediController = TextEditingController();
  final TextEditingController _minimumStokController = TextEditingController();
  final TextEditingController _kategoriController = TextEditingController();
  bool _yukleniyor = false;

  @override
  void initState() {
    super.initState();
    if (widget.barkod != null) {
      _barkodController.text = widget.barkod!;
      _urunBilgileriniGetir();
    }
  }

  Future<void> _urunBilgileriniGetir() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('urunler')
          .doc(_barkodController.text)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _urunAdiController.text = data['urunAdi'] ?? '';
          _markaController.text = data['marka'] ?? '';
          _gramajController.text = data['gramaj'] ?? '';
          _fiyatController.text = data['fiyat']?.toString() ?? '';
          _indirimliFiyatController.text = data['indirimliFiyat']?.toString() ?? '';
          _kampanyaController.text = data['kampanya'] ?? '';
          _stokAdediController.text = data['stokMiktari']?.toString() ?? '0';
          _minimumStokController.text = data['minimumStokMiktari']?.toString() ?? '0';
          _kategoriController.text = data['kategori'] ?? '';
        });
      }
    } catch (e) {
      logger.e('Ürün bilgileri getirilirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ürün bilgileri getirilirken bir hata oluştu')),
        );
      }
    }
  }

  Future<void> _urunKaydet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _yukleniyor = true);

    try {
      final urunData = {
        'barkod': _barkodController.text,
        'urunAdi': _urunAdiController.text,
        'marka': _markaController.text,
        'gramaj': _gramajController.text,
        'fiyat': double.parse(_fiyatController.text),
        'indirimliFiyat': _indirimliFiyatController.text.isNotEmpty
            ? double.parse(_indirimliFiyatController.text)
            : 0,
        'kampanya': _kampanyaController.text,
        'status': 1,
        'stokMiktari': int.parse(_stokAdediController.text),
        'minimumStokMiktari': int.parse(_minimumStokController.text),
        'kategori': _kategoriController.text,
        'eklenmeTarihi': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('urunler')
          .doc(_barkodController.text)
          .set(urunData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün başarıyla kaydedildi')),
      );

      Navigator.pop(context);
    } catch (e) {
      logger.e('Ürün kaydedilirken hata: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ürün kaydedilirken bir hata oluştu')),
      );
    } finally {
      setState(() => _yukleniyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.barkod != null ? 'Ürün Düzenle' : 'Yeni Ürün Ekle'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _barkodController,
                decoration: const InputDecoration(
                  labelText: 'Barkod',
                  border: OutlineInputBorder(),
                ),
                enabled: widget.barkod == null,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen barkod girin';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.length >= 13) {
                    _urunBilgileriniGetir();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _urunAdiController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen ürün adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _markaController,
                decoration: const InputDecoration(
                  labelText: 'Marka',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen marka girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kategoriController,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen kategori girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gramajController,
                decoration: const InputDecoration(
                  labelText: 'Gramaj',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen gramaj girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fiyatController,
                decoration: const InputDecoration(
                  labelText: 'Fiyat',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen fiyat girin';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Geçerli bir fiyat girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _indirimliFiyatController,
                decoration: const InputDecoration(
                  labelText: 'İndirimli Fiyat (Opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (double.tryParse(value) == null) {
                      return 'Geçerli bir fiyat girin';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kampanyaController,
                decoration: const InputDecoration(
                  labelText: 'Kampanya (Opsiyonel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stokAdediController,
                decoration: const InputDecoration(
                  labelText: 'Stok Adedi',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen stok adedi girin';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minimumStokController,
                decoration: const InputDecoration(
                  labelText: 'Minimum Stok Miktarı',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen minimum stok miktarı girin';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _yukleniyor ? null : _urunKaydet,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: _yukleniyor
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.barkod != null ? 'Güncelle' : 'Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barkodController.dispose();
    _urunAdiController.dispose();
    _markaController.dispose();
    _gramajController.dispose();
    _fiyatController.dispose();
    _indirimliFiyatController.dispose();
    _kampanyaController.dispose();
    _stokAdediController.dispose();
    _minimumStokController.dispose();
    _kategoriController.dispose();
    super.dispose();
  }
} 