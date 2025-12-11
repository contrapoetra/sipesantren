import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/core/models/teaching_assignment_model.dart';
import 'package:sipesantren/core/models/user_model.dart';
import 'package:sipesantren/core/models/mapel_model.dart';
import 'package:sipesantren/core/models/santri_model.dart'; // Added
import 'package:sipesantren/core/providers/kelas_provider.dart';
import 'package:sipesantren/core/providers/teaching_provider.dart';
import 'package:sipesantren/core/providers/user_list_provider.dart';
import 'package:sipesantren/core/providers/mapel_provider.dart';
import 'package:sipesantren/core/providers/user_provider.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';
import 'package:sipesantren/features/kelas/presentation/kelas_attendance_page.dart';
import 'package:sipesantren/features/kelas/presentation/kelas_grading_page.dart';
import 'package:sipesantren/features/kelas/presentation/create_aktivitas_page.dart'; // Added
import 'package:sipesantren/core/providers/aktivitas_kelas_provider.dart'; // Added
import 'package:intl/intl.dart'; // Added for DateFormat

class KelasDetailPage extends ConsumerStatefulWidget {
  final KelasModel kelas;

  const KelasDetailPage({super.key, required this.kelas});

  @override
  ConsumerState<KelasDetailPage> createState() => _KelasDetailPageState();
}

