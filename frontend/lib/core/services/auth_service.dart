import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthService extends ChangeNotifier {
  final ApiService _api;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _errorMessage;
  bool _loading = false;

  AuthService(this._api);

  AuthStatus get status  => _status;
  UserModel?  get user   => _user;
  String?     get error  => _errorMessage;
  bool        get loading => _loading;
  bool        get isAuthenticated => _status == AuthStatus.authenticated;

  // Chamado no startup — verifica se há token salvo
  Future<void> tryRestoreSession() async {
    final token = await _api.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final data = await _api.getMe();
      _user   = UserModel.fromJson(data);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await _api.clearToken();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final data  = await _api.login(email, password);
      final token = data['token'] as String;
      await _api.saveToken(token);
      _user   = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String displayName,
    required String password,
  }) async {
    _setLoading(true);
    try {
      final data  = await _api.register(username: username, email: email, displayName: displayName, password: password);
      final token = data['token'] as String;
      if (token.isNotEmpty) {
        await _api.saveToken(token);
        _user   = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
      } else {
        // Email precisa de confirmação
        _status = AuthStatus.unauthenticated;
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginDemo() async {
    _setLoading(true);
    try {
      final data  = await _api.loginDemo();
      final token = data['token'] as String;
      await _api.saveToken(token);
      _user   = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on DioException catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user   = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Atualiza o perfil do usuário logado
  Future<void> refreshUser() async {
    try {
      final data = await _api.getMe();
      _user = UserModel.fromJson(data);
      notifyListeners();
    } catch (_) {}
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map) return data['error'] as String? ?? 'Erro desconhecido';
    return 'Erro de conexão. Verifique sua internet.';
  }
}
