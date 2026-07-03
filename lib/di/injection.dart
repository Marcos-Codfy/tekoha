// lib/di/injection.dart
// Camada: Composition Root.
//
// Configura o `GetIt` (service locator) com TODAS as dependencias do app.
// E o UNICO arquivo que sabe "como construir" as classes — em todo o
// resto do codigo voce so pede `sl<MeuServico>()` e recebe a instancia.
//
// REGRAS DE OURO:
//   1. Nenhum arquivo de fora deste import `package:get_it/get_it.dart`.
//      Quem quiser uma instancia importa daqui (`sl`).
//   2. Sempre registre pelo TIPO ABSTRATO quando existir contrato
//      (`sl.registerLazySingleton<ContentRepository>(() => Impl())`).
//      Isso permite trocar a impl em testes sem mexer no codigo.
//   3. `LazySingleton` = construido SO QUANDO chamado pela primeira vez.
//      Use por padrao. `Singleton` = construido ja no setup. Use so se
//      precisar do efeito colateral imediato (ex.: listener do Firebase).
//   4. `Factory` = nova instancia toda vez. Use pra Providers ou objetos
//      com estado por tela.
//
// REGISTRO E POR FEATURE — cada `_registerXxx()` agrupa as dependencias
// daquela feature. Adicionar uma feature nova = criar funcao + chamar
// em `setupDependencies()`.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../core/network/airtable_client.dart';
import '../core/services/audio_player_service.dart';
import '../core/services/speech_service.dart';
import '../features/achievements/data/datasources/achievements_remote_datasource.dart';
import '../features/achievements/data/repositories/achievements_repository_impl.dart';
import '../features/achievements/domain/repositories/achievements_repository.dart';
import '../features/achievements/domain/usecases/get_achievements.dart';
import '../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/register.dart';
import '../features/auth/domain/usecases/sign_in.dart';
import '../features/auth/domain/usecases/sign_out.dart';
import '../features/culture/data/datasources/culture_remote_datasource.dart';
import '../features/culture/data/repositories/culture_repository_impl.dart';
import '../features/culture/domain/repositories/culture_repository.dart';
import '../features/culture/domain/usecases/get_culture_content.dart';
import '../features/lesson/data/datasources/lesson_remote_datasource.dart';
import '../features/lesson/data/repositories/lesson_repository_impl.dart';
import '../features/lesson/domain/repositories/lesson_repository.dart';
import '../features/lesson/domain/usecases/get_lessons_by_module.dart';
import '../features/lesson/domain/usecases/get_words_by_lesson.dart';
import '../features/practice/data/datasources/practice_remote_datasource.dart';
import '../features/practice/data/repositories/practice_repository_impl.dart';
import '../features/practice/domain/repositories/practice_repository.dart';
import '../features/practice/domain/usecases/get_modules.dart';
import '../features/progress/data/datasources/firestore_progress_datasource.dart';
import '../features/progress/data/repositories/user_progress_repository_impl.dart';
import '../features/progress/domain/repositories/user_progress_repository.dart';

/// Apelido global pra encurtar `GetIt.instance.<X>()` em `sl<X>()`.
/// "sl" = "service locator".
final GetIt sl = GetIt.instance;

/// Inicializa todas as dependencias. Chamar UMA VEZ em `main()` depois
/// do `dotenv.load` e antes do `runApp`.
Future<void> setupDependencies() async {
  _registerCore();
  _registerAudioAndSpeech();
  _registerPractice();
  _registerLesson();
  _registerCulture();
  _registerAuth();
  _registerProgress();
  _registerAchievements();
}

// ── Feature: Practice ─────────────────────────────────────────────────

void _registerPractice() {
  // DataSource (mais baixo): conhece o AirtableClient.
  sl.registerLazySingleton<PracticeRemoteDataSource>(
    () => PracticeRemoteDataSourceImpl(sl<AirtableClient>()),
  );

  // Repository (contrato + impl): conhece o DataSource.
  sl.registerLazySingleton<PracticeRepository>(
    () => PracticeRepositoryImpl(sl<PracticeRemoteDataSource>()),
  );

  // UseCase: conhece o Repository.
  sl.registerLazySingleton<GetModulesUseCase>(
    () => GetModulesUseCase(sl<PracticeRepository>()),
  );
}

