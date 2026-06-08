import 'dart:io';
import 'dart:convert';
import 'package:postgres/postgres.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Connection? _connection;

  Future<Connection> get connection async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }
    _connection = await _initConnection();
    return _connection!;
  }

  Future<Connection> _initConnection() async {
    final urlStr = dotenv.env['DATABASE_URL'];
    if (urlStr == null) {
      throw Exception('DATABASE_URL not found in .env');
    }
    
    final uri = Uri.parse(urlStr);
    final userInfo = uri.userInfo.split(':');
    final username = userInfo.isNotEmpty ? userInfo[0] : '';
    final password = userInfo.length > 1 ? userInfo[1] : '';
    
    final conn = await Connection.open(
      Endpoint(
        host: uri.host,
        port: uri.hasPort ? uri.port : 5432,
        database: uri.pathSegments.isNotEmpty ? uri.pathSegments.first : 'neondb',
        username: username,
        password: password,
      ),
      settings: ConnectionSettings(
        sslMode: (uri.queryParameters['sslmode'] == 'req' || uri.queryParameters['sslmode'] == 'require')
            ? SslMode.require 
            : SslMode.disable,
        connectTimeout: const Duration(seconds: 45), // Beri waktu lebih untuk Neon DB 'wake up'
        queryTimeout: const Duration(seconds: 45),
      ),
    );

    // Initialize table
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS report_images (
        id SERIAL PRIMARY KEY,
        report_id VARCHAR(255) NOT NULL,
        image_data TEXT NOT NULL
      )
    ''');
    
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS user_profiles (
        user_id VARCHAR(255) PRIMARY KEY,
        profile_picture TEXT NOT NULL
      )
    ''');
    
    await conn.execute('''
      CREATE TABLE IF NOT EXISTS resolved_images (
        id SERIAL PRIMARY KEY,
        report_id VARCHAR(255) NOT NULL,
        image_data TEXT NOT NULL
      )
    ''');
    
    return conn;
  }

  Future<void> uploadImages(String reportId, List<File> photos) async {
    if (photos.isEmpty) return;
    try {
      final conn = await connection;
      
      for (var photo in photos) {
        final bytes = await photo.readAsBytes();
        final base64String = base64Encode(bytes);
        
        await conn.execute(
          Sql.named('INSERT INTO report_images (report_id, image_data) VALUES (@reportId, @imageData)'),
          parameters: {
            'reportId': reportId,
            'imageData': base64String,
          },
        );
      }
    } catch (e) {
      debugPrint('Error uploading images to Neon: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchImages(String reportId) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named('SELECT image_data FROM report_images WHERE report_id = @reportId ORDER BY id ASC'),
        parameters: {'reportId': reportId},
      );
      
      List<String> images = [];
      for (final row in result) {
        images.add(row[0] as String);
      }
      return images;
    } catch (e) {
      debugPrint('Error fetching images from Neon: $e');
      return [];
    }
  }

  Future<void> uploadProfilePicture(String userId, File photo) async {
    try {
      final conn = await connection;
      final bytes = await photo.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // Upsert (Insert or Update)
      await conn.execute(
        Sql.named('''
          INSERT INTO user_profiles (user_id, profile_picture) 
          VALUES (@userId, @imageData) 
          ON CONFLICT (user_id) DO UPDATE 
          SET profile_picture = EXCLUDED.profile_picture
        '''),
        parameters: {
          'userId': userId,
          'imageData': base64String,
        },
      );
    } catch (e) {
      debugPrint('Error uploading profile picture to Neon: $e');
      rethrow;
    }
  }

  Future<String?> fetchProfilePicture(String userId) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named('SELECT profile_picture FROM user_profiles WHERE user_id = @userId'),
        parameters: {'userId': userId},
      );
      
      if (result.isEmpty) return null;
      return result.first[0] as String;
    } catch (e) {
      debugPrint('Error fetching profile picture from Neon: $e');
      return null;
    }
  }

  Future<void> uploadResolvedImages(String reportId, List<File> photos) async {
    if (photos.isEmpty) return;
    try {
      final conn = await connection;
      
      for (var photo in photos) {
        final bytes = await photo.readAsBytes();
        final base64String = base64Encode(bytes);
        
        await conn.execute(
          Sql.named('INSERT INTO resolved_images (report_id, image_data) VALUES (@reportId, @imageData)'),
          parameters: {
            'reportId': reportId,
            'imageData': base64String,
          },
        );
      }
    } catch (e) {
      debugPrint('Error uploading resolved images to Neon: $e');
      rethrow;
    }
  }

  Future<List<String>> fetchResolvedImages(String reportId) async {
    try {
      final conn = await connection;
      final result = await conn.execute(
        Sql.named('SELECT image_data FROM resolved_images WHERE report_id = @reportId ORDER BY id ASC'),
        parameters: {'reportId': reportId},
      );
      
      List<String> images = [];
      for (final row in result) {
        images.add(row[0] as String);
      }
      return images;
    } catch (e) {
      debugPrint('Error fetching resolved images from Neon: $e');
      return [];
    }
  }
}
