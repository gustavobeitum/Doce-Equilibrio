import 'package:doce_equilibrio/core/database/database_connection.dart';
import 'package:doce_equilibrio/features/auth/controllers/registration_controller.dart';
import 'package:doce_equilibrio/features/auth/controllers/login_controller.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository_interface.dart';
import 'package:doce_equilibrio/features/auth/repositories/user_repository.dart';
import 'package:doce_equilibrio/features/charts/controllers/charts_controller.dart';
import 'package:doce_equilibrio/features/glycemia/controllers/glycemia_controller.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository.dart';
import 'package:doce_equilibrio/features/glycemia/repositories/glycemia_repository_interface.dart';
import 'package:doce_equilibrio/core/services/notification_service.dart';
import 'package:doce_equilibrio/core/notifications/notification_scheduler.dart';
import 'package:doce_equilibrio/core/services/session_service.dart';
import 'package:doce_equilibrio/features/activity/controllers/activity_controller.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository.dart';
import 'package:doce_equilibrio/features/activity/repositories/activity_repository_interface.dart';
import 'package:doce_equilibrio/features/food/controllers/food_controller.dart';
import 'package:doce_equilibrio/features/food/navigation/food_library_navigator.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository.dart';
import 'package:doce_equilibrio/features/food/repositories/food_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_controller.dart';
import 'package:doce_equilibrio/features/meals/controllers/meal_food_controller.dart';
import 'package:doce_equilibrio/features/meals/repositories/meal_repository_interface.dart';
import 'package:doce_equilibrio/features/meals/repositories/meal_repository.dart';
import 'package:doce_equilibrio/features/home/controllers/home_controller.dart';
import 'package:doce_equilibrio/features/hba1c/controllers/hba1c_controller.dart';
import 'package:doce_equilibrio/features/insulin/controllers/insulin_application_controller.dart';
import 'package:doce_equilibrio/features/insulin/repositories/insulin_application_repository.dart';
import 'package:doce_equilibrio/features/insulin/repositories/insulin_application_repository_interface.dart';
import 'package:doce_equilibrio/features/medication/controllers/medication_controller.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository_interface.dart';
import 'package:doce_equilibrio/features/medication/repositories/medication_repository.dart';
import 'package:doce_equilibrio/features/reminders/controllers/reminder_controller.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository_interface.dart';
import 'package:doce_equilibrio/features/reminders/repositories/reminder_repository.dart';
import 'package:doce_equilibrio/features/reminders/services/reminder_notification_service.dart';
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

  getIt.registerLazySingleton<FoodLibraryNavigator>(
    () => FlutterFoodLibraryNavigator(),
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

  getIt.registerLazySingleton<InsulinApplicationRepositoryInterface>(
    () => InsulinApplicationRepository(getIt<DatabaseConnection>()),
  );

  getIt.registerLazySingleton<NotificationScheduler>(
    () => LocalNotificationScheduler(),
  );
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(
      getIt<NotificationScheduler>(),
      getIt<ReminderRepositoryInterface>(),
    ),
  );
  getIt.registerLazySingleton<ReminderNotificationService>(
    () => getIt<NotificationService>(),
  );

  getIt.registerFactory<LoginController>(
    () => LoginController(
      getIt<UserRepositoryInterface>(),
      getIt<SessionService>(),
    ),
  );
  getIt.registerFactory<RegistrationController>(
    () => RegistrationController(getIt<UserRepositoryInterface>()),
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
  getIt.registerFactory<ChartsController>(
    () => ChartsController(
      getIt<GlycemiaController>(),
      getIt<ProfileController>(),
    ),
  );
  getIt.registerFactory<HbA1cController>(
    () => HbA1cController(getIt<GlycemiaController>()),
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
      getIt<ReminderNotificationService>(),
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
  getIt.registerFactory<MealFoodController>(
    () => MealFoodController(
      getIt<FoodRepositoryInterface>(),
      getIt<SessionService>(),
      getIt<FoodLibraryNavigator>(),
    ),
  );
  getIt.registerFactory<InsulinApplicationController>(
    () => InsulinApplicationController(
      getIt<InsulinApplicationRepositoryInterface>(),
      getIt<MealRepositoryInterface>(),
      getIt<UserRepositoryInterface>(),
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
