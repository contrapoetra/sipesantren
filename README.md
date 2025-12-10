# e-Penilaian Santri Pesantren

Aplikasi mobile berbasis Flutter untuk digitalisasi penilaian santri (akademik & non-akademik) di Pesantren. Aplikasi ini dirancang dengan pendekatan **Offline-First**, memungkinkan penggunaan tanpa koneksi internet, dengan sinkronisasi otomatis ke Firebase saat online.

## Fitur Utama

*   **Multi-Peran**: Login sebagai Admin, Ustadz/Wali Kelas, atau Wali Santri dengan hak akses yang berbeda.
*   **Offline-First**: Semua data (Santri, Nilai, Absensi) disimpan lokal menggunakan SQLite (`sqflite`). Aplikasi berfungsi penuh tanpa internet.
*   **Sinkronisasi**: Sinkronisasi dua arah (Push/Pull) otomatis dengan **Firebase Firestore** saat perangkat terhubung ke internet.
*   **Manajemen Santri**: CRUD data santri dengan validasi kapasitas kamar dinamis.
*   **Input Penilaian Lengkap**:
    *   **Tahfidz**: Target hafalan, setoran ayat, dan nilai tajwid.
    *   **Mapel (Fiqh & Bahasa Arab)**: Input nilai formatif dan sumatif. Mendukung input massal per kelas.
    *   **Akhlak**: Penilaian indikator perilaku (Disiplin, Adab, dll).
    *   **Kehadiran**: Kalender absensi visual (Hadir, Sakit, Izin, Alpa).
*   **Otomatisasi Nilai**: Perhitungan Nilai Akhir dan Predikat (A-D) otomatis berdasarkan bobot yang dapat dikonfigurasi.
*   **Rapor Digital**:
    *   Visualisasi grafik perkembangan.
    *   Ekspor Rapor ke format **PDF**.
    *   Rincian transparan perhitungan nilai.

## Arsitektur & Teknologi

Aplikasi ini dibangun menggunakan arsitektur **Clean Architecture** yang disederhanakan dengan pemisahan layer:
*   **Presentation**: UI (Pages, Widgets) yang reaktif menggunakan `flutter_riverpod`.
*   **Core/Domain**: Model data dan logika bisnis (Service).
*   **Data/Repository**: Abstraksi sumber data yang menangani logika *Offline-First* (memilih antara SQLite atau Firestore).

**Paket Utama:**
*   `flutter_riverpod`: State management & Dependency Injection.
*   `sqflite`: Database lokal.
*   `cloud_firestore` & `firebase_core`: Backend cloud.
*   `connectivity_plus`: Deteksi status internet.
*   `pdf` & `printing`: Pembuatan dokumen PDF.
*   `fl_chart`: Visualisasi grafik.
*   `flutter_secure_storage`: Penyimpanan sesi login aman.

## Persyaratan Sistem

*   Flutter SDK: >=3.0.0
*   Dart SDK: >=3.0.0
*   Android SDK / iOS Xcode (untuk menjalankan di emulator/device)

## Cara Menjalankan Aplikasi

1.  **Clone Repository** ini.
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Konfigurasi Firebase**:
    *   Aplikasi ini memerlukan file `lib/firebase_options.dart` yang valid agar sinkronisasi berfungsi.
    *   Buat project di Firebase Console.
    *   Gunakan [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) untuk mengonfigurasi project:
        ```bash
        flutterfire configure
        ```
    *   *Catatan: Project ini menyertakan file dummy untuk keperluan kompilasi, namun sinkronisasi akan gagal jika tidak dikonfigurasi dengan kredensial asli.*
4.  **Jalankan Aplikasi**:
    ```bash
    flutter run
    ```

## Cara Menjalankan Pengujian (Testing)

Project ini dilengkapi dengan Widget Test dan Unit Test untuk memverifikasi logika perhitungan dan integritas UI dasar.

Untuk menjalankan seluruh test suite:

```bash
flutter test
```

Untuk menjalankan test spesifik:

```bash
# Test logika perhitungan nilai
flutter test test/grading_service_test.dart

# Test UI daftar santri (Widget Test)
flutter test test/santri_list_page_test.dart

# Smoke test aplikasi (memastikan app bisa render)
flutter test test/widget_test.dart
```

## Asumsi Pengembangan

1.  **Bobot Nilai**: Bobot default adalah Tahfidz (30%), Fiqh (20%), B. Arab (20%), Akhlak (20%), Kehadiran (10%). Bobot ini dapat diubah oleh Admin melalui menu Dashboard.
2.  **Kapasitas Kamar**: Default kapasitas kamar adalah 6 santri. Dapat dikonfigurasi oleh Admin.
3.  **Akun Awal**: Sistem registrasi terbuka untuk memudahkan pengujian. Dalam produksi, registrasi Admin/Ustadz mungkin perlu dibatasi.
4.  **Konflik Data**: Strategi sinkronisasi saat ini memprioritaskan data server jika terjadi konflik ID yang sama saat *pull*, namun mempertahankan perubahan lokal yang belum disinkronkan (*dirty writes*).

---
*Dibuat untuk Studi Kasus Flutter Developer.*