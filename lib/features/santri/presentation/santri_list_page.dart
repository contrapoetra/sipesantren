// features/santri/presentation/santri_list_page.dart
import 'package:fl_chart/fl_chart.dart'; // New import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';
import 'package:sipesantren/features/penilaian/presentation/input_penilaian_page.dart';
import 'package:sipesantren/features/rapor/presentation/rapor_page.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sipesantren/features/auth/presentation/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart'; // New import
import 'package:sipesantren/core/models/penilaian_model.dart'; // New import
import 'dart:math';
import 'package:sipesantren/core/providers/user_provider.dart'; // New import
import 'package:sipesantren/features/master_data/presentation/mapel_list_page.dart'; // New import
import 'package:sipesantren/features/santri/presentation/santri_form_page.dart'; // New import
import 'package:sipesantren/features/master_data/presentation/weight_config_page.dart'; // New import

class SantriListPage extends ConsumerStatefulWidget {
  const SantriListPage({super.key});

  @override
  ConsumerState<SantriListPage> createState() => _SantriListPageState();
}

class _SantriListPageState extends ConsumerState<SantriListPage> {
  // Removed direct instantiation, now obtained from provider
  String _selectedKamar = 'Semua';
  String _selectedAngkatan = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final _repository = ref.read(santriRepositoryProvider); // Get from provider
    final _firestore = ref.watch(firestoreProvider); // Get from provider
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Santri'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('santri').snapshots(),
            builder: (context, snapshot) {
              bool hasPendingWrites = snapshot.hasData && snapshot.data!.metadata.hasPendingWrites;
              return IconButton(
                icon: Icon(
                  hasPendingWrites ? Icons.cloud_upload : Icons.cloud_done,
                  color: hasPendingWrites ? Colors.orangeAccent : Colors.white,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(hasPendingWrites
                          ? 'Perubahan lokal menunggu sinkronisasi.'
                          : 'Semua perubahan tersinkronisasi.'),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              _showSyncDialog();
            },
          ),

          if (ref.watch(userProvider).userRole == 'Admin') // Only for Admin
            IconButton(
              icon: const Icon(Icons.category),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapelListPage()),
                );
              },
            ),
          if (ref.watch(userProvider).userRole == 'Admin') // Only for Admin
            IconButton(
              icon: const Icon(Icons.precision_manufacturing), // Icon for weights/settings
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WeightConfigPage()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final firebaseServices = ref.read(firebaseServicesProvider);
              await firebaseServices.logout();
              if (context.mounted) {
                ref.read(userProvider.notifier).logout(); // Update userProvider
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            margin: const EdgeInsets.all(16), // Added margin
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor, // Use card color
              borderRadius: BorderRadius.circular(15), // Rounded corners
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari santri...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Rounded corners for input
                      borderSide: BorderSide.none, // Remove border
                    ),
                    filled: true,
                    fillColor: Colors.grey[100], // Light background for the text field
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], // Light background for dropdown
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent), // Remove border
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedKamar,
                            items: const [
                              DropdownMenuItem(value: 'Semua', child: Text('Semua Kamar')),
                              DropdownMenuItem(value: 'A3', child: Text('Kamar A3')),
                              DropdownMenuItem(value: 'B1', child: Text('Kamar B1')),
                              DropdownMenuItem(value: 'C2', child: Text('Kamar C2')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedKamar = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100], // Light background for dropdown
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent), // Remove border
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedAngkatan,
                            items: const [
                              DropdownMenuItem(value: 'Semua', child: Text('Semua Angkatan')),
                              DropdownMenuItem(value: '2023', child: Text('2023')),
                              DropdownMenuItem(value: '2022', child: Text('2022')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedAngkatan = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Santri List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('santri').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allSantriDocs = snapshot.data!.docs;
                final filteredSantri = allSantriDocs.where((doc) {
                  final santri = SantriModel.fromFirestore(doc); // Create SantriModel for filtering
                  final matchesSearch = santri.nama.toLowerCase().contains(_searchQuery) || 
                                      santri.nis.contains(_searchQuery);
                  final matchesKamar = _selectedKamar == 'Semua' || (santri.kamarGedung + '-' + santri.kamarNomor.toString()) == _selectedKamar;
                  final matchesAngkatan = _selectedAngkatan == 'Semua' || santri.angkatan.toString() == _selectedAngkatan;
                  return matchesSearch && matchesKamar && matchesAngkatan;
                }).toList();

                if (filteredSantri.isEmpty) {
                  return const Center(child: Text('Data tidak ditemukan'));
                }

                return ListView.builder(
                  itemCount: filteredSantri.length,
                  itemBuilder: (context, index) {
                    final doc = filteredSantri[index];
                    final santri = SantriModel.fromFirestore(doc);
                    final bool hasPendingWrites = doc.metadata.hasPendingWrites;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      elevation: 2, // Add a subtle shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Consistent rounded corners
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Theme-based background
                            borderRadius: BorderRadius.circular(10), // Slightly less rounded than outer card
                          ),
                          child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary), // Theme-based icon color
                        ),
                        title: Text(santri.nama),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NIS: ${santri.nis} | Kamar: ${santri.kamarGedung}-${santri.kamarNomor}'),
                            if (hasPendingWrites)
                              const Row(
                                children: [
                                  Icon(Icons.cloud_upload, size: 16, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text('Menunggu sinkronisasi', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                      trailing: (ref.watch(userProvider).userRole != 'Wali Santri')
                          ? PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SantriFormPage(santri: santri),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Konfirmasi Hapus"),
                                      content: Text("Anda yakin ingin menghapus ${santri.nama}?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text("BATAL"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text("HAPUS"),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _repository.deleteSantri(santri.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${santri.nama} berhasil dihapus')),
                                      );
                                    }
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete),
                                      SizedBox(width: 8),
                                      Text('Hapus'),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SantriDetailPage(santri: santri),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (ref.watch(userProvider).userRole != 'Wali Santri')
          ? FloatingActionButton(
              onPressed: _showAddSantriDialog,
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  void _showSyncDialog() {
    // Firestore syncs automatically. This could be a "Force Sync" or status check.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sinkronisasi Data'),
        content: const Text('Data disinkronkan secara otomatis saat online.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddSantriDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SantriFormPage()),
    );
  }
}

class SantriDetailPage extends ConsumerStatefulWidget {
  final SantriModel santri;

  const SantriDetailPage({super.key, required this.santri});

  @override
  ConsumerState<SantriDetailPage> createState() => _SantriDetailPageState();
}

class _SantriDetailPageState extends ConsumerState<SantriDetailPage> {
  // Removed direct instantiation, now obtained from provider
  List<PenilaianTahfidz> _tahfidzData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTahfidzData();
  }

  Future<void> _loadTahfidzData() async {
    final _penilaianRepository = ref.read(penilaianRepositoryProvider); // Get from provider
    _penilaianRepository.getTahfidzBySantri(widget.santri.id).listen((data) {
      setState(() {
        _tahfidzData = data;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.santri.nama),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Penilaian'),
              Tab(text: 'Kehadiran'),
              Tab(text: 'Grafik'),
              Tab(text: 'Rapor'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Penilaian
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // TODO: Fetch real grades
                  _buildNilaiCard('Tahfidz', '93', Colors.green, Icons.book),
                  _buildNilaiCard('Fiqh', '86', Colors.blue, Icons.balance),
                  _buildNilaiCard('Bahasa Arab', '78', Colors.orange, Icons.language),
                  _buildNilaiCard('Akhlak', '94', Colors.purple, Icons.emoji_people),
                  _buildNilaiCard('Kehadiran', '90', Colors.red, Icons.calendar_today),
                  const SizedBox(height: 16),
                  if (ref.watch(userProvider).userRole != 'Wali Santri')
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InputPenilaianPage(santri: widget.santri),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Input Penilaian Baru'),
                    ),
                ],
              ),
            ),

            // Tab Kehadiran
            const Center(child: Text('Data Kehadiran akan ditampilkan di sini')),

            // Tab Grafik
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildTahfidzChart(),

            // Tab Rapor
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'RAPOR SANTRI',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildRaporItem('Nilai Akhir', '89'),
                          _buildRaporItem('Predikat', 'A'),
                          _buildRaporItem('Peringkat', '5 dari 40'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RaporPage(santri: widget.santri),
                                ),
                              );
                            },
                            child: const Text('Lihat Rapor Lengkap'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTahfidzChart() {
    if (_tahfidzData.isEmpty) {
      return const Center(child: Text('Tidak ada data Tahfidz untuk ditampilkan.'));
    }

    _tahfidzData.sort((a, b) => a.minggu.compareTo(b.minggu)); // Sort by date

    // Prepare data for the chart
    List<FlSpot> spots = _tahfidzData.asMap().entries.map((entry) {
      // Use index as x-axis for chronological order
      return FlSpot(entry.key.toDouble(), entry.value.nilaiAkhir);
    }).toList();

    // Determine min/max Y values for appropriate scaling
    double minY = spots.map((spot) => spot.y).reduce(min);
    double maxY = spots.map((spot) => spot.y).reduce(max);
    if (maxY < 100) maxY = 100; // Ensure Y-axis goes up to at least 100

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grafik Perkembangan Tahfidz',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.70,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 20,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xff37434d),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return const FlLine(
                      color: Color(0xff37434d),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _tahfidzData.length) {
                          final date = _tahfidzData[value.toInt()].minggu;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text('${date.day}/${date.month}', style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                      interval: 1,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10));
                      },
                      interval: 20,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: const Color(0xff37434d), width: 1),
                ),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY > 0 ? (minY - 10).floorToDouble() : 0, // Extend a bit below min
                maxY: maxY + 10, // Extend a bit above max
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blueAccent.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiCard(String mataPelajaran, String nilai, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(mataPelajaran),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            nilai,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRaporItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}