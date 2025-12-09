import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/weight_config_model.dart';
import 'package:sipesantren/core/repositories/weight_config_repository.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sipesantren/core/providers/weight_config_provider.dart'; // New import

class WeightConfigPage extends ConsumerStatefulWidget {
  const WeightConfigPage({super.key});

  @override
  ConsumerState<WeightConfigPage> createState() => _WeightConfigPageState();
}

class _WeightConfigPageState extends ConsumerState<WeightConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {
    'tahfidz': TextEditingController(),
    'fiqh': TextEditingController(),
    'bahasaArab': TextEditingController(),
    'akhlak': TextEditingController(),
    'kehadiran': TextEditingController(),
  };

  bool _hasUnsavedChanges = false;
  late WeightConfigModel _initialConfig; // Store the initially loaded config

  double _currentSumPercentage = 0.0; // New state variable for sum
  bool _showSumWarning = false; // New state variable for warning display
  bool _isInitialized = false; // New flag to track if controllers are initialized

  @override
  void initState() {
    super.initState();
    _addListenersToControllers();
  }

  void _addListenersToControllers() {
    _controllers.forEach((key, controller) {
      controller.addListener(_checkForChangesAndSum); // Use new method
    });
  }

  void _removeListenersFromControllers() {
    _controllers.forEach((key, controller) {
      controller.removeListener(_checkForChangesAndSum); // Use new method
    });
  }

  void _checkForChangesAndSum() { // Renamed and modified
    final currentConfig = _createConfigFromControllers();
    
    // Calculate sum of current weights (as decimals, then convert to percentage)
    final sumOfDecimals = currentConfig.tahfidz +
                          currentConfig.fiqh +
                          currentConfig.bahasaArab +
                          currentConfig.akhlak +
                          currentConfig.kehadiran;
    final newSumPercentage = sumOfDecimals * 100;

    // Use a small epsilon for floating point comparisons to avoid precision issues
    const double _epsilon = 0.0000001; 

    // Determine if there are unsaved changes
    final bool areEqual = 
        (_initialConfig.tahfidz - currentConfig.tahfidz).abs() < _epsilon &&
        (_initialConfig.fiqh - currentConfig.fiqh).abs() < _epsilon &&
        (_initialConfig.bahasaArab - currentConfig.bahasaArab).abs() < _epsilon &&
        (_initialConfig.akhlak - currentConfig.akhlak).abs() < _epsilon &&
        (_initialConfig.kehadiran - currentConfig.kehadiran).abs() < _epsilon;

    final bool shouldHaveChanges = !areEqual;

    // Determine if warning should be shown
    final newShowSumWarning = newSumPercentage > (100.0 + _epsilon);

    // Update state only if necessary to avoid unnecessary rebuilds
    if (shouldHaveChanges != _hasUnsavedChanges || newShowSumWarning != _showSumWarning || (newSumPercentage - _currentSumPercentage).abs() > _epsilon) {
      debugPrint("--- _checkForChangesAndSum ---");
      debugPrint("Initial Config: Tahfidz=${_initialConfig.tahfidz}, Fiqh=${_initialConfig.fiqh}, Bahasa=${_initialConfig.bahasaArab}, Akhlak=${_initialConfig.akhlak}, Kehadiran=${_initialConfig.kehadiran}");
      debugPrint("Current Config: Tahfidz=${currentConfig.tahfidz}, Fiqh=${currentConfig.fiqh}, Bahasa=${currentConfig.bahasaArab}, Akhlak=${currentConfig.akhlak}, Kehadiran=${currentConfig.kehadiran}");
      debugPrint("Should Have Changes: $shouldHaveChanges, Current _hasUnsavedChanges: $_hasUnsavedChanges");
      debugPrint("New Sum Percentage: $newSumPercentage, New Show Sum Warning: $newShowSumWarning");
      setState(() {
        _hasUnsavedChanges = shouldHaveChanges;
        _currentSumPercentage = newSumPercentage;
        _showSumWarning = newShowSumWarning;
      });
    }
  }

  // Helper to create a WeightConfigModel from current controller values (for comparison)
  WeightConfigModel _createConfigFromControllers() {
    // We parse as double/100 as the controllers display percentages
    final tahfidz = (double.tryParse(_controllers['tahfidz']!.text) ?? 0.0) / 100;
    final fiqh = (double.tryParse(_controllers['fiqh']!.text) ?? 0.0) / 100;
    final bahasaArab = (double.tryParse(_controllers['bahasaArab']!.text) ?? 0.0) / 100;
    final akhlak = (double.tryParse(_controllers['akhlak']!.text) ?? 0.0) / 100;
    final kehadiran = (double.tryParse(_controllers['kehadiran']!.text) ?? 0.0) / 100;

    return WeightConfigModel(
      id: 'grading_weights', // Dummy ID for comparison
      tahfidz: tahfidz,
      fiqh: fiqh,
      bahasaArab: bahasaArab,
      akhlak: akhlak,
      kehadiran: kehadiran,
    );
  }

  @override
  void dispose() {
    _removeListenersFromControllers();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveWeights() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final repo = ref.read(weightConfigRepositoryProvider);

      try {
        // Parse input as percentage and convert to decimal for storage
        final tahfidz = (double.tryParse(_controllers['tahfidz']!.text) ?? 0.0) / 100;
        final fiqh = (double.tryParse(_controllers['fiqh']!.text) ?? 0.0) / 100;
        final bahasaArab = (double.tryParse(_controllers['bahasaArab']!.text) ?? 0.0) / 100;
        final akhlak = (double.tryParse(_controllers['akhlak']!.text) ?? 0.0) / 100;
        final kehadiran = (double.tryParse(_controllers['kehadiran']!.text) ?? 0.0) / 100;

        final newConfig = WeightConfigModel(
          id: 'grading_weights', // Fixed ID as defined in repository
          tahfidz: tahfidz,
          fiqh: fiqh,
          bahasaArab: bahasaArab,
          akhlak: akhlak,
          kehadiran: kehadiran,
        );
        await repo.updateWeightConfig(newConfig);
        Fluttertoast.showToast(msg: "Bobot berhasil diperbarui!");

        // After successful save, update initial config and disable button
        setState(() {
          _initialConfig = newConfig; // Update initial config to the newly saved one
          _hasUnsavedChanges = false;
          
          // Re-calculate sum and warning based on new config
          final sumOfDecimals = _initialConfig.tahfidz +
                                _initialConfig.fiqh +
                                _initialConfig.bahasaArab +
                                _initialConfig.akhlak +
                                _initialConfig.kehadiran;
          _currentSumPercentage = sumOfDecimals * 100;
          const double _epsilon = 0.0000001; 
          _showSumWarning = _currentSumPercentage > (100.0 + _epsilon);
        });
        // Navigator.of(context).pop(); // Removed: Keep user on page after saving
      } catch (e) {
        Fluttertoast.showToast(msg: "Gagal memperbarui bobot: $e");
      }
    }
  }

  String? _weightValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mohon masukkan bobot';
    }
    // Remove '%' before parsing
    final cleanValue = value.replaceAll('%', '');
    final double? weightPercentage = double.tryParse(cleanValue);
    if (weightPercentage == null || weightPercentage < 0 || weightPercentage > 100) {
      return 'Bobot harus berupa angka antara 0 dan 100 (mis. 30 atau 30%)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final weightConfigAsync = ref.watch(weightConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfigurasi Bobot Penilaian'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0, // Flat app bar
      ),
      body: weightConfigAsync.when(
        data: (config) {
          // Initialize controllers and _initialConfig only once when data is first loaded
          if (!_isInitialized) {
            _initialConfig = config; // Set initial config
            _controllers['tahfidz']!.text = (config.tahfidz * 100).toStringAsFixed(0);
            _controllers['fiqh']!.text = (config.fiqh * 100).toStringAsFixed(0);
            _controllers['bahasaArab']!.text = (config.bahasaArab * 100).toStringAsFixed(0);
            _controllers['akhlak']!.text = (config.akhlak * 100).toStringAsFixed(0);
            _controllers['kehadiran']!.text = (config.kehadiran * 100).toStringAsFixed(0);
            // Initial calculation of sum and warning state
            _checkForChangesAndSum(); // Call after initial config and controllers are set
            _isInitialized = true; // Mark as initialized
          } // <--- MISSING CLOSING CURLY BRACE ADDED HERE

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildWeightInputCard('Tahfidz', _controllers['tahfidz']!, Icons.book),
                const SizedBox(height: 12),
                _buildWeightInputCard('Fiqh', _controllers['fiqh']!, Icons.school),
                const SizedBox(height: 12),
                _buildWeightInputCard('Bahasa Arab', _controllers['bahasaArab']!, Icons.language),
                const SizedBox(height: 12),
                _buildWeightInputCard('Akhlak', _controllers['akhlak']!, Icons.favorite_border),
                const SizedBox(height: 12),
                _buildWeightInputCard('Kehadiran', _controllers['kehadiran']!, Icons.check_circle_outline),
                const SizedBox(height: 30),
                if (_showSumWarning)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Total bobot (${_currentSumPercentage.toStringAsFixed(0)}%) melebihi 100%. Harap sesuaikan.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_hasUnsavedChanges && !_showSumWarning) ? _saveWeights : null, // Enable/disable based on state and sum warning
                    icon: const Icon(Icons.save),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.5), // Disabled style
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Consistent with dialog buttons
                      ),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildWeightInputCard(String label, TextEditingController controller, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none, // Remove border from TextFormField itself
          contentPadding: EdgeInsets.zero, // Remove default padding
          prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
          prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
          suffixText: '%', // Display percentage symbol visually
          suffixStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _weightValidator,
        onSaved: (value) => controller.text = value!,
      ),
    );
  }
}
