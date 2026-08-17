import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/auth/controllers/registration_controller.dart';
import 'package:doce_equilibrio/features/auth/controllers/login_controller.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';
import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/activity/controllers/activity_controller.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository_interface.dart';
import 'package:doce_equilibrio/features/food/controllers/food_controller.dart';
import 'package:doce_equilibrio/features/food/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:doce_equilibrio/features/food/repositories/meal_repository_interface.dart';
import 'package:doce_equilibrio/features/food/repositories/meal_repository.dart';
import 'package:doce_equilibrio/features/home/controllers/home_controller.dart';
import 'package:doce_equilibrio/features/medication/controllers/medication_controller.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository_interface.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository.dart';
import 'package:doce_equilibrio/features/reminders/controllers/reminder_controller.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository.dart';
import 'package:doce_equilibrio/features/settings/controllers/profile_controller.dart';
import 'package:get_it/get_it.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<DatabaseConnection>(() => DatabaseConnection());
  getIt.registerLazySingleton<SessionService>(
    () => SecureStorageSessionService(),
  );

  getIt.registerLazySingleton<UserRepositoryInterface>(
    () => UserRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<GlycemiaRepositoryInterface>(
    () => GlycemiaRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<ReminderRepositoryInterface>(
    () => ReminderRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<FoodRepositoryInterface>(
    () => FoodRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<MealRepositoryInterface>(
    () => MealRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<MedicationRepositoryInterface>(
    () => MedicationRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<ActivityRepositoryInterface>(
    () => ActivityRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  getIt.registerFactory<LoginController>(
    () => LoginController(
      getIt<UserRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<RegistrationController>(
    () => RegistrationController(
      getIt<UserRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<HomeController>(
    () => HomeController(
      getIt<UserRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<GlycemiaController>(
    () => GlycemiaController(
      getIt<GlycemiaRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<ProfileController>(
    () => ProfileController(
      getIt<UserRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<ReminderController>(
    () => ReminderController(
      getIt<ReminderRepositoryInterface>(),
      getIt<NotificationService>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<FoodController>(
    () => FoodController(
      getIt<FoodRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<MealController>(
    () => MealController(
      getIt<MealRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<MedicationController>(
    () => MedicationController(
      getIt<MedicationRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<ActivityController>(
    () => ActivityController(
      getIt<ActivityRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
}
