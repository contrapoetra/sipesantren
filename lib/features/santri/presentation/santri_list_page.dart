// features/santri/presentation/santri_list_page.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';
import 'package:sipesantren/features/penilaian/presentation/input_penilaian_page.dart';
import 'package:sipesantren/features/rapor/presentation/rapor_page.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sipesantren/features/auth/presentation/login_page.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart';
import 'package:sipesantren/core/models/penilaian_model.dart';
import 'dart:math';
import 'package:sipesantren/core/providers/user_provider.dart';
import 'package:sipesantren/features/master_data/presentation/mapel_list_page.dart';
import 'package:sipesantren/features/santri/presentation/santri_form_page.dart';
import 'package:sipesantren/features/master_data/presentation/weight_config_page.dart';

class SantriListPage extends ConsumerStatefulWidget {
  const SantriListPage({super.key});

  @override
  ConsumerState<SantriListPage> createState() => _SantriListPageState();
}

class _SantriListPageState extends ConsumerState<SantriListPage> {
  String _selectedKamar = 'Semua';
  String _selectedAngkatan = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SantriModel> _allSantri = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(santriRepositoryProvider);
      final list = await repository.getSantriList();
      if (mounted) {
        setState(() {
          _allSantri = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _repository = ref.read(santriRepositoryProvider);
    
    // Filtering logic
    final filteredSantri = _allSantri.where((santri) {
      final matchesSearch = santri.nama.toLowerCase().contains(_searchQuery) || 
                          santri.nis.contains(_searchQuery);
      final matchesKamar = _selectedKamar == 'Semua' || (santri.kamarGedung + '-' + santri.kamarNomor.toString()) == _selectedKamar;
      final matchesAngkatan = _selectedAngkatan == 'Semua' || santri.angkatan.toString() == _selectedAngkatan;
      return matchesSearch && matchesKamar && matchesAngkatan;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Santri'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Manual',
            onPressed: () {
              _showSyncDialog();
            },
          ),
          if (ref.watch(userProvider).userRole == 'Admin')
            IconButton(
              icon: const Icon(Icons.category),
              tooltip: 'Daftar Mata Pelajaran',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapelListPage()),
                );
              },
            ),
          if (ref.watch(userProvider).userRole == 'Admin')
            IconButton(
              icon: const Icon(Icons.precision_manufacturing),
              tooltip: 'Konfigurasi Bobot',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WeightConfigPage()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: () async {
              final firebaseServices = ref.read(firebaseServicesProvider);
              await firebaseServices.logout();
              if (context.mounted) {
                ref.read(userProvider.notifier).logout();
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
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
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
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent),
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
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.transparent),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredSantri.isEmpty
                    ? const Center(child: Text('Data tidak ditemukan'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: filteredSantri.length,
                          itemBuilder: (context, index) {
                            final santri = filteredSantri[index];
                            final bool hasPendingWrites = santri.syncStatus != 0;

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
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
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SantriFormPage(santri: santri),
                                              ),
                                            );
                                            _loadData();
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
                                                _loadData();
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
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SantriDetailPage(santri: santri),
                                    ),
                                  );
                                  _loadData(); // Reload on return just in case
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: (ref.watch(userProvider).userRole != 'Wali Santri')
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SantriFormPage()),
                );
                _loadData();
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }

  void _showSyncDialog() {
    // Manually trigger sync
    // In a real app, this might show progress.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sinkronisasi Data'),
          content: const Text('Sedang mencoba sinkronisasi data ke server...'),
          actions: [
            TextButton(
              onPressed: () {
                 Navigator.pop(context);
              }, 
              child: const Text('Tutup')
            )
          ],
        );
      }
    );
    // Trigger sync
    // Use the synchronization service
    // Note: SynchronizationService is automatically started if watched, but here we might want to force check.
    // Since we don't have a direct "forceSync" on provider without instance, we can rely on repositories.
    // Or access the service if we expose a method.
    // For now, let's just trigger repo syncs.
    ref.read(santriRepositoryProvider).syncPendingChanges().then((_) {
      ref.read(penilaianRepositoryProvider).syncPendingChanges().then((_) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Sinkronisasi selesai (jika online).'))
           );
           _loadData(); // Reload list to update status icons
         }
      });
    });
  }
}

class SantriDetailPage extends ConsumerStatefulWidget {
  final SantriModel santri;

  const SantriDetailPage({super.key, required this.santri});

  @override
  ConsumerState<SantriDetailPage> createState() => _SantriDetailPageState();
}

class _SantriDetailPageState extends ConsumerState<SantriDetailPage> {
  List<PenilaianTahfidz> _tahfidzData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTahfidzData();
  }

  Future<void> _loadTahfidzData() async {
    final _penilaianRepository = ref.read(penilaianRepositoryProvider);
    final data = await _penilaianRepository.getTahfidzBySantri(widget.santri.id);
    if (mounted) {
      setState(() {
        _tahfidzData = data;
        _isLoading = false;
      });
    }
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
                  _buildNilaiCard('Tahfidz', '93', Colors.green, Icons.book),
                  _buildNilaiCard('Fiqh', '86', Colors.blue, Icons.balance),
                  _buildNilaiCard('Bahasa Arab', '78', Colors.orange, Icons.language),
                  _buildNilaiCard('Akhlak', '94', Colors.purple, Icons.emoji_people),
                  _buildNilaiCard('Kehadiran', '90', Colors.red, Icons.calendar_today),
                  const SizedBox(height: 16),
                  if (ref.watch(userProvider).userRole != 'Wali Santri')
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InputPenilaianPage(santri: widget.santri),
                          ),
                        );
                        _loadTahfidzData();
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

    _tahfidzData.sort((a, b) => a.minggu.compareTo(b.minggu));

    List<FlSpot> spots = _tahfidzData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.nilaiAkhir);
    }).toList();

    double minY = spots.map((spot) => spot.y).reduce(min);
    double maxY = spots.map((spot) => spot.y).reduce(max);
    if (maxY < 100) maxY = 100;

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
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < _tahfidzData.length && value.toInt() >= 0) {
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
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY > 0 ? (minY - 10).floorToDouble() : 0,
                maxY: maxY + 10,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.3)),
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