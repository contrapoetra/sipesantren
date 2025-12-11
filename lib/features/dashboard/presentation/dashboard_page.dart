import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/providers/user_provider.dart';
import 'package:sipesantren/features/admin/presentation/weight_config_page.dart';
import 'package:sipesantren/features/admin/presentation/user_management_page.dart';
import 'package:sipesantren/features/auth/presentation/login_page.dart';
import 'package:sipesantren/features/santri/presentation/santri_list_page.dart';
import 'package:sipesantren/features/kelas/presentation/kelas_list_page.dart';
import 'package:sipesantren/features/master_data/presentation/mapel_list_page.dart';
import 'package:sipesantren/firebase_services.dart';

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
              Text('Selamat Datang ${userState.userName}!',
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
                icon: Icons.class_,
                title: 'Kelola Kelas',
                subtitle: 'Atur kelas, wali kelas, dan pengajar.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const KelasListPage()));
                },
              ),
              const SizedBox(height: 10),
              DashboardActionCard(
                icon: Icons.library_books,
                title: 'Kelola Mata Pelajaran',
                subtitle: 'Tambah dan edit mata pelajaran.',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const MapelListPage()));
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
              Text('Selamat Datang ${userState.userName}!',
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
                icon: Icons.class_,
                title: 'Kelas',
                subtitle: 'Absensi dan Penilaian per Kelas (Fiqh/B. Arab).',
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const KelasListPage()));
                },
              ),
              const SizedBox(height: 10),
              DashboardActionCard(
                icon: Icons.score,
                title: 'Input Nilai Individual',
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
      case 'Wali':
        bodyContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selamat Datang ${userState.userName}!',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),

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
              final firebaseServices = ref.read(firebaseServicesProvider);
              firebaseServices.logout();
              ref.read(userProvider.notifier).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (userState.requestStatus == 'pending')
            Container(
              width: double.infinity,
              color: Colors.amber[100],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[900]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Permintaan Anda menjadi ${userState.requestedRole} sedang ditinjau. Cek lagi nanti.",
                      style: TextStyle(color: Colors.amber[900], fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.amber[900]),
                    onPressed: () async {
                      final firebaseServices = ref.read(firebaseServicesProvider);
                      final updatedUser = await firebaseServices.getUserById(userState.userId!);
                      
                      if (updatedUser != null && context.mounted) {
                        // Update session and provider
                        await firebaseServices.saveUserSession(
                          updatedUser.id,
                          updatedUser.role,
                          updatedUser.name,
                          requestedRole: updatedUser.requestedRole,
                          requestStatus: updatedUser.requestStatus,
                        );
                        
                        ref.read(userProvider.notifier).login(
                          updatedUser.id,
                          updatedUser.role,
                          updatedUser.name,
                          requestedRole: updatedUser.requestedRole,
                          requestStatus: updatedUser.requestStatus,
                        );

                        if (updatedUser.requestStatus == 'pending') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Status masih menunggu persetujuan.")),
                          );
                        }
                      }
                    },
                  )
                ],
              ),
            ),
          if (userState.requestStatus == 'approved')
            Container(
              width: double.infinity,
              color: Colors.green[100],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.green[900]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Permintaan peran Anda telah disetujui.",
                      style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.green[900]),
                    onPressed: () async {
                      final firebaseServices = ref.read(firebaseServicesProvider);
                      await firebaseServices.dismissRequestStatus(userState.userId!);
                      
                       // Update session and provider to clear the status
                        await firebaseServices.saveUserSession(
                          userState.userId!,
                          userState.userRole!,
                          userState.userName!,
                          requestedRole: null,
                          requestStatus: null,
                        );

                        ref.read(userProvider.notifier).clearRequestStatus();
                    },
                  )
                ],
              ),
            ),
          if (userState.requestStatus == 'rejected')
            Container(
              width: double.infinity,
              color: Colors.red[100],
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[900]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Permintaan Anda menjadi ${userState.requestedRole} ditolak.",
                      style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red[900]),
                    onPressed: () async {
                      final firebaseServices = ref.read(firebaseServicesProvider);
                      await firebaseServices.dismissRequestStatus(userState.userId!);
                      
                       // Update session and provider to clear the status
                        await firebaseServices.saveUserSession(
                          userState.userId!,
                          userState.userRole!,
                          userState.userName!,
                          requestedRole: null,
                          requestStatus: null,
                        );

                        ref.read(userProvider.notifier).clearRequestStatus();
                    },
                  )
                ],
              ),
            ),
          Expanded(child: bodyContent),
        ],
      ),
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