// ── Feature: Achievements (ESP-006 — definicoes vem do Airtable) ──────

void _registerAchievements() {
  sl.registerLazySingleton<AchievementsRemoteDataSource>(
    () => AchievementsRemoteDataSourceImpl(sl<AirtableClient>()),
  );

  sl.registerLazySingleton<AchievementsRepository>(
    () => AchievementsRepositoryImpl(sl<AchievementsRemoteDataSource>()),
  );

  sl.registerLazySingleton<GetAchievementsUseCase>(
    () => GetAchievementsUseCase(sl<AchievementsRepository>()),
  );
}

// ── Feature: Progress (ESP-006 — persistencia ATIVA via Firestore) ────

void _registerProgress() {
  sl.registerLazySingleton<FirestoreProgressDataSource>(
    () => FirestoreProgressDataSource(FirebaseFirestore.instance),
  );

  sl.registerLazySingleton<UserProgressRepository>(
    () => UserProgressRepositoryImpl(sl<FirestoreProgressDataSource>()),
  );
}

// ── Feature: Lesson ───────────────────────────────────────────────────

void _registerLesson() {
  sl.registerLazySingleton<LessonRemoteDataSource>(
    () => LessonRemoteDataSourceImpl(sl<AirtableClient>()),
  );

  sl.registerLazySingleton<LessonRepository>(
    () => LessonRepositoryImpl(sl<LessonRemoteDataSource>()),
  );

  sl.registerLazySingleton<GetLessonsByModuleUseCase>(
    () => GetLessonsByModuleUseCase(sl<LessonRepository>()),
  );

  sl.registerLazySingleton<GetWordsByLessonUseCase>(
    () => GetWordsByLessonUseCase(sl<LessonRepository>()),
  );
}

// ── Feature: Culture ──────────────────────────────────────────────────

void _registerCulture() {
  sl.registerLazySingleton<CultureRemoteDataSource>(
    () => CultureRemoteDataSourceImpl(sl<AirtableClient>()),
  );

  sl.registerLazySingleton<CultureRepository>(
    () => CultureRepositoryImpl(sl<CultureRemoteDataSource>()),
  );

  sl.registerLazySingleton<GetCultureContentUseCase>(
    () => GetCultureContentUseCase(sl<CultureRepository>()),
  );
}

// ── Feature: Auth ─────────────────────────────────────────────────────

void _registerAuth() {
  sl.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSourceImpl(),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<FirebaseAuthDataSource>()),
  );

  sl.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(sl<AuthRepository>()),
  );

  sl.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(sl<AuthRepository>()),
  );
}

// ── Core ──────────────────────────────────────────────────────────────

void _registerCore() {
  // HTTP client global. Mantemos UM unico cliente pra reaproveitar
  // socket pool entre features.
  sl.registerLazySingleton<http.Client>(() => http.Client());

  // Cliente Airtable. Le credenciais do .env UMA vez no registro.
  // Se as chaves estiverem ausentes, o proprio AirtableClient devolve
  // ConfigFailure na primeira chamada — nao explode aqui.
  sl.registerLazySingleton<AirtableClient>(() => AirtableClient(
        apiKey: dotenv.env['AIRTABLE_API_KEY'] ?? '',
        baseId: dotenv.env['AIRTABLE_BASE_ID'] ?? '',
        httpClient: sl<http.Client>(),
      ));
}

// ── Audio + Speech (servicos com estado, por isso singleton) ──────────

void _registerAudioAndSpeech() {
  // Mantemos uma instancia unica pelo ciclo de vida do app porque:
  //   - AudioPlayer guarda cache de paths em memoria
  //   - SpeechService inicializa motor de voz (permissao + handle nativo)
  // Trocar entre telas perderia esse estado.
  //
  // Usamos `.instance` (construtor privado existente) durante a migracao
  // pra que codigo antigo (que ainda faz `AudioPlayerService.instance`)
  // compartilhe a MESMA instancia que `sl<AudioPlayerService>()`. Apos a
  // limpeza final podemos abrir o construtor e remover o singleton.
  sl.registerLazySingleton<AudioPlayerService>(() => AudioPlayerService.instance);
  sl.registerLazySingleton<SpeechService>(() => SpeechService.instance);
}

/// Limpa o registry (util em testes — `setUp(() => sl.reset())`).
Future<void> resetDependencies() => sl.reset();
