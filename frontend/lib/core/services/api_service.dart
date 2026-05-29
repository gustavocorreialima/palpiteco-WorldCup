import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const _baseUrl = 'https://palpiteco-world-cup.vercel.app/api';
  // Para desenvolvimento local, use: 'http://10.0.2.2:3000/api' (Android emulator)
  // ou 'http://localhost:3000/api' (web/desktop)

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  Future<void> saveToken(String token) =>
      _storage.write(key: 'auth_token', value: token);

  Future<void> clearToken() => _storage.delete(key: 'auth_token');

  Future<String?> getToken() => _storage.read(key: 'auth_token');

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String displayName,
    required String password,
  }) async {
    final res = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'displayName': displayName,
      'password': password,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> loginDemo() async {
    final res = await _dio.post('/auth/demo');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('/auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    try { await _dio.post('/auth/logout'); } catch (_) {}
    await clearToken();
  }

  // ── Matches ───────────────────────────────────────────────────────────────

  Future<List<dynamic>> getMatches({String? status}) async {
    final res = await _dio.get('/worldcup/matches',
      queryParameters: status != null ? {'status': status} : null,
    );
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getUpcomingMatches() async {
    final res = await _dio.get('/worldcup/matches/upcoming');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getLiveMatches() async {
    final res = await _dio.get('/worldcup/matches/live');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getFinishedMatches() async {
    final res = await _dio.get('/worldcup/matches/finished');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getMatchesByDate(String date) async {
    final res = await _dio.get('/worldcup/matches/by-date',
      queryParameters: {'date': date},
    );
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getGroups() async {
    final res = await _dio.get('/worldcup/groups');
    return res.data as List<dynamic>;
  }

  // ── Bets ──────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getBets() async {
    final res = await _dio.get('/bets');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> submitBet({
    required String matchId,
    required int predictedHome,
    required int predictedAway,
    String? groupId,
  }) async {
    final res = await _dio.post('/bets', data: {
      'matchId': matchId,
      'predictedHome': predictedHome,
      'predictedAway': predictedAway,
      if (groupId != null) 'groupId': groupId,
    });
    return res.data as Map<String, dynamic>;
  }

  // ── Rankings ──────────────────────────────────────────────────────────────

  Future<List<dynamic>> getGlobalRanking() async {
    final res = await _dio.get('/rankings/global');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getRoundRanking() async {
    final res = await _dio.get('/rankings/round');
    return res.data as List<dynamic>;
  }

  // ── Clubs ─────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getClubs() async {
    final res = await _dio.get('/clubs');
    return res.data as List<dynamic>;
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getNotifications() async {
    final res = await _dio.get('/notifications');
    return res.data as List<dynamic>;
  }

  Future<void> markNotificationsRead() async {
    await _dio.post('/notifications/read-all');
  }
}
