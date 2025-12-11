import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sipesantren/core/models/kelas_model.dart';
import 'package:sipesantren/core/models/penilaian_model.dart';
import 'package:sipesantren/core/models/santri_model.dart';
import 'package:sipesantren/core/repositories/penilaian_repository.dart';
import 'package:sipesantren/core/repositories/santri_repository.dart';

class KelasAttendancePage extends ConsumerStatefulWidget {
  final KelasModel kelas;

  const KelasAttendancePage({super.key, required this.kelas});

  @override
  ConsumerState<KelasAttendancePage> createState() => _KelasAttendancePageState();
}

class _KelasAttendancePageState extends ConsumerState<KelasAttendancePage> {
  DateTime _selectedDate = DateTime.now();
  List<SantriModel> _students = [];
  bool _isLoading = true;
  final Map<String, String> _attendanceMap = {}; // SantriID -> Status (H,S,I,A)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final santriRepo = ref.read(santriRepositoryProvider);

    try {
      // Fetch students
      final students = await santriRepo.getSantriByKelas(widget.kelas.id);
      
      // Fetch existing attendance for this date (if any) to pre-fill
      // Note: We don't have a direct "getByKelasAndDate" yet, so we might need to fetch by student individually
      // or implement a better query. For now, let's fetch for each student (inefficient but works for prototype)
      // OR just default to 'H' (Present) if not set.
      // Let's iterate and try to find. Ideally we need `getKehadiranByKelasAndDate` in repo.
      // Assuming for now we just default to 'H' or empty.
      // Let's try to see if we can fetch.
      
      // Optimization: Default all to 'H' (Hadir)
      for (var s in students) {
        _attendanceMap[s.id] = 'H';
      }

      if (mounted) {
        setState(() {
          _students = students;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var s in _students) {
        _attendanceMap[s.id] = status;
      }
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    final repo = ref.read(penilaianRepositoryProvider);
    int count = 0;
    try {
      for (var s in _students) {
        final status = _attendanceMap[s.id] ?? 'H';
        final data = Kehadiran(
          id: '', // Repo generates ID
          santriId: s.id,
          tanggal: _selectedDate,
          status: status,
        );
        await repo.addKehadiran(data);
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Absensi $count siswa tersimpan.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi Kelas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveAttendance,
          )
        ],
      ),
      body: Column(
        children: [
          // Date Selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tanggal Absensi', style: TextStyle(fontSize: 12)),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_selectedDate),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          
          // Bulk Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Set Semua: '),
                const SizedBox(width: 8),
                ActionChip(label: const Text('Hadir'), onPressed: () => _markAll('H')),
                const SizedBox(width: 4),
                ActionChip(label: const Text('Sakit'), onPressed: () => _markAll('S')),
                const SizedBox(width: 4),
                ActionChip(label: const Text('Izin'), onPressed: () => _markAll('I')),
              ],
            ),
          ),
          const Divider(),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatusOption(s.id, 'H', 'Hadir', Colors.green),
                                  _buildStatusOption(s.id, 'S', 'Sakit', Colors.orange),
                                  _buildStatusOption(s.id, 'I', 'Izin', Colors.blue),
                                  _buildStatusOption(s.id, 'A', 'Alpa', Colors.red),
                                ],
                              ),
                            ],
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

  Widget _buildStatusOption(String santriId, String code, String label, Color color) {
    final isSelected = _attendanceMap[santriId] == code;
    return InkWell(
      onTap: () {
        setState(() {
          _attendanceMap[santriId] = code;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
