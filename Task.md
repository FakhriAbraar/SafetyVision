# Instruksi Pembuatan Fitur AI Chatbot (Flutter)

Tolong buatkan fitur antarmuka "AI Companion Chatbot" di aplikasi Flutter ini. Ikuti spesifikasi teknis dan integrasi aset di bawah ini dengan sangat presisi.

### 1. Tujuan Utama (Navigasi & UI)
- Tambahkan sebuah **Chat Icon** (berupa Floating Action Button atau tombol di AppBar) pada laman utama (Home Screen). 
- Jika icon tersebut ditekan, navigasikan pengguna ke laman baru bernama `ChatScreen`.
- UI `ChatScreen` harus memiliki tata letak (*layout*) berikut:
  - **Bagian atas/tengah (Visual):** Menampilkan gambar aset karakter 2D (Miku). Gambar ini harus bersifat dinamis dan berubah secara otomatis berdasarkan *state* emosi dan animasi tubuh.
  - **Bagian tengah/bawah (Riwayat):** Area *List/Scrollable* berisi *Chat Bubbles* yang menampilkan riwayat obrolan antara User dan AI.
  - **Bagian bawah (Input):** *TextField* untuk pengguna mengetik pesan dan tombol panah/kirim (*Send*).

### 2. Integrasi API & Audio Server
Tambahkan package `http` dan `audioplayers` di `pubspec.yaml`. Buatkan *Service Class* (`ApiService`) yang akan menembak server AI eksternal:

- **Base URL Endpoint:** Buat variabel statis `https://<URL_CLOUDFLARE>.trycloudflare.com` (Jangan gunakan localhost, ini harus URL publik).
- **Request Method:** Saat tombol kirim ditekan, lakukan `HTTP POST` ke `$baseUrl/api/chat`.
- **Request Body (JSON):** 
  ```json
  {"message": "teks dari textfield", "user_id": "user_flutter"}
  ```

### 3. State Management & Penanganan Response JSON
Server AI akan membalas dengan sebuah JSON (atau List of JSON) yang berisi 4 parameter utama. Buatkan *State Controller* (misal: Provider/GetX/Bloc) untuk menangkap dan bereaksi terhadap nilai-nilai ini:

1. `response_text`: Teks balasan AI. Segera tambahkan ke daftar pesan UI Chat Bubbles.
2. `emotion_tag`: Menentukan ekspresi wajah Miku. Server hanya akan mengirimkan 5 kemungkinan nilai:
   - `happy`
   - `sad`
   - `neutral`
   - `relaxed`
   - `angry`
   - `surprised`
3. `animation_tag`: Menentukan postur/gerakan tubuh Miku. Server hanya akan mengirimkan 7 kemungkinan nilai:
   - `idle`
   - `crossed arm`
   - `shy`
   - `shy2`
   - `hand on chest`
   - `surprised`
   - `wave`
4. `audio_url`: URL relatif untuk file suara (contoh: `/static/audio_123.wav`). Kamu **WAJIB** menggabungkannya dengan Base URL (menjadi `$baseUrl$audioUrl`) lalu langsung memutarnya menggunakan package `audioplayers`.

### 4. Animasi Lip-Sync & Manajemen Aset Gambar
Miku harus terlihat sedang berbicara saat file audio diputar.

- **Logika Lip-Sync:** 
  Buat variabel boolean `isSpeaking`. Saat audio dari `audio_url` sedang diputar, jalankan sebuah *loop* asinkron yang secara acak mengubah *state* bentuk mulut (`mouthVowel`) menjadi `A`, `U`, atau `O` setiap 150 milidetik.
  Begitu pemutaran audio selesai, atur `isSpeaking = false` dan kembalikan *state* mulut ke `close` (tutup).

- **Kebutuhan Aset Gambar (Assets):**
  Kamu harus merakit UI gambar karakter dengan menumpuk (menggunakan `Stack` widget) gambar tubuh/wajah dasar, lalu menimpa gambar mulut di atasnya. 
  Pastikan kamu mendaftarkan folder `assets/miku/` di `pubspec.yaml` dan meminta *developer* untuk menyiapkan struktur *file* gambar berikut:

  **Aset Tubuh (Berdasarkan animation_tag):**
  - `assets/miku/body_idle.png`
  - `assets/miku/body_crossed_arm.png`
  - `assets/miku/body_shy.png`
  - `assets/miku/body_hand_on_chest.png`
  - `assets/miku/body_surprised.png`
  - `assets/miku/body_wave.png`

  **Aset Wajah/Mata (Berdasarkan emotion_tag):**
  - `assets/miku/face_happy.png`
  - `assets/miku/face_sad.png`
  - `assets/miku/face_neutral.png`
  - `assets/miku/face_relaxed.png`

  **Aset Mulut (Berdasarkan Lip-Sync):**
  - `assets/miku/mouth_A.png`
  - `assets/miku/mouth_U.png`
  - `assets/miku/mouth_O.png`
  - `assets/miku/mouth_close.png`

### 5. Idle Micro-Animations (Head & Body Movement)
Karakter 2D akan terlihat kaku seperti patung jika tidak ada pergerakan saat sedang diam. Oleh karena itu, tolong buatkan **logika pergerakan acak (Randomized Micro-Animations)** di *Controller* yang berjalan terus-menerus di *background*:
1. **Breathing (Bernapas):** Buat animasi *Tween* sederhana yang menskalakan (Scale) ukuran tubuh atau menaik-turunkan tubuh sebesar 1-2% secara perlahan dan berulang tanpa henti.
2. **Head & Body Direction:** Buat timer asinkron (*Timer.periodic*) yang aktif setiap 3-6 detik sekali. Timer ini akan memutar (*Rotate*) atau menggeser posisi kepala dan tubuh sedikit ke kiri atau ke kanan secara acak. Tujuannya adalah mensimulasikan Miku yang sedang melihat-lihat ke sekelilingnya secara alami. Gunakan widget `Transform.rotate` atau `Transform.translate` pada elemen gambar tubuh/kepala untuk efek ini.

Silakan tuliskan seluruh kode untuk antarmuka UI, API Service, dan logika *Controller* yang menyatukan semua ini!

