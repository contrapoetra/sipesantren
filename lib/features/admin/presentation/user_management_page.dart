import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sipesantren/core/models/user_model.dart';
import 'package:sipesantren/core/providers/user_list_provider.dart';
import 'package:sipesantren/firebase_services.dart';
import 'package:sipesantren/crypt.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsyncValue = ref.watch(usersStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pengguna'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: usersAsyncValue.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Tidak ada pengguna.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserListItem(user: user, ref: ref, onAction: _handleUserAction);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditUserDialog(context, ref),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _handleUserAction(BuildContext context, WidgetRef ref, String action, UserModel user) async {
    final firebaseServices = ref.read(firebaseServicesProvider);
    switch (action) {
      case 'edit':
        _showAddEditUserDialog(context, ref, user: user);
        break;
      case 'change_password':
        _showChangePasswordDialog(context, ref, user);
        break;
      case 'delete':
        _showDeleteUserDialog(context, ref, user);
        break;
      case 'approve_request':
        try {
          await firebaseServices.approveUserRoleRequest(user.id, user.requestedRole!);
          Fluttertoast.showToast(msg: 'Permintaan peran disetujui!');
        } catch (e) {
          Fluttertoast.showToast(msg: 'Gagal menyetujui: $e');
        }
        break;
      case 'reject_request':
        try {
          await firebaseServices.rejectUserRoleRequest(user.id);
          Fluttertoast.showToast(msg: 'Permintaan peran ditolak.');
        } catch (e) {
          Fluttertoast.showToast(msg: 'Gagal menolak: $e');
        }
        break;
    }
  }

  Future<void> _showAddEditUserDialog(BuildContext context, WidgetRef ref, {UserModel? user}) async {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final passwordController = TextEditingController();
    String selectedRole = user?.role ?? 'Ustadz';
    if (selectedRole == 'Wali Santri') {
      selectedRole = 'Wali';
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? 'Edit Pengguna' : 'Tambah Pengguna Baru', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                if (!isEditing)
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Peran',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'Ustadz', child: Text('Ustadz')),
                    DropdownMenuItem(value: 'Wali', child: Text('Wali Santri')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final firebaseServices = ref.read(firebaseServicesProvider);
                try {
                  if (isEditing) {
                    await firebaseServices.updateUser(
                      user.id,
                      nameController.text,
                      emailController.text,
                      selectedRole,
                    );
                    Fluttertoast.showToast(msg: 'Pengguna berhasil diperbarui!');
                  } else {
                    if (passwordController.text.isEmpty) {
                      Fluttertoast.showToast(msg: 'Kata sandi tidak boleh kosong.');
                      return;
                    }
                    final salt = PasswordHandler.generateSalt();
                    final hashedPassword = PasswordHandler.hashPassword(
                      passwordController.text,
                      salt,
                    );
                    await firebaseServices.createUser(
                      nameController.text,
                      emailController.text,
                      hashedPassword,
                      selectedRole,
                    );
                    Fluttertoast.showToast(msg: 'Pengguna berhasil ditambahkan!');
                  }
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Gagal: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isEditing ? 'Simpan' : 'Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context, WidgetRef ref, UserModel user) async {
    final newPasswordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Ubah Kata Sandi', textAlign: TextAlign.center),
          content: TextField(
            controller: newPasswordController,
            decoration: const InputDecoration(
              labelText: 'Kata Sandi Baru',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock_reset),
            ),
            obscureText: true,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text.isEmpty) {
                  Fluttertoast.showToast(msg: 'Kata sandi tidak boleh kosong.');
                  return;
                }
                final firebaseServices = ref.read(firebaseServicesProvider);
                try {
                  await firebaseServices.updateUserPassword(
                    user.id,
                    newPasswordController.text,
                  );
                  Fluttertoast.showToast(msg: 'Kata sandi berhasil diperbarui!');
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Gagal memperbarui kata sandi: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ubah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteUserDialog(BuildContext context, WidgetRef ref, UserModel user) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Hapus Pengguna', textAlign: TextAlign.center),
          content: Text('Apakah Anda yakin ingin menghapus pengguna ${user.name}?', textAlign: TextAlign.center),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final firebaseServices = ref.read(firebaseServicesProvider);
                try {
                  await firebaseServices.deleteUser(user.id);
                  Fluttertoast.showToast(msg: 'Pengguna berhasil dihapus!');
                  if (context.mounted) Navigator.of(context).pop();
                } catch (e) {
                  Fluttertoast.showToast(msg: 'Gagal menghapus pengguna: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}

class _UserListItem extends StatelessWidget {
  final UserModel user;
  final WidgetRef ref;
  final Function(BuildContext, WidgetRef, String, UserModel) onAction;

  const _UserListItem({
    required this.user,
    required this.ref,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.role,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    if (user.requestedRole != null && user.requestStatus == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber),
                        ),
                        child: Text(
                          'Request: ${user.requestedRole}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber[900],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (user.requestedRole != null && user.requestStatus == 'pending') ...[
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              tooltip: 'Setujui',
              onPressed: () => onAction(context, ref, 'approve_request', user),
            ),
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.red),
              tooltip: 'Tolak',
              onPressed: () => onAction(context, ref, 'reject_request', user),
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) => onAction(context, ref, value, user),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'change_password', child: Text('Ubah Kata Sandi')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
    );
  }
}
