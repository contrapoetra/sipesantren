import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/weight_config_model.dart';
import 'package:sipesantren/core/repositories/weight_config_repository.dart';
import 'package:sipesantren/core/providers/mapel_provider.dart'; // Added

class WeightConfigPage extends ConsumerStatefulWidget {
  const WeightConfigPage({super.key});

  @override
  ConsumerState<WeightConfigPage> createState() => _WeightConfigPageState();
}

class _WeightConfigPageState extends ConsumerState<WeightConfigPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for static weights
  final _tahfidzController = TextEditingController();
  final _akhlakController = TextEditingController();
  final _kehadiranController = TextEditingController();
  
  // Dynamic controllers for mapels
  final Map<String, TextEditingController> _mapelControllers = {};

  // Controller for settings
  final _maxSantriController = TextEditingController();

  bool _isLoading = true;
  WeightConfigModel? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final repository = ref.read(weightConfigRepositoryProvider);
    // Ensure initialized
    await repository.initializeWeightConfig();
    
    repository.getWeightConfig().listen((config) {
      if (mounted) {
        setState(() {
          _currentConfig = config;
          _tahfidzController.text = (config.tahfidz * 100).toStringAsFixed(0);
          _akhlakController.text = (config.akhlak * 100).toStringAsFixed(0);
          _kehadiranController.text = (config.kehadiran * 100).toStringAsFixed(0);
          _maxSantriController.text = config.maxSantriPerRoom.toString();
          
          // Populate dynamic mapels will happen in build when provider data is available
          // But we can pre-fill map if we want to retain values, strictly logic is better in build or separate init
          // For now, we rely on the provider in build to create controllers if missing.
          
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tahfidzController.dispose();
    _akhlakController.dispose();
    _kehadiranController.dispose();
    _maxSantriController.dispose();
    for (var controller in _mapelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      final repository = ref.read(weightConfigRepositoryProvider);
      
      double t = double.parse(_tahfidzController.text) / 100;
      double a = double.parse(_akhlakController.text) / 100;
      double k = double.parse(_kehadiranController.text) / 100;
      int maxSantri = int.parse(_maxSantriController.text);

      Map<String, double> mapelWeights = {};
      double mapelSum = 0;
      
      _mapelControllers.forEach((id, controller) {
        double val = double.parse(controller.text) / 100;
        mapelWeights[id] = val;
        mapelSum += val;
      });

      double total = t + a + k + mapelSum;
      // Allow small epsilon error
      if ((total - 1.0).abs() > 0.01) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Total bobot harus 100%. Saat ini: ${(total * 100).toStringAsFixed(0)}%')),
        );
        return;
      }

      final newConfig = WeightConfigModel(
        id: _currentConfig!.id,
        tahfidz: t,
        akhlak: a,
        kehadiran: k,
        mapelWeights: mapelWeights,
        maxSantriPerRoom: maxSantri,
      );

      await repository.updateWeightConfig(newConfig);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konfigurasi berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapelsAsync = ref.watch(mapelProvider);

    if (_isLoading || mapelsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Initialize mapel controllers if needed
    if (mapelsAsync.hasValue) {
      for (var mapel in mapelsAsync.value!) {
        if (!_mapelControllers.containsKey(mapel.id)) {
          double weight = _currentConfig?.mapelWeights[mapel.id] ?? 0.0;
          _mapelControllers[mapel.id] = TextEditingController(text: (weight * 100).toStringAsFixed(0));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi Aplikasi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bobot Penilaian (%)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInput('Tahfidz', _tahfidzController),
              _buildInput('Akhlak', _akhlakController),
              _buildInput('Kehadiran', _kehadiranController),
              
              const SizedBox(height: 16),
              const Text('Mata Pelajaran:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              if (mapelsAsync.hasValue)
                ...mapelsAsync.value!.map((mapel) {
                  return _buildInput(mapel.name, _mapelControllers[mapel.id]!);
                }),
              
              const Divider(height: 32),
              
              const Text(
                'Pengaturan Asrama',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxSantriController,
                decoration: const InputDecoration(
                  labelText: 'Maksimal Santri per Kamar',
                  border: OutlineInputBorder(),
                  suffixText: 'orang',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Harus diisi';
                  if (int.tryParse(value) == null) return 'Harus angka';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  child: const Text('SIMPAN KONFIGURASI'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixText: '%',
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Harus diisi';
          if (double.tryParse(value) == null) return 'Harus angka';
          return null;
        },
      ),
    );
  }
}