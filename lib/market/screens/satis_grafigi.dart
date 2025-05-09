import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SatisGrafigi extends StatefulWidget {
  const SatisGrafigi({super.key});

  @override
  State<SatisGrafigi> createState() => _SatisGrafigiState();
}

class _SatisGrafigiState extends State<SatisGrafigi> {
  DateTime _baslangicTarihi = DateTime.now().subtract(const Duration(days: 7));
  DateTime _bitisTarihi = DateTime.now();
  List<BarChartGroupData> _satisVerileri = [];
  List<DateTime> _siraIleGunler = []; // ✅ Gün sırasını saklamak için liste
  bool _yukleniyor = true;
  final Map<DateTime, List<Map<String, dynamic>>> _gunlukSatisDetaylari = {};
  DateTime? _secilenGun;

  @override
  void initState() {
    super.initState();
    _satisVerileriniGetir();
  }

  Future<void> _satisVerileriniGetir() async {
    setState(() => _yukleniyor = true);
    try {
      final satisRef = FirebaseFirestore.instance.collection('siparisler');
      final querySnapshot = await satisRef
          .where('tarih', isGreaterThanOrEqualTo: Timestamp.fromDate(_baslangicTarihi))
          .where('tarih', isLessThanOrEqualTo: Timestamp.fromDate(_bitisTarihi))
          .get();

      final Map<DateTime, double> gunlukSatislar = {};
      _gunlukSatisDetaylari.clear();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final tarih = (data['tarih'] as Timestamp).toDate();
        final urunler = data['urunler'] as List<dynamic>;

        double gunlukToplam = 0;
        final List<Map<String, dynamic>> gunlukUrunler = [];

        for (var urun in urunler) {
          final fiyat = (urun['fiyat'] as num).toDouble();
          final adet = (urun['adet'] as num).toInt();
          gunlukToplam += fiyat * adet;

          gunlukUrunler.add({
            'urunAdi': urun['urunAdi'] ?? 'İsimsiz Ürün',
            'marka': urun['marka'] ?? '',
            'barkod': urun['barkod'] ?? '',
            'fiyat': fiyat,
            'adet': adet,
            'toplam': fiyat * adet,
          });
        }

        final gun = DateTime(tarih.year, tarih.month, tarih.day);
        gunlukSatislar[gun] = (gunlukSatislar[gun] ?? 0) + gunlukToplam;

        if (_gunlukSatisDetaylari.containsKey(gun)) {
          _gunlukSatisDetaylari[gun]!.addAll(gunlukUrunler);
        } else {
          _gunlukSatisDetaylari[gun] = gunlukUrunler;
        }
      }

      final siralananGunler = gunlukSatislar.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      _siraIleGunler = siralananGunler.map((e) => e.key).toList();

      setState(() {
        _satisVerileri = List.generate(siralananGunler.length, (index) {
          final gun = siralananGunler[index].key;
          final toplam = siralananGunler[index].value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: toplam,
                color: _secilenGun != null && gun == _secilenGun
                    ? Colors.red
                    : Colors.teal,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        });

        _yukleniyor = false;
      });
    } catch (e) {
      setState(() => _yukleniyor = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Veriler yüklenirken hata oluştu: $e')),
      );
    }
  }

  Future<void> _tarihSec() async {
    final DateTimeRange? secilenTarih = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _baslangicTarihi,
        end: _bitisTarihi,
      ),
    );

    if (secilenTarih != null) {
      setState(() {
        _baslangicTarihi = secilenTarih.start;
        _bitisTarihi = secilenTarih.end;
        _secilenGun = null;
      });
      _satisVerileriniGetir();
    }
  }

  void _gunSec(double value) {
    final index = value.toInt();
    if (index >= 0 && index < _siraIleGunler.length) {
      final gun = _siraIleGunler[index];
      setState(() {
        _secilenGun = gun;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Satış Grafiği'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _tarihSec,
            tooltip: 'Tarih Aralığı Seç',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Başlangıç: ${DateFormat('dd/MM/yyyy').format(_baslangicTarihi)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Bitiş: ${DateFormat('dd/MM/yyyy').format(_bitisTarihi)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              flex: 2,
              child: _yukleniyor
                  ? const Center(child: CircularProgressIndicator())
                  : _satisVerileri.isEmpty
                      ? const Center(child: Text('Bu tarih aralığında satış verisi bulunamadı'))
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _satisVerileri.fold<double>(
                              0,
                              (max, item) => item.barRods.first.toY > max
                                  ? item.barRods.first.toY
                                  : max,
                            ) * 1.2,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.teal,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final tarih = _siraIleGunler[group.x.toInt()];
                                  return BarTooltipItem(
                                    '${DateFormat('dd/MM/yyyy').format(tarih)}\n',
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '${rod.toY.toStringAsFixed(2)} TL',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
                                if (event is FlTapDownEvent && response?.spot != null) {
                                  _gunSec(response!.spot!.touchedBarGroupIndex.toDouble());
                                }
                              },
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 && value.toInt() < _siraIleGunler.length) {
                                      final tarih = _siraIleGunler[value.toInt()];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('dd/MM').format(tarih),
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toStringAsFixed(0)} TL',
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            gridData: const FlGridData(show: true),
                            barGroups: _satisVerileri,
                          ),
                        ),
            ),
            if (_secilenGun != null && _gunlukSatisDetaylari.containsKey(_secilenGun))
              Expanded(
                flex: 3,
                child: Card(
                  margin: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          '${DateFormat('dd/MM/yyyy').format(_secilenGun!)} Tarihli Satışlar',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _gunlukSatisDetaylari[_secilenGun]!.length,
                          itemBuilder: (context, index) {
                            final urun = _gunlukSatisDetaylari[_secilenGun]![index];
                            return ListTile(
                              title: Text(
                                urun['urunAdi'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Marka: ${urun['marka']}'),
                                  Text('Barkod: ${urun['barkod']}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${urun['adet']} adet',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${urun['fiyat']} TL',
                                    style: const TextStyle(color: Colors.teal),
                                  ),
                                  Text(
                                    'Toplam: ${urun['toplam']} TL',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
