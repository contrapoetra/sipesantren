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
import 'package:sipesantren/features/admin/presentation/weight_config_page.dart'; // Fixed import

import 'package:sipesantren/core/services/grading_service.dart';
import 'package:sipesantren/core/repositories/weight_config_repository.dart';
import 'package:sipesantren/core/repositories/mapel_repository.dart'; 
import 'package:sipesantren/core/repositories/kelas_repository.dart'; 
import 'package:sipesantren/core/repositories/teaching_repository.dart'; 
import 'package:sipesantren/core/models/weight_config_model.dart'; 
import 'package:sipesantren/core/providers/mapel_provider.dart'; // Added
import 'package:intl/intl.dart';

class SantriListPage extends ConsumerStatefulWidget {
  const SantriListPage({super.key});

  @override
  ConsumerState<SantriListPage> createState() => _SantriListPageState();
}

class _SantriListPageState extends ConsumerState<SantriListPage> with SingleTickerProviderStateMixin {
  String _selectedKamar = 'Semua';
  String _selectedAngkatan = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<SantriModel> _allSantri = [];
  bool _isLoading = true;
  bool _isSyncing = false; 

  late AnimationController _syncAnimationController;

  List<String> _kamarOptions = ['Semua'];
  List<String> _angkatanOptions = ['Semua'];

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _syncAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(santriRepositoryProvider);
      final userState = ref.read(userProvider);
      List<SantriModel> list = [];

      if (userState.userRole == 'Wali' || userState.userRole == 'Wali Santri') {
        if (userState.userId != null) {
          list = await repository.getSantriByWali(userState.userId!);
        }
      } else if (userState.userRole == 'Ustadz') {
        // Fetch all first, then filter (Client-side filtering for simplicity)
        // Ideally we do this in DB, but complex joins in SQFlite via pure SQL helper method would be better
        var all = await repository.getSantriList();
        
        final kelasRepo = ref.read(kelasRepositoryProvider);
        final teachingRepo = ref.read(teachingRepositoryProvider);
        
        final allClasses = await kelasRepo.getKelasList();
        final myAssignments = await teachingRepo.getAssignmentsForUstad(userState.userId!);
        
        // Classes where I am Wali Kelas
        final myWaliKelasIds = allClasses.where((k) => k.waliKelasId == userState.userId).map((k) => k.id).toSet();
        
        // Classes where I teach
        final myTeachingClassIds = myAssignments.map((a) => a.kelasId).toSet();
        
        final accessibleClassIds = {...myWaliKelasIds, ...myTeachingClassIds};
        
        list = all.where((s) => s.kelasId != null && accessibleClassIds.contains(s.kelasId)).toList();
        
      } else {
        // Admin or others
        list = await repository.getSantriList();
      }
      
      // If local list is empty and we are Admin/Ustadz, try fetching from server
      // For Wali, we might want to fetch too if empty
      if (list.isEmpty) {
        // ... (existing logic)
        // Note: For Ustadz filtering to work after fetch, we need to re-apply filter.
        // Simplification: Just fetchAll if empty then re-run this method logic?
        // Let's just do a fetchFromFirestore call if generic list is empty and retry?
        // But getSantriList() returns local.
        // Let's keep the existing "try fetch if empty" logic but apply to the result.
        
        if (mounted) {
           // Only show snackbar if we really think we should have data
           // ScaffoldMessenger.of(context).showSnackBar(...); 
        }
        await repository.fetchFromFirestore();
        
        // Re-run the fetch logic
         if (userState.userRole == 'Wali' || userState.userRole == 'Wali Santri') {
            if (userState.userId != null) {
              list = await repository.getSantriByWali(userState.userId!);
            }
          } else if (userState.userRole == 'Ustadz') {
             var all = await repository.getSantriList();
             final kelasRepo = ref.read(kelasRepositoryProvider);
             final teachingRepo = ref.read(teachingRepositoryProvider);
             final allClasses = await kelasRepo.getKelasList();
             final myAssignments = await teachingRepo.getAssignmentsForUstad(userState.userId!);
             final myWaliKelasIds = allClasses.where((k) => k.waliKelasId == userState.userId).map((k) => k.id).toSet();
             final myTeachingClassIds = myAssignments.map((a) => a.kelasId).toSet();
             final accessibleClassIds = {...myWaliKelasIds, ...myTeachingClassIds};
             list = all.where((s) => s.kelasId != null && accessibleClassIds.contains(s.kelasId)).toList();
          } else {
            list = await repository.getSantriList();
          }
      }
      
