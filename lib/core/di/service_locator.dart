import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../network/dio_client.dart';
import '../network/network_info.dart';

// Auth
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_mock_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/sign_up_usecase.dart';
import '../../features/auth/domain/usecases/other_auth_usecases.dart';

// Map / Business
import '../../features/map/data/datasources/business_remote_datasource.dart';
import '../../features/map/data/datasources/business_mock_datasource.dart';
import '../../features/map/data/datasources/business_local_datasource.dart';
import '../../features/map/data/repositories/business_repository_impl.dart';
import '../../features/map/domain/repositories/business_repository.dart';
import '../../features/map/domain/usecases/business_usecases.dart';

// Categories
import '../../features/categories/data/datasources/category_remote_datasource.dart';
import '../../features/categories/data/datasources/category_mock_datasource.dart';
import '../../features/categories/data/repositories/category_repository_impl.dart';
import '../../features/categories/domain/repositories/category_repository.dart';
import '../../features/categories/domain/usecases/get_categories_usecase.dart';

// Events
import '../../features/events/data/datasources/event_remote_datasource.dart';
import '../../features/events/data/datasources/event_mock_datasource.dart';
import '../../features/events/data/repositories/event_repository_impl.dart';
import '../../features/events/domain/repositories/event_repository.dart';
import '../../features/events/domain/usecases/event_usecases.dart';

// Notifications (broadcast)
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/datasources/notification_mock_datasource.dart';
import '../../features/notifications/data/repositories/notification_repository_impl.dart';
import '../../features/notifications/domain/repositories/notification_repository.dart';
import '../../features/notifications/domain/usecases/broadcast_notification_usecase.dart';

// Dashboard / Analytics
import '../../features/dashboard/data/datasources/analytics_remote_datasource.dart';
import '../../features/dashboard/data/datasources/analytics_mock_datasource.dart';
import '../../features/dashboard/data/repositories/analytics_repository_impl.dart';
import '../../features/dashboard/domain/repositories/analytics_repository.dart';
import '../../features/dashboard/domain/usecases/analytics_usecases.dart';

// Favorites
import '../../features/favorites/data/datasources/favorites_local_datasource.dart';
import '../../features/favorites/data/datasources/favorites_remote_datasource.dart';
import '../../features/favorites/data/repositories/favorites_repository_impl.dart';
import '../../features/favorites/domain/repositories/favorites_repository.dart';
import '../../features/favorites/domain/usecases/favorites_usecases.dart';

final GetIt sl = GetIt.instance;

/// Registers every dependency exactly once at app startup.
/// Called from main() before runApp(). Using GetIt (rather than
/// scattering Riverpod Provider factories) keeps the data/domain layers
/// framework-agnostic — Riverpod providers just read from `sl`.
Future<void> initServiceLocator() async {
  // ---------------- External / Core ----------------
  sl.registerLazySingleton<FlutterSecureStorage>(() => const FlutterSecureStorage());
  sl.registerLazySingleton<Connectivity>(() => Connectivity());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<DioClient>(() => DioClient(sl()));

  await Hive.initFlutter();
  final Box<String> userBox = await Hive.openBox<String>(AppConstants.userBox);
  final Box<String> businessCacheBox =
      await Hive.openBox<String>(AppConstants.businessCacheBox);
  final Box<String> favoritesBox = await Hive.openBox<String>(AppConstants.favoritesBox);
  sl.registerLazySingleton<Box<String>>(() => userBox, instanceName: AppConstants.userBox);
  sl.registerLazySingleton<Box<String>>(
    () => businessCacheBox,
    instanceName: AppConstants.businessCacheBox,
  );
  sl.registerLazySingleton<Box<String>>(
    () => favoritesBox,
    instanceName: AppConstants.favoritesBox,
  );

  // ---------------- Auth ----------------
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AppConstants.useMockData
        ? AuthMockDataSource(sl())
        : AuthRemoteDataSourceImpl(sl<DioClient>().dio, sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl(instanceName: AppConstants.userBox), sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));
  sl.registerLazySingleton(() => ContinueAsGuestUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ChangePasswordUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));

  // ---------------- Map / Business ----------------
  sl.registerLazySingleton<BusinessRemoteDataSource>(
    () => AppConstants.useMockData
        ? BusinessMockDataSource()
        : BusinessRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<BusinessLocalDataSource>(
    () => BusinessLocalDataSourceImpl(sl(instanceName: AppConstants.businessCacheBox)),
  );
  sl.registerLazySingleton<BusinessRepository>(
    () => BusinessRepositoryImpl(remoteDataSource: sl(), localDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetBusinessesUseCase(sl()));
  sl.registerLazySingleton(() => GetBusinessDetailsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitBusinessUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBusinessUseCase(sl()));
  sl.registerLazySingleton(() => SearchBusinessesUseCase(sl()));
  sl.registerLazySingleton(() => GetMyBusinessesUseCase(sl()));
  sl.registerLazySingleton(() => UploadLogoUseCase(sl()));

  // ---------------- Categories ----------------
  sl.registerLazySingleton<CategoryDataSource>(
    () => AppConstants.useMockData
        ? CategoryMockDataSource()
        : CategoryRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<CategoryRepository>(
    () => CategoryRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));

  // ---------------- Dashboard / Analytics ----------------
  sl.registerLazySingleton<AnalyticsDataSource>(
    () => AppConstants.useMockData
        ? AnalyticsMockDataSource()
        : AnalyticsRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(dataSource: sl()),
  );
  sl.registerLazySingleton(() => GetBusinessAnalyticsUseCase(sl()));
  sl.registerLazySingleton(() => RecordAnalyticsEventUseCase(sl()));

  // ---------------- Events ----------------
  sl.registerLazySingleton<EventRemoteDataSource>(
    () => AppConstants.useMockData
        ? EventMockDataSource()
        : EventRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetEventsUseCase(sl()));
  sl.registerLazySingleton(() => CreateEventUseCase(sl()));
  sl.registerLazySingleton(() => UploadEventImageUseCase(sl()));

  // ---------------- Notifications (broadcast) ----------------
  sl.registerLazySingleton<NotificationRemoteDataSource>(
    () => AppConstants.useMockData
        ? NotificationMockDataSource()
        : NotificationRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => BroadcastNotificationUseCase(sl()));

  // ---------------- Favorites ----------------
  sl.registerLazySingleton<FavoritesLocalDataSource>(
    () => FavoritesLocalDataSourceImpl(sl(instanceName: AppConstants.favoritesBox)),
  );
  sl.registerLazySingleton<FavoritesRemoteDataSource>(
    () => FavoritesRemoteDataSourceImpl(sl<DioClient>().dio),
  );
  sl.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(localDataSource: sl(), remoteDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => ToggleFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => GetFavoritesUseCase(sl()));
}
