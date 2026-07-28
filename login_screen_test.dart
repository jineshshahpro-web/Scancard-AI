import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scancard_ai/features/auth/domain/entities/user_entity.dart';
import 'package:scancard_ai/features/auth/presentation/providers/auth_providers.dart';
import 'package:scancard_ai/features/auth/presentation/screens/login_screen.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    // Splash/router-redirect logic elsewhere relies on this stream;
    // the login screen itself only needs it to not throw.
    when(() => authRepository.authStateChanges())
        .thenAnswer((_) => const Stream<UserEntity?>.empty());
  });

  Widget buildApp() {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (_, __) => const Placeholder()),
      GoRoute(path: '/forgot-password', name: 'forgot-password', builder: (_, __) => const Placeholder()),
    ]);
    return ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('shows a validation error when submitting an empty form', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required.'), findsOneWidget);
    expect(find.text('Password is required.'), findsOneWidget);
  });

  testWidgets('flags an invalid email format', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });

  testWidgets('calls signInWithEmail on the repository with valid input', (tester) async {
    when(() => authRepository.signInWithEmail(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Right(UserEntity(id: 'u1', email: 'jane@example.com')));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'jane@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    verify(() => authRepository.signInWithEmail(
          email: 'jane@example.com',
          password: 'password123',
        )).called(1);
  });

  testWidgets('toggling the password visibility icon unmasks the field', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
