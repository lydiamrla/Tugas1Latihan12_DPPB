import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Import core & data
import 'core/app_router.dart';
import 'core/dio_client.dart';
import 'mvc/auth/bloc/auth_bloc.dart';
import 'mvc/auth/data/auth_repository.dart';
import 'mvc/auth/data/auth_storage.dart';
import 'mvc/posts/bloc/post_bloc.dart';
import 'mvc/posts/data/post_repository.dart';

// Import UI Pages (Pastikan path sesuai dengan folder Anda)
import 'mvc/auth/view/login_page.dart';
import 'mvc/auth/view/register_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Mengizinkan pemuatan gambar dari server lokal (IP Address)
  HttpOverrides.global = CustomHttpOverrides();

  // Pastikan IP ini sesuai dengan IP server Laravel Anda
  const baseUrl = 'http://10.52.194.95:8000/api';

  final authStorage = AuthStorage();
  final token = await authStorage.getToken();

  final dioClient = DioClient(baseUrl: baseUrl, token: token);

  final authRepository = AuthRepository(dioClient);
  final postRepository = PostRepository(dioClient);

  final appRouter = AppRouter(
    authRepository: authRepository,
    authStorage: authStorage,
    postRepository: postRepository,
  );

  runApp(
    MyApp(
      appRouter: appRouter,
      authRepository: authRepository,
      authStorage: authStorage,
      postRepository: postRepository,
      dioClient: dioClient,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.appRouter,
    required this.authRepository,
    required this.authStorage,
    required this.postRepository,
    required this.dioClient,
  });

  final AppRouter appRouter;
  final AuthRepository authRepository;
  final AuthStorage authStorage;
  final PostRepository postRepository;
  final DioClient dioClient;

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: authStorage),
        RepositoryProvider.value(value: postRepository),
        RepositoryProvider.value(value: dioClient),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(
              authRepository: authRepository,
              authStorage: authStorage,
            )..add(const AuthCheckRequested()),
          ),
          BlocProvider(create: (_) => PostBloc(postRepository)),
        ],
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) async {
            /// ================= AUTHENTICATED =================
            if (state.status == AuthStatus.authenticated) {
              final token = await authStorage.getToken();
              if (token != null) {
                dioClient.updateToken(token);
              }

              final msg = state.message ?? 'Login berhasil';
              scaffoldMessengerKey.currentState
                ?..removeCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green[600],
                  ),
                );

              Future.microtask(() {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/posts', // Ke Halaman Utama
                  (route) => false,
                );
              });
            }

            /// ================= UNAUTHENTICATED =================
            if (state.status == AuthStatus.unauthenticated) {
              dioClient.clearToken();

              if (state.message != null && state.message!.isNotEmpty) {
                scaffoldMessengerKey.currentState
                  ?..removeCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(state.message!),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Colors.red[700],
                    ),
                  );
              }

              Future.microtask(() {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/', // Kembali ke Login
                  (route) => false,
                );
              });
            }
          },
          child: MaterialApp(
            title: 'Flutter Laravel API',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
            ),
            onGenerateRoute: appRouter.onGenerateRoute,
            initialRoute: '/',
          ),
        ),
      ),
    );
  }
}

class CustomHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..connectionTimeout = const Duration(seconds: 30)
      ..findProxy = HttpClient.findProxyFromEnvironment;
  }
}