      final uniqueKamars = list.map((s) => '${s.kamarGedung}-${s.kamarNomor}').toSet().toList();
      uniqueKamars.sort(); 
      
      final uniqueAngkatan = list.map((s) => s.angkatan.toString()).toSet().toList();
      uniqueAngkatan.sort((a, b) => b.compareTo(a)); 

      if (mounted) {
        setState(() {
          _allSantri = list;
          _kamarOptions = ['Semua', ...uniqueKamars];
          _angkatanOptions = ['Semua', ...uniqueAngkatan];
          
          if (!_kamarOptions.contains(_selectedKamar)) _selectedKamar = 'Semua';
          if (!_angkatanOptions.contains(_selectedAngkatan)) _selectedAngkatan = 'Semua';
          
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

  Future<void> _performSync() async {
    if (_isSyncing) return; // Prevent multiple clicks

    setState(() {
      _isSyncing = true;
    });
    _syncAnimationController.repeat(); // Start rotating

    try {
      final santriRepo = ref.read(santriRepositoryProvider);
      final penilaianRepo = ref.read(penilaianRepositoryProvider);

      // Perform sync
      await santriRepo.syncPendingChanges();
      await penilaianRepo.syncPendingChanges();
      
      // Attempt fetch to update local data from server
      await santriRepo.fetchFromFirestore();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinkronisasi selesai (jika online).')),
        );
        _loadData(); // Refresh list to update status icons
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal sinkronisasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        _syncAnimationController.stop(); // Stop rotating
        _syncAnimationController.reset(); // Reset position
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(santriRepositoryProvider);
    
    final filteredSantri = _allSantri.where((santri) {
      final matchesSearch = santri.nama.toLowerCase().contains(_searchQuery) || 
                          santri.nis.contains(_searchQuery);
      final currentKamar = '${santri.kamarGedung}-${santri.kamarNomor}';
      final matchesKamar = _selectedKamar == 'Semua' || currentKamar == _selectedKamar;
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
          // Rotating Sync Icon
          RotationTransition(
            turns: _syncAnimationController,
            child: IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sinkronisasi Manual',
              onPressed: _performSync,
            ),
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
                  color: Colors.grey.withValues(alpha: 0.1),
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
                            items: _kamarOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'Semua' ? 'Semua Kamar' : 'Kamar $value'),
                              );
                            }).toList(),
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
                            items: _angkatanOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value == 'Semua' ? 'Semua Angkatan' : value),
                              );
                            }).toList(),
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
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                                trailing: (ref.watch(userProvider).userRole != 'Wali' && ref.watch(userProvider).userRole != 'Wali Santri')
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
                                              await repository.deleteSantri(santri.id);
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
      floatingActionButton: (ref.watch(userProvider).userRole != 'Wali' && ref.watch(userProvider).userRole != 'Wali Santri')
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
}

class SantriDetailPage extends ConsumerStatefulWidget {
  final SantriModel santri;

  const SantriDetailPage({super.key, required this.santri});

  @override
  ConsumerState<SantriDetailPage> createState() => _SantriDetailPageState();
}

class _SantriDetailPageState extends ConsumerState<SantriDetailPage> with SingleTickerProviderStateMixin {
  final GradingService _gradingService = GradingService();
  
  bool _isLoading = true;
  
