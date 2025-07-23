# Project ETL Data Engineer

Pipeline ETL Modern dengan Kafka, PostgreSQL, dan Pemrosesan Data Real-time

> **🌐 Baca ini dalam bahasa lain:** [English](README.md) • [Bahasa Indonesia](#)

## ⚠️ Catatan Penting
Pipeline ETL ini menyediakan solusi yang robust dan efisien untuk memproses data dari berbagai sumber. **PENTING:** Setelah menggunakan layanan, jalankan `./etl_pipeline_run.sh --stop` untuk mematikan semua container dengan benar dan membebaskan resource sistem.

## 📋 Daftar Isi
- [Prasyarat](#prasyarat)
- [Panduan Memulai](#memulai-dengan-cepat)
- [Struktur Project](#-struktur-project)
- [Pengaturan Infrastruktur](#️-pengaturan-infrastruktur)
- [Urutan Eksekusi](#-urutan-eksekusi)
- [Eksekusi ETL Pipeline](#-eksekusi-etl-pipeline)
- [Pemrosesan Real-time](#-real-time-processing)
- [SQL Tasks](#-sql-tasks)
- [Debugging & Optimasi](#debugging--optimization)
- [Troubleshooting](#-troubleshooting)
- [Monitoring](#-monitoring)
- [Langkah Selanjutnya](#-langkah-selanjutnya)
- [Perintah Referensi Cepat](#perintah-referensi-cepat)

## 🏗️ Pengaturan Infrastruktur

### Prasyarat
- Docker dan Docker Compose v2+
- Minimal 4GB RAM tersedia untuk container
- Port 5433, 7777, 9092, 9093 harus tersedia

### 🤖 Script Otomatisasi

Project ini dilengkapi dengan beberapa script otomatisasi untuk memudahkan penggunaan:

1. **etl_pipeline_run.sh** *(Jalankan ini pertama untuk menyiapkan infrastruktur)*
   - Menjalankan ETL pipeline utama
   - Start dan stop semua services Docker
   - Format: 
     - `./etl_pipeline_run.sh [--sql|--python]` (default: --sql)
     - `./etl_pipeline_run.sh --stop` (untuk menghentikan layanan)
   - Ketika menggunakan opsi `--python`:
     - Menjalankan script Python dari mesin host (bukan di dalam container)
     - Secara otomatis menginstal paket Python yang diperlukan dari `requirements.txt`
     - Sementara mengkonfigurasi script ETL untuk akses database dari host ke container
2. **realtime_processing_run.sh** *(Jalankan setelah ETL pipeline)*
   - Menu interaktif untuk real-time processing
   - Kafka producer/consumer dan SQL processing
   - Format: `./realtime_processing_run.sh`
3. **sql_tasks_run.sh** *(Jalankan setelah real-time processing)*
   - Menu interaktif untuk menjalankan SQL tasks
   - Menjalankan berbagai query analisis dan optimasi
   - Format: `./sql_tasks_run.sh`
4. **debugging_optimization_run.sh** *(Jalankan jika diperlukan untuk pengoptimalan performa)*
   - Menu interaktif untuk debugging dan optimasi
   - Generate test data dan analisis performa
   - Format: `./debugging_optimization_run.sh`

## 📁 Struktur Project
```
etl/
├── docker-compose.yaml       # Konfigurasi infrastruktur
├── .env                      # Variabel lingkungan
├── README.md                 # File dokumentasi Bahasa Inggris
├── README.id.md              # File ini (Bahasa Indonesia)
├── etl_pipeline_run.sh       # Script otomasi ETL pipeline
├── debugging_optimization_run.sh  # Script otomasi debugging & optimasi
├── realtime_processing_run.sh     # Script otomasi real-time processing
├── sql_tasks_run.sh          # Script otomasi SQL tasks
├── etl-pipeline/
│   ├── etl_sql.sql           # Script ETL berbasis SQL
│   ├── etl_script.py         # Script ETL Python (alternatif)
│   └── requirements.txt      # Dependensi Python
├── data-modeling/
├── debugging-optimization/
├── real-time-processing/
└── sql/
```

### Memulai dengan Cepat
1. **Clone dan siapkan environment**
   ```bash
   git clone <repository-url>
   cd etl
   cp .env.example .env  # Edit dengan kredensial Anda
   ```
2. **Mulai infrastruktur**
   ```bash
   docker-compose up -d
   ```
3. **Verifikasi layanan berjalan**
   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

### 🔗 URL Layanan
- **Kafka UI**: http://localhost:7777
- **PostgreSQL**: localhost:5433
- **Kafka Broker**: localhost:9092 (eksternal), broker:9093 (internal)

### 🛠️ Konfigurasi
#### Variabel Lingkungan
Buat file `.env` dengan:
```env
POSTGRES_USER=etl_user
POSTGRES_PASSWORD=secure_password_123
POSTGRES_DB=clickstream_db
```

#### Persistensi Volume
Semua data disimpan dalam volume Docker:
- `postgres_data`: Data PostgreSQL
- `kafka_data`: Topic dan log Kafka
- `zookeeper_data`: Data Zookeeper

## 📊 Eksekusi ETL Pipeline

### Proses ETL Langkah-demi-Langkah
#### Metode 1: Menggunakan Script Otomasi
1. **Jalankan Script Otomasi ETL Project**
   ```bash
   # Pada Linux/Mac: Berikan izin eksekusi (hanya pertama kali)
   chmod +x etl_pipeline_run.sh
   # Pada Windows dengan Git Bash:
   bash etl_pipeline_run.sh
   # Pada Windows dengan CMD/PowerShell:
   bash -c "./etl_pipeline_run.sh"
   ```
   Ini akan secara otomatis:
   - Memulai semua layanan Docker
   - Menunggu PostgreSQL siap (pada port 5433)
   - Menjalankan proses ETL
   - Menampilkan hasil dan status layanan
2. **Hentikan semua layanan setelah selesai**
   ```bash
   bash etl_pipeline_run.sh --stop
   ```

#### Metode 2: Eksekusi Manual
1. **Pastikan layanan Docker berjalan**
   ```bash
   docker-compose ps
   # Semua layanan harus menunjukkan status 'Up'
   ```
2. **Jalankan ETL pipeline menggunakan script SQL**
   ```bash
   # Salin script ETL ke container PostgreSQL
   docker cp etl-pipeline/etl_sql.sql postgres:/tmp/etl_sql.sql
   # Eksekusi proses ETL
   docker-compose exec postgres bash -c "psql -U etl_user -d clickstream_db -f /tmp/etl_sql.sql"
   ```
3. **Verifikasi hasil ETL**
   Script akan otomatis menampilkan:
   - Total records yang dimuat
   - Perincian berdasarkan kategori
   - Contoh data yang ditransformasi

### Gambaran Umum Proses ETL
ETL pipeline melakukan:
- **Extract**: Membuat data pesanan sampel (simulasi sumber data)
- **Transform**: Menghitung total_amount (price × quantity) dan mengkategorikan produk
- **Load**: Menyimpan data yang diproses ke dalam tabel target

### Output yang Diharapkan
```
CREATE TABLE
CREATE TABLE
INSERT 0 4
INSERT 0 4
       message
----------------------
 ETL Process Results:
(1 row)
        metric         | value
-----------------------+-------
 Total records loaded: |     4
(1 row)
      breakdown       |  category   | count | total_amount
----------------------+-------------+-------+--------------
 Records by category: | Furniture   |     2 |       450.00
 Records by category: | Electronics |     2 |       500.00
(2 rows)
```

### 🔍 Troubleshooting
#### Memeriksa status layanan
```bash
docker-compose ps
docker-compose logs -f [nama-layanan]
```

#### Masalah umum
- **PostgreSQL connection refused**: Tunggu health check selesai
- **Kafka not ready**: Pastikan Zookeeper berjalan dengan baik terlebih dahulu
- **Konflik port**: Periksa apakah port 5433, 7777, 9092 tersedia

#### Akses database manual
```bash
# Koneksi langsung ke PostgreSQL
docker-compose exec postgres psql -U etl_user -d clickstream_db
# Daftar tabel
\dt
# Query data
SELECT * FROM sales;
```

### 🧹 Pembersihan
```bash
# Hentikan semua layanan
docker-compose down
# Hapus semua data (hati-hati: ini menghapus semua volume)
docker-compose down -v
# Hapus semuanya termasuk images
docker-compose down --rmi all -v
```

## 🚀 Urutan Eksekusi

Untuk hasil optimal, ikuti urutan eksekusi yang direkomendasikan berikut:

### Langkah 1: Siapkan Infrastruktur dan Jalankan ETL Pipeline
```bash
# Pada Windows dengan Git Bash (menggunakan SQL - default):
bash etl_pipeline_run.sh
# ATAU menggunakan Python:
bash etl_pipeline_run.sh --python

# ATAU pada Windows dengan CMD:
bash -c "./etl_pipeline_run.sh"
bash -c "./etl_pipeline_run.sh --python"  # Menggunakan Python
```
Langkah pertama ini akan:
- Memulai semua container Docker (PostgreSQL, Kafka, Zookeeper)
- Membuat tabel database yang diperlukan
- Memuat data awal
- Menjalankan transformasi ETL

### Langkah 2: Proses Data Real-time
```bash
# Setelah ETL pipeline selesai dengan sukses:
bash realtime_processing_run.sh
```
Dari menu interaktif:
1. Pilih opsi 1 untuk membuat topic Kafka
2. Pilih opsi 2 untuk mengirim contoh pesan
3. Pilih opsi 3 untuk menjalankan consumer Kafka
4. Pilih opsi 4 untuk memproses hasil dengan SQL

### Langkah 3: Jalankan Tugas Analisis SQL
```bash
# Setelah pemrosesan real-time:
bash sql_tasks_run.sh
```
Ini akan memberikan wawasan analitis berdasarkan data yang telah diproses.

### Langkah 4: Debugging & Optimasi (Jika Diperlukan)
```bash
# Untuk pengoptimalan performa:
bash debugging_optimization_run.sh
```

### Menghentikan Semua Layanan
```bash
# Ketika selesai:
bash etl_pipeline_run.sh --stop
```

## 🏃‍♂️ Komponen Project
1. **ETL Pipeline** (`etl-pipeline/`)
   - Script ekstraksi, transformasi, dan loading data
   - Batch processing menggunakan PostgreSQL
   - Sample data generation untuk simulasi

2. **Real-time Processing** (`real-time-processing/`)
   - Kafka consumer untuk stream processing
   - Producer untuk mengirim data ke Kafka
   - Consumer untuk memproses data dan menyimpan ke PostgreSQL
   - SQL processing untuk analisis hasil data real-time

3. **SQL Tasks** (`sql/`)
   - Database queries dan optimizations
   - Task untuk analisis total spending
   - Task untuk mencari city dengan highest orders
   - Task untuk query optimization

4. **Data Modeling** (`data-modeling/`)
   - Database schema dan diagram
   - Entity-relationship diagram

5. **Debugging & Optimization** (`debugging-optimization/`)
   - Performance analysis dan optimization scripts
   - Data generator untuk testing
   - Script untuk optimasi performa

## 🔄 Real-time Processing
Pipeline real-time menggunakan Kafka untuk stream processing:

1. **Producer**: Mengirim data clickstream ke topic Kafka
2. **Consumer**: Memproses messages dari Kafka dan menyimpan ke PostgreSQL
3. **Processing**: SQL script memproses data untuk analitik

Menjalankan real-time processing:
```bash
bash realtime_processing_run.sh
```

Menu interaktif akan muncul dengan opsi:
- Membuat Kafka topic
- Mengirim sample messages
- Menjalankan Kafka consumer
- Memproses hasil dengan SQL

## 🔍 Troubleshooting Tambahan
### Masalah Umum:
1. **Konflik port**: Pastikan port 5433, 7777, 9092, 9093 tersedia
2. **Masalah memori**: Alokasikan minimal 4GB RAM untuk Docker
3. **Masalah perizinan**: Pastikan Docker memiliki izin yang sesuai
4. **Masalah koneksi**: Saat mengakses dari luar container, gunakan localhost:9092 untuk Kafka dan localhost:5433 untuk PostgreSQL

### Health Checks:
Semua layanan menyertakan health check. Pantau dengan:
```bash
docker-compose ps
```

## 📊 Monitoring
- Gunakan Kafka UI di http://localhost:7777 untuk memantau topic dan pesan
- PostgreSQL dapat diakses melalui klien PostgreSQL apa saja
- Periksa log container untuk debugging: `docker-compose logs [service]`

## 🎯 Langkah Selanjutnya
1. **Skala pipeline**: Tambahkan transformasi yang lebih kompleks
2. **Pemrosesan real-time**: Implementasikan consumer Kafka untuk data streaming
3. **Monitoring**: Tambahkan pengumpulan log dan metrik
4. **Kualitas data**: Implementasikan validasi dan penanganan kesalahan
5. **Otomatisasi**: Siapkan pipeline CI/CD untuk deployment

### Perintah Referensi Cepat
```bash
# Mulai layanan
docker-compose up -d
# Hentikan layanan
docker-compose down
# Hapus semuanya (termasuk volume)
docker-compose down -v
# Lihat log
docker-compose logs -f [nama-layanan]
# Periksa kesehatan layanan
docker-compose ps
```
