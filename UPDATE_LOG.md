# Update Log Aplikasi SafetyVision

Berikut adalah rangkuman dari seluruh perubahan, peningkatan (*enhancement*), dan perbaikan *bug* yang telah ditambahkan ke dalam aplikasi:

## Pembaruan Fitur Utama
1. **Red Badge Notifikasi & Riwayat Dinamis**
   - Menambahkan titik merah (badge) pada tab Riwayat (Bottom Nav) dan Notifikasi (Home App Bar & Profile Menu).
   - Badge secara cerdas hanya akan muncul jika terdapat pembaruan (*update*) aktivitas atau laporan yang masuk, dan otomatis menghilang saat Anda membuka halaman tersebut.
   - Mengimplementasikan `updatedAt` pada struktur laporan database.
2. **Penghapusan Komentar Sendiri**
   - User maupun Admin kini memiliki hak untuk menghapus komentar milik mereka sendiri di halaman detail laporan. Ikon tempat sampah merah akan muncul di komentar yang relevan.
3. **Peningkatan Batas Radius & Pop-up Dialog Penyelesaian Laporan (Admin)**
   - Mengubah batas minimal jarak admin ke lokasi jalan rusak dari 10 meter menjadi 50 meter.
   - Pop-up pemberitahuan jarak (*Error Message*) kini berbentuk Dialog di depan layar, yang akan langsung mencegat (*intercept*) sebelum Admin membuka form "Pilih Laporan".
   - Admin sekarang wajib menambahkan deskripsi perbaikan dengan batas karakter selain mengunggah foto.
4. **Pull to Refresh Global**
   - Menerapkan fitur *pull-to-refresh* di halaman Beranda, Detail Laporan, dan Profil agar user dapat menarik halaman ke bawah untuk memperbarui data (*refresh*).

## Peningkatan UI/UX & Tampilan Visual
1. **Foto Profil Real-time**
   - Menghapus *placeholder* dan mengganti dengan foto asli pengguna (*current user*) pada menu Beranda (pojok kanan atas), Detail Laporan, serta pada *bubble* komentar.
   - Menjadikan foto profil di Beranda sebagai *shortcut* yang bisa ditekan untuk menuju Halaman Profil.
   - Tampilan nama user pada laporan maupun komentar sekarang diatur agar *sync* secara otomatis bila user melakukan perubahan nama.
2. **Penyempurnaan Tampilan Komentar Admin**
   - Komentar yang dikirimkan oleh Admin kini memiliki label badge "Admin" yang jelas, beserta warna dan grafis (*highlight*) latar khusus untuk membedakannya dengan warga.
3. **Galeri Laporan (*Full Picture Mode*)**
   - Menambahkan fitur di mana gambar di Detail Laporan maupun gambar balasan dari Admin dapat ditekan untuk melihatnya dalam ukuran penuh (*full picture*).
   - Menambahkan dukungan navigasi geser / *swipe* kanan-kiri jika gambar lebih dari satu.
4. **Pembersihan Layout & Statistik Tidak Perlu**
   - Menghapus filter dan elemen statistik berstatus "Diproses" di halaman Beranda.
   - Menghapus *placeholder* statistik (Laporan, Diproses, Selesai) yang tidak dipakai di halaman Profil.
   - Menghapus *gear icon* di halaman profil karena sudah digantikan oleh menu Edit Profil.
   - Memodifikasi tombol Lonceng/Notifikasi di pojok atas Beranda sebagai *shortcut* langsung ke laman Notifikasi.

## Pembaruan Sistem Notifikasi
1. **Pemisahan Notifikasi Sesuai Role**
   - **Non-Admin (User)**: Mendapatkan notifikasi jika laporan mereka "Berhasil Dibuat" dan "Selesai Ditangani".
   - **Admin**: Mendapatkan notifikasi jika ada warga yang mengirimkan "Laporan Baru" yang membutuhkan tindakan (berstatus *Pending*).