  // Data State
  List<PenilaianTahfidz> _tahfidzData = [];
  List<Kehadiran> _kehadiranData = [];
  
  // Calculated Scores
  Map<String, double> _scores = {
    'Tahfidz': 0,
    'Fiqh': 0,
    'Bahasa Arab': 0,
    'Akhlak': 0,
    'Kehadiran': 0,
  };
  
  Map<String, dynamic> _finalGrade = {
    'score': 0.0,
    'predikat': '-',
  };

  // State for calculation breakdown
  WeightConfigModel? _weights;
  bool _showCalculationDetails = false;

  // Calendar State
  DateTime _focusedMonth = DateTime.now();

  // Speed Dial FAB State
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isFabOpen = false;
  List<String> _inputOptions = ['Tahfidz', 'Akhlak', 'Kehadiran']; // Will be populated with Mapels

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.easeOut);
    
    _loadAllData();
    _loadInputOptions();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadInputOptions() async {
    final mapelRepo = ref.read(mapelRepositoryProvider);
    final mapels = await mapelRepo.getMapelList();
    if (mounted) {
      setState(() {
        _inputOptions = ['Tahfidz', ...mapels.map((m) => m.name), 'Akhlak', 'Kehadiran'];
      });
    }
  }

  Future<void> _loadAllData() async {
    final santriId = widget.santri.id;
    final penilaianRepo = ref.read(penilaianRepositoryProvider);
    final weightRepo = ref.read(weightConfigRepositoryProvider);
    final mapelRepo = ref.read(mapelRepositoryProvider);

    try {
      await weightRepo.initializeWeightConfig();
      final weights = await weightRepo.getWeightConfig().first;
      final mapels = await mapelRepo.getMapelList(); // Fetch all mapels

      final tahfidz = await penilaianRepo.getTahfidzBySantri(santriId);
      final mapelData = await penilaianRepo.getMapelBySantri(santriId);
      final akhlak = await penilaianRepo.getAkhlakBySantri(santriId);
      final kehadiran = await penilaianRepo.getKehadiranBySantri(santriId);

      final sTahfidz = _gradingService.calculateTahfidz(tahfidz);
      final sAkhlak = _gradingService.calculateAkhlak(akhlak);
      final sKehadiran = _gradingService.calculateKehadiran(kehadiran);

      // Calculate Mapel Scores
      Map<String, double> mapelScoresById = {};
      Map<String, double> mapelScoresByName = {};

      for (var m in mapels) {
        // We assume PenilaianMapel stores 'mapel' as Name for now (legacy) or ID?
        // Checking PenilaianMapel model (not visible but usually String mapel).
        // If it stores Name:
        double score = _gradingService.calculateMapel(mapelData, m.name);
        mapelScoresById[m.id] = score;
        mapelScoresByName[m.name] = score;
      }
      
      // Fallback for hardcoded legacy names if they don't match dynamic ones?
      // Assuming migration happened or we just use what we found.

      final finalResult = _gradingService.calculateFinalGrade(
        tahfidz: sTahfidz,
        akhlak: sAkhlak,
        kehadiran: sKehadiran,
        mapelScores: mapelScoresById,
        weights: weights,
      );

      if (mounted) {
        setState(() {
          _tahfidzData = tahfidz;
          _kehadiranData = kehadiran;
          
          _scores = {
            'Tahfidz': sTahfidz,
            'Akhlak': sAkhlak,
            'Kehadiran': sKehadiran,
            ...mapelScoresByName, // Add mapels for display
          };
          
          _finalGrade = finalResult;
          _weights = weights; 
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading detailed data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleFab() {
    setState(() {
      _isFabOpen = !_isFabOpen;
      if (_isFabOpen) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    });
  }

  void _navigateToInput(String type) async {
    _toggleFab(); // Close menu
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InputPenilaianPage(santri: widget.santri, initialType: type),
      ),
    );
    _loadAllData(); // Refresh on return
  }

  IconData _getIconForType(String type) {
    if (type == 'Tahfidz') return Icons.book;
    if (type == 'Akhlak') return Icons.favorite;
    if (type == 'Kehadiran') return Icons.calendar_today;
    return Icons.class_; 
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userProvider).userRole;
    final isWali = userRole == 'Wali' || userRole == 'Wali Santri';

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
        body: Stack(
          children: [
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                children: [
                  _buildTabPenilaian(),
                  _buildTabKehadiran(),
                  _buildTabGrafik(),
                  _buildTabRaporSummary(),
                ],
              ),
            
            // Dim Background
            if (_isFabOpen)
              GestureDetector(
                onTap: _toggleFab,
                child: Container(
                  color: Colors.black54,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
          ],
        ),
        floatingActionButton: !isWali
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_isFabOpen) ..._buildSpeedDialOptions(),
                  FloatingActionButton(
                    heroTag: 'detail_fab',
                    onPressed: _toggleFab,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    child: Icon(_isFabOpen ? Icons.close : Icons.add),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  List<Widget> _buildSpeedDialOptions() {
    return List.generate(_inputOptions.length, (index) {
      final type = _inputOptions[index];
      return ScaleTransition(
        scale: _fabAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              FloatingActionButton.small(
                heroTag: 'option_$index',
                onPressed: () => _navigateToInput(type),
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(_getIconForType(type)),
              ),
            ],
          ),
        ),
      );
    });
  }

  // --- TAB 1: Penilaian ---
  Widget _buildTabPenilaian() {
    // Separate special keys
    final specialKeys = ['Tahfidz', 'Akhlak', 'Kehadiran'];
    final mapelKeys = _scores.keys.where((k) => !specialKeys.contains(k)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildNilaiCard('Tahfidz', _scores['Tahfidz']!.toStringAsFixed(0), Colors.green, Icons.book),
          // Dynamically build mapel cards
          ...mapelKeys.map((key) => 
            _buildNilaiCard(key, _scores[key]!.toStringAsFixed(0), Colors.blue, Icons.class_)
          ),
          _buildNilaiCard('Akhlak', _scores['Akhlak']!.toStringAsFixed(0), Colors.purple, Icons.emoji_people),
          _buildNilaiCard('Kehadiran', _scores['Kehadiran']!.toStringAsFixed(0), Colors.red, Icons.calendar_today),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          // Final Score Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                const Text('ESTIMASI NILAI AKHIR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      double.parse(_finalGrade['score'].toString()).toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 48, 
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _finalGrade['predikat'],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_weights != null) ...[
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showCalculationDetails = !_showCalculationDetails;
                });
              },
              icon: Icon(_showCalculationDetails ? Icons.expand_less : Icons.expand_more),
              label: Text(_showCalculationDetails ? 'Sembunyikan Rincian' : 'Lihat Rincian Perhitungan'),
            ),
            if (_showCalculationDetails)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    _buildCalculationRow('Tahfidz', _scores['Tahfidz']!, _weights!.tahfidz),
                    // Loop Mapels
                    ...ref.read(mapelProvider).value?.map((m) {
                       // Find score by name (UI display) and weight by ID
                       final score = _scores[m.name] ?? 0.0;
                       final weight = _weights!.mapelWeights[m.id] ?? 0.0;
                       return _buildCalculationRow(m.name, score, weight);
                    }) ?? [],
                    _buildCalculationRow('Akhlak', _scores['Akhlak']!, _weights!.akhlak),
                    _buildCalculationRow('Kehadiran', _scores['Kehadiran']!, _weights!.kehadiran),
                    const Divider(),
                                                                                            Row(
                                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                              children: [
                                                                                                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                                                                                Text(double.parse(_finalGrade['score'].toString()).toStringAsFixed(0), style: const TextStyle(fontWeight: FontWeight.bold)),
                                                                                              ],
                                                                                            )
                                                                                          ],
                                                                                        ),
                                                        
                                                  ),
                                              ],
                                    
                                              const SizedBox(height: 80), // Space for FAB
                                            ],
                                          ),
                                        );
                                      }
                                      
                                      Widget _buildCalculationRow(String label, double score, double weight) {
                    
    double contribution = (score * weight);
    // Format to 1 decimal place usually enough
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Text('${score.toStringAsFixed(0)} x ${(weight * 100).toStringAsFixed(0)}%'),
          const SizedBox(width: 16),
          Text('= ${contribution.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // --- TAB 2: Kehadiran ---
  Widget _buildTabKehadiran() {
    // 1. Helper to check status for a specific day
    String? getStatusForDay(int day) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      // Find matching record (ignoring time)
      try {
        final record = _kehadiranData.firstWhere(
          (k) => k.tanggal.year == date.year && k.tanggal.month == date.month && k.tanggal.day == date.day
        );
        return record.status;
      } catch (e) {
        return null; // No record
      }
    }

    // 2. Color Mapper
    Color getColorForStatus(String? status) {
      switch (status) {
        case 'H': return Colors.green; // Hadir
        case 'S': return Colors.yellow[700]!; // Sakit
        case 'I': return Colors.blue; // Izin
        case 'A': return Colors.red; // Alpa
        default: return Colors.grey[300]!; // No Data
      }
    }

    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Month Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
              ),
              Text(
                DateFormat('MMMM yyyy').format(_focusedMonth),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Legend
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _StatusLegend(color: Colors.green, label: 'Hadir'),
              _StatusLegend(color: Colors.yellow, label: 'Sakit'),
              _StatusLegend(color: Colors.blue, label: 'Izin'),
              _StatusLegend(color: Colors.red, label: 'Alpa'),
              _StatusLegend(color: Colors.grey, label: 'K/A'),
            ],
          ),
          const SizedBox(height: 24),

          // Grid
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, // Weekly layout
                childAspectRatio: 1.0,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: daysInMonth,
              itemBuilder: (context, index) {
                final day = index + 1;
                final status = getStatusForDay(day);
                return Container(
                  decoration: BoxDecoration(
                    color: getColorForStatus(status),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: status == null ? Colors.black54 : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: Grafik ---
  Widget _buildTabGrafik() {
    return _buildTahfidzChart(); // Reuse existing method but it now uses populated _tahfidzData
  }

  // --- TAB 4: Rapor Summary ---
  Widget _buildTabRaporSummary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'RINGKASAN RAPOR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                                    const SizedBox(height: 16),
                                    _buildRaporItem('Nilai Akhir', double.parse(_finalGrade['score'].toString()).toStringAsFixed(0)),
                                    _buildRaporItem('Predikat', _finalGrade['predikat']),
                                    _buildRaporItem('Peringkat', '-'),
                   // Rank requires wider context, keeping placeholder
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
    );
  }

  // --- Helpers ---

  Widget _buildTahfidzChart() {
    if (_tahfidzData.isEmpty) {
      return const Center(child: Text('Tidak ada data Tahfidz untuk ditampilkan.'));
    }

    final sortedData = List<PenilaianTahfidz>.from(_tahfidzData);
    sortedData.sort((a, b) => a.minggu.compareTo(b.minggu));

    List<FlSpot> spots = sortedData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.nilaiAkhir);
    }).toList();

    double minY = spots.map((spot) => spot.y).reduce(min);
    double maxY = spots.map((spot) => spot.y).reduce(max);
    // Pad axis
    minY = (minY - 5).clamp(0, 100);
    maxY = (maxY + 5).clamp(0, 100);

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
            aspectRatio: 1.5,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int idx = value.toInt();
                        if (idx >= 0 && idx < sortedData.length) {
                          final date = sortedData[idx].minggu;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              '${date.day}/${date.month}', 
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blueAccent,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withValues(alpha: 0.3)),
                    dotData: const FlDotData(show: true),
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
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(mataPelajaran),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
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

class _StatusLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
