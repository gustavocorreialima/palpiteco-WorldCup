import 'package:get_it/get_it.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

final sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton<ApiService>(() => ApiService());
  sl.registerLazySingleton<AuthService>(() => AuthService(sl<ApiService>()));
}
