import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/network_info.dart';
import '../storage/token_storage.dart';
import '../storage/user_storage.dart';

// Auth
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_user.dart';
import '../../features/auth/domain/usecases/logout_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Balance
import '../../features/balance/data/datasources/balance_local_data_source.dart';
import '../../features/balance/data/repositories/balance_repository_impl.dart';
import '../../features/balance/domain/repositories/balance_repository.dart';
import '../../features/balance/domain/usecases/add_balance.dart';
import '../../features/balance/domain/usecases/get_balance.dart';
import '../../features/balance/presentation/cubit/balance_cubit.dart';

// Homework
import '../../features/homework/data/repositories/homework_repository_impl.dart';
import '../../features/homework/data/services/homework_service.dart';
import '../../features/homework/domain/repositories/homework_repository.dart';
import '../../features/homework/domain/usecases/get_homeworks.dart';
import '../../features/homework/presentation/bloc/homework_bloc.dart';

// Attendance
import '../../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../../features/attendance/data/services/attendance_service.dart';
import '../../features/attendance/domain/repositories/attendance_repository.dart';
import '../../features/attendance/domain/usecases/get_attendance.dart';
import '../../features/attendance/presentation/bloc/attendance_bloc.dart';

// Timetable
import '../../features/timetable/data/repositories/timetable_repository_impl.dart';
import '../../features/timetable/data/services/timetable_service.dart';
import '../../features/timetable/domain/repositories/timetable_repository.dart';
import '../../features/timetable/domain/usecases/get_timetable.dart';
import '../../features/timetable/presentation/bloc/timetable_bloc.dart';

// Library
import '../../features/library/data/repositories/library_repository_impl.dart';
import '../../features/library/data/services/library_service.dart';
import '../../features/library/domain/repositories/library_repository.dart';
import '../../features/library/domain/usecases/get_books.dart';
import '../../features/library/presentation/bloc/library_bloc.dart';

// Examination
import '../../features/examination/data/repositories/examination_repository_impl.dart';
import '../../features/examination/data/services/examination_service.dart';
import '../../features/examination/domain/repositories/examination_repository.dart';
import '../../features/examination/domain/usecases/get_examinations.dart';
import '../../features/examination/presentation/bloc/examination_bloc.dart';

// Weekly plan
import '../../features/weekly_plan/data/datasources/weekly_plan_remote_data_source.dart';
import '../../features/weekly_plan/data/repositories/weekly_plan_repository_impl.dart';
import '../../features/weekly_plan/domain/repositories/weekly_plan_repository.dart';
import '../../features/weekly_plan/domain/usecases/get_weekly_plan.dart';
import '../../features/weekly_plan/presentation/cubit/weekly_plan_cubit.dart';

// Notifications
import '../../features/notifications/data/repositories/notifications_repository_impl.dart';
import '../../features/notifications/data/services/notifications_service.dart';
import '../../features/notifications/domain/repositories/notifications_repository.dart';
import '../../features/notifications/domain/usecases/get_notifications.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';

// Buffet
import '../../features/buffet_cart/data/datasources/buffet_remote_data_source.dart';
import '../../features/buffet_cart/data/repositories/buffet_repository_impl.dart';
import '../../features/buffet_cart/domain/repositories/buffet_repository.dart';
import '../../features/buffet_cart/domain/usecases/get_products.dart';
import '../../features/buffet_cart/domain/usecases/place_order.dart';
import '../../features/buffet_cart/presentation/cubit/buffet_cubit.dart';

/// Service locator. Call [initDependencies] once before runApp.
final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- External ----
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  // ---- Core ----
  sl.registerLazySingleton<TokenStorage>(() => TokenStorageImpl(sl()));
  sl.registerLazySingleton<UserStorage>(() => UserStorageImpl(sl()));
  // The single configured Dio (base URL + token interceptor) is shared by
  // every service in the app.
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
  sl.registerLazySingleton<Dio>(() => sl<ApiClient>().dio);
  // A bare Dio, not the app's: the reachability probe hits a third-party host
  // and must not carry the auth interceptor's bearer token there.
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(Dio()));

  _initAuth();
  _initBalance();
  _initHomework();
  _initAttendance();
  _initTimetable();
  _initLibrary();
  _initExamination();
  _initWeeklyPlan();
  _initBuffet();
  _initNotifications();
}

void _initNotifications() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => NotificationsBloc(getNotifications: sl()));

  // Use case
  sl.registerLazySingleton(() => GetNotifications(sl()));

  // Repository
  sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(
            service: sl(),
            authRepository: sl(), // reuses the Auth singleton for `class_id`
          ));

  // Service
  sl.registerLazySingleton<NotificationsService>(
      () => NotificationsServiceImpl(sl()));
}