class _KelasDetailPageState extends ConsumerState<KelasDetailPage> with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  String? _selectedWaliKelasId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kelas.name);
    _selectedWaliKelasId = widget.kelas.waliKelasId;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final updatedKelas = widget.kelas.copyWith(
      name: newName,
      waliKelasId: _selectedWaliKelasId,
    );

    ref.read(kelasProvider.notifier).updateKelas(updatedKelas);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perubahan disimpan')));
  }

  void _deleteKelas() {
     showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Kelas'),
          content: Text('Hapus kelas ${widget.kelas.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                ref.read(kelasProvider.notifier).deleteKelas(widget.kelas.id);
                Navigator.pop(context); // Pop Dialog
                Navigator.pop(context); // Pop Page
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final isAdmin = userState.userRole == 'Admin';
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelas ${widget.kelas.name}'),
        actions: [
          if (isAdmin)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteKelas),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Info & Pengajar'),
            Tab(text: 'Aktivitas Kelas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(isAdmin),
          _buildActivitiesTab(userState.userRole, userState.userId),
        ],
      ),
      floatingActionButton: _buildFab(userState.userRole, userState.userId),
    );
  }

  Widget? _buildFab(String? userRole, String? userId) {
    final isAdmin = userRole == 'Admin';
    final isUstadz = userRole == 'Ustadz';
    
    // Only show FAB on the second tab (Activities)
    if (_tabController.index == 1) {
      if (isAdmin || isUstadz) {
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CreateAktivitasPage(kelasId: widget.kelas.id)),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Buat Aktivitas',
        );
      }
    }
    return null;
  }


  Widget _buildInfoTab(bool isAdmin) {
    final usersAsync = ref.watch(usersStreamProvider);
    final assignments = ref.watch(assignmentsByKelasProvider(widget.kelas.id));
    final mapelsAsync = ref.watch(mapelProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kelas Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Informasi Kelas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  if (isAdmin) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nama Kelas'),
                    ),
                    const SizedBox(height: 16),
                    usersAsync.when(
                      data: (users) {
                        final ustads = users.where((u) => u.role == 'Ustadz').toList(); 
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedWaliKelasId,
                          decoration: const InputDecoration(labelText: 'Wali Kelas'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Pilih Wali Kelas')),
                            ...ustads.map((u) => DropdownMenuItem(
                                  value: u.id,
                                  child: Text('${u.name} (${u.role})'),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedWaliKelasId = value;
                            });
                          },
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (e, s) => Text('Error loading users: $e'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveChanges,
                        child: const Text('Simpan Perubahan'),
                      ),
                    ),
                  ] else ...[
                    // Read Only View for Non-Admins
                    Text('Nama Kelas: ${widget.kelas.name}', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    usersAsync.when(
                      data: (users) {
                        final waliName = users.firstWhere(
                          (u) => u.id == widget.kelas.waliKelasId, 
                          orElse: () => UserModel(id: '', name: '-', email: '', role: '', hashedPassword: '', createdAt: DateTime.now())
                        ).name;
                        return Text('Wali Kelas: $waliName', style: const TextStyle(fontSize: 16));
                      },
                      loading: () => const Text('Loading...'),
                      error: (_,__) => const Text('Error'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Teaching Assignments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pengajar Mata Pelajaran', style: Theme.of(context).textTheme.titleLarge),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: () => _showAddAssignmentDialog(context, ref, usersAsync.value ?? [], mapelsAsync.value ?? []),
                ),
            ],
          ),
          if (assignments.isEmpty)
            const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada pengajar ditugaskan.'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                final mapelName = mapelsAsync.value?.firstWhere((m) => m.id == assignment.mapelId, orElse: () => MapelModel(id: '', name: 'Unknown')).name ?? 'Loading...';
                final ustadName = usersAsync.value?.firstWhere((u) => u.id == assignment.ustadId, orElse: () => UserModel(id: '', name: 'Unknown', email: '', role: '', hashedPassword: '', createdAt: DateTime.now())).name ?? 'Loading...';
                
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(mapelName),
                    subtitle: Text('Pengajar: $ustadName'),
                    trailing: isAdmin ? IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref.read(teachingProvider.notifier).deleteAssignment(assignment.id);
                      },
                    ) : null,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab(String? userRole, String? userId) {
    final mapelsAsync = ref.watch(mapelProvider);
    final assignments = ref.watch(assignmentsByKelasProvider(widget.kelas.id));
    final aktivitasAsync = ref.watch(aktivitasKelasProvider(widget.kelas.id));
    
    final isAdmin = userRole == 'Admin';
    final isWaliKelas = widget.kelas.waliKelasId == userId;
    // Check if user is ANY teacher in this class
    final isAssignedTeacher = assignments.any((a) => a.ustadId == userId);

    final cards = <Widget>[];

    // 1. Participants Card
    cards.add(_buildActivityCard(
      title: 'Daftar Siswa',
      icon: Icons.people,
      color: Colors.blue,
      onTap: () => _showParticipants(context, ref),
    ));

    // 2. Attendance Card (Allowed for Admin, Wali Kelas, AND Assigned Teachers)
    if (isAdmin || isWaliKelas || isAssignedTeacher) {
      cards.add(_buildActivityCard(
        title: 'Absensi',
        icon: Icons.calendar_today,
        color: Colors.orange,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => KelasAttendancePage(kelas: widget.kelas)),
          );
        },
      ));
    }

    // 3. Grading Cards
    if (mapelsAsync.hasValue) {
      for (var mapel in mapelsAsync.value!) {
        final isMySubject = assignments.any((a) => a.mapelId == mapel.id && a.ustadId == userId);
        if (isAdmin || isMySubject) {
          cards.add(_buildActivityCard(
            title: 'Nilai ${mapel.name}',
            icon: Icons.assignment,
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KelasGradingPage(kelas: widget.kelas, mapelName: mapel.name),
                ),
              );
            },
          ));
        }
      }
    }

    return CustomScrollView(
      slivers: [
        // Grid
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => cards[index],
              childCount: cards.length,
            ),
          ),
        ),
        
        // Timeline Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Timeline Kelas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // Timeline Feed
        aktivitasAsync.when(
          data: (data) {
            if (data.isEmpty) {
              return const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Belum ada aktivitas.')),
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final activity = data[index];
                  final isAnnouncement = activity.type == 'announcement';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isAnnouncement ? Colors.amber[100] : Colors.blue[100],
                        child: Icon(
                          isAnnouncement ? Icons.campaign : Icons.assignment,
                          color: isAnnouncement ? Colors.amber[800] : Colors.blue[800],
                        ),
                      ),
                      title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(activity.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('dd MMM HH:mm').format(activity.createdAt),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: (isAdmin || activity.authorId == userId)
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                ref.read(aktivitasKelasProvider(widget.kelas.id).notifier).deleteActivity(activity.id);
                              },
                            )
                          : null,
                    ),
                  );
                },
                childCount: data.length,
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
          error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
        ),
        
        // Spacer for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  Widget _buildActivityCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showParticipants(BuildContext context, WidgetRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Daftar Siswa')),
          body: Consumer(
            builder: (context, ref, child) {
              final santriRepo = ref.read(santriRepositoryProvider);
              return FutureBuilder(
                future: santriRepo.getSantriByKelas(widget.kelas.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final students = snapshot.data as List<SantriModel>; 
                  if (students.isEmpty) {
                    return const Center(child: Text('Tidak ada siswa di kelas ini.'));
                  }
                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final s = students[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(s.nama[0])),
                        title: Text(s.nama),
                        subtitle: Text(s.nis),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAddAssignmentDialog(BuildContext context, WidgetRef ref, List<UserModel> users, List<MapelModel> mapels) {
    String? selectedMapelId;
    String? selectedUstadId;
    final ustads = users.where((u) => u.role == 'Ustadz').toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah Pengajar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Mata Pelajaran'),
                    items: mapels.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                    onChanged: (val) => setState(() => selectedMapelId = val),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Ustadz Pengajar'),
                    items: ustads.map((u) => DropdownMenuItem(value: u.id, child: Text(u.name))).toList(),
                    onChanged: (val) => setState(() => selectedUstadId = val),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    if (selectedMapelId != null && selectedUstadId != null) {
                      ref.read(teachingProvider.notifier).addAssignment(
                        TeachingAssignmentModel(
                          id: '',
                          kelasId: widget.kelas.id,
                          mapelId: selectedMapelId!,
                          ustadId: selectedUstadId!,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}