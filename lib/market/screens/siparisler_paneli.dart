import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';

class SiparislerPaneli extends StatefulWidget {
  const SiparislerPaneli({super.key});

  @override
  State<SiparislerPaneli> createState() => _SiparislerPaneliState();
}

class _SiparislerPaneliState extends State<SiparislerPaneli> with SingleTickerProviderStateMixin {
  final List<String> durumlar = [
    'Sipariş Verildi',
    'Sipariş Hazırlanıyor',
    'Sipariş Teslim Edildi'
  ];

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

  Future<void> durumGuncelle(String docId, String yeniDurum) async {
    await FirebaseFirestore.instance
        .collection('siparisler')
        .doc(docId)
        .update({'durum': yeniDurum});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FadeTransition(
          opacity: _controller,
          child: const Text('Siparişler'),
        ),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('siparisler').orderBy('tarih', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(              );
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text('${data['ad']} ${data['soyad']}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Adres: ${data['adres'] ?? "-"}'),
                        Text('Durum: ${data['durum'] ?? "Bilinmiyor"}'),
                        Text('Tarih: ${data['tarih'] != null ? (data['tarih'] as Timestamp).toDate().toString() : "-"}'),
                        Text('Ürünler:'),
                        ...((data['urunler'] as List<dynamic>?) ?? []).map((u) => Text('- ${u['urunAdi']} x${u['adet']}')),
                        const SizedBox(height: 8),
                        DropdownButton<String>(
                          value: data['durum'] ?? durumlar[0],
                          items: durumlar.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (yeniDurum) {
                            if (yeniDurum != null) {
                              durumGuncelle(docId, yeniDurum);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 