void _initAuth() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => AuthBloc(
        loginUser: sl(),
        logoutUser: sl(),
        repository: sl(),
      ));

  // Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        service: sl(),
        tokenStorage: sl(),
        userStorage: sl(),
        networkInfo: sl(),
      ));

  // Service
  sl.registerLazySingleton<AuthService>(() => AuthServiceImpl(sl()));
}

void _initBalance() {
  sl.registerFactory(() => BalanceCubit(getBalance: sl(), addBalance: sl()));
  sl.registerLazySingleton(() => GetBalance(sl()));
  sl.registerLazySingleton(() => AddBalance(sl()));
  // Singleton: shared source of truth with the Buffet feature.
  sl.registerLazySingleton<BalanceRepository>(
      () => BalanceRepositoryImpl(sl()));
  sl.registerLazySingleton<BalanceLocalDataSource>(
      () => BalanceLocalDataSourceImpl(sl()));
}

void _initHomework() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => HomeworkBloc(getHomeworks: sl()));

  // Use case
  sl.registerLazySingleton(() => GetHomeworks(sl()));

  // Repository
  sl.registerLazySingleton<HomeworkRepository>(() => HomeworkRepositoryImpl(
        service: sl(),
        authRepository: sl(), // reuses the Auth singleton for `class_id`
      ));

  // Service
  sl.registerLazySingleton<HomeworkService>(() => HomeworkServiceImpl(sl()));
}

void _initAttendance() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => AttendanceBloc(getAttendance: sl()));

  // Use case
  sl.registerLazySingleton(() => GetAttendance(sl()));

  // Repository
  sl.registerLazySingleton<AttendanceRepository>(
      () => AttendanceRepositoryImpl(service: sl()));

  // Service
  sl.registerLazySingleton<AttendanceService>(
      () => AttendanceServiceImpl(sl()));
}

void _initTimetable() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => TimetableBloc(getTimetable: sl()));

  // Use case
  sl.registerLazySingleton(() => GetTimetable(sl()));

  // Repository
  sl.registerLazySingleton<TimetableRepository>(() => TimetableRepositoryImpl(
        service: sl(),
        authRepository: sl(), // reuses the Auth singleton for `class_id`
      ));

  // Service
  sl.registerLazySingleton<TimetableService>(
      () => TimetableServiceImpl(sl()));
}

void _initLibrary() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => LibraryBloc(getBooks: sl()));

  // Use case
  sl.registerLazySingleton(() => GetBooks(sl()));

  // Repository
  sl.registerLazySingleton<LibraryRepository>(() => LibraryRepositoryImpl(
        service: sl(),
        authRepository: sl(), // reuses the Auth singleton for `class_id`
      ));

  // Service
  sl.registerLazySingleton<LibraryService>(() => LibraryServiceImpl(sl()));
}

void _initExamination() {
  // Bloc — new instance per screen mount.
  sl.registerFactory(() => ExaminationBloc(getExaminations: sl()));

  // Use case
  sl.registerLazySingleton(() => GetExaminations(sl()));

  // Repository
  sl.registerLazySingleton<ExaminationRepository>(
      () => ExaminationRepositoryImpl(service: sl()));

  // Service
  sl.registerLazySingleton<ExaminationService>(
      () => ExaminationServiceImpl(sl()));
}

void _initWeeklyPlan() {
  sl.registerFactory(() => WeeklyPlanCubit(getWeeklyPlan: sl()));
  sl.registerLazySingleton(() => GetWeeklyPlan(sl()));
  sl.registerLazySingleton<WeeklyPlanRepository>(
      () => WeeklyPlanRepositoryImpl(sl()));
  sl.registerLazySingleton<WeeklyPlanRemoteDataSource>(
      () => WeeklyPlanRemoteDataSourceMock());
}

void _initBuffet() {
  sl.registerFactory(() => BuffetCubit(getProducts: sl(), placeOrder: sl()));
  sl.registerLazySingleton(() => GetProducts(sl()));
  sl.registerLazySingleton(() => PlaceOrder(sl()));
  sl.registerLazySingleton<BuffetRepository>(() => BuffetRepositoryImpl(
        remoteDataSource: sl(),
        balanceRepository: sl(), // reuses the Balance singleton
      ));
  sl.registerLazySingleton<BuffetRemoteDataSource>(
      () => BuffetRemoteDataSourceMock());
}
