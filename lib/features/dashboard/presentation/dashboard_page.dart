import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/providers/user_provider.dart';
import 'package:sipesantren/features/admin/presentation/weight_config_page.dart';
import 'package:sipesantren/features/admin/presentation/user_management_page.dart';
import 'package:sipesantren/features/auth/presentation/login_page.dart';
import 'package:sipesantren/features/santri/presentation/santri_list_page.dart';
import 'package:sipesantren/firebase_services.dart'; // Added import

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    String roleMessage = "Peran Tidak Dikenali";
    if (userState.userRole != null) {
      roleMessage = "Masuk sebagai: ${userState.userRole}";
    }

    Widget bodyContent;
    switch (userState.userRole) {
      case 'Admin':
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selamat Datang Admin! $roleMessage',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              DashboardActionCard(
                icon: Icons.people_outline,
                title: 'Kelola Santri',
                subtitle: 'Tambah, edit, hapus data santri.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SantriListPage()));
                },
              ),
              const SizedBox(height: 10),
              DashboardActionCard(
                icon: Icons.edit_note,
                title: 'Konfigurasi Bobot Penilaian',
                subtitle: 'Atur bobot penilaian untuk berbagai mata pelajaran.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const WeightConfigPage()));
                },
              ),
              const SizedBox(height: 10),
              DashboardActionCard(
                icon: Icons.people,
                title: 'Kelola Pengguna',
                subtitle: 'Tambah, edit, atau hapus akun pengguna.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const UserManagementPage()));
                },
              ),
            ],
          ),
        );
        break;
      case 'Ustadz':
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selamat Datang ${userState.userRole}! $roleMessage',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              DashboardActionCard(
                icon: Icons.school,
                title: 'Kelola Santri',
                subtitle: 'Lihat dan kelola informasi santri.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SantriListPage()));                },
              ),
              const SizedBox(height: 10),
              DashboardActionCard(
                icon: Icons.score,
                title: 'Input Nilai',
                subtitle: 'Masukkan dan perbarui nilai santri.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SantriListPage()));
                },
              ),
            ],
          ),
        );
        break;
      case 'Wali': // Updated from 'Wali Santri' to match registration
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selamat Datang Wali Santri! $roleMessage',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              DashboardActionCard(
                icon: Icons.assignment,
                title: 'Lihat Rapor',
                subtitle: 'Akses rapor santri Anda.',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SantriListPage()));
                },
              ),
              const SizedBox(height: 10),
              DashboardActionCard(
                icon: Icons.person,
                title: 'Lihat Detail Santri',
                subtitle: 'Lihat informasi rinci tentang santri Anda.',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SantriListPage()));
                },
              ),
            ],
          ),
        );
        break;
      default:
        // Fallback for any other role
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               Text('Peran: ${userState.userRole}.'),
               const SizedBox(height: 20),
               DashboardActionCard(
                icon: Icons.list,
                title: 'Daftar Santri',
                subtitle: 'Lihat daftar santri.',
                onTap: () {
                   Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const SantriListPage()));
                },
              ),
            ],
          )
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dasbor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Proper logout via provider
              final firebaseServices = ref.read(firebaseServicesProvider); // Obtain service via provider
              firebaseServices.logout(); // Call logout on service
              ref.read(userProvider.notifier).logout(); // Update state
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}

class DashboardActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const DashboardActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
