import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scancard_ai/core/error/failures.dart';
import 'package:scancard_ai/features/auth/domain/entities/user_entity.dart';
import 'package:scancard_ai/features/auth/presentation/providers/auth_providers.dart';

import '../../../../helpers/mocks.dart';

const _user = UserEntity(id: 'u1', email: 'jane@example.com', displayName: 'Jane');

void main() {
  late MockAuthRepository authRepository;
  late ProviderContainer container;

  setUp(() {
    authRepository = MockAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
    addTearDown(container.dispose);
  });

  test('signIn success sets AsyncData and returns true', () async {
    when(() => authRepository.signInWithEmail(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Right(_user));

    final controller = container.read(authControllerProvider.notifier);
    final ok = await controller.signIn('jane@example.com', 'password123');

    expect(ok, isTrue);
    expect(container.read(authControllerProvider), const AsyncData<void>(null));
  });

  test('signIn failure sets AsyncError and returns false', () async {
    when(() => authRepository.signInWithEmail(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Left(AuthFailure('Incorrect email or password.')));

    final controller = container.read(authControllerProvider.notifier);
    final ok = await controller.signIn('jane@example.com', 'wrong');

    expect(ok, isFalse);
    expect(container.read(authControllerProvider).hasError, isTrue);
    expect(container.read(authControllerProvider).error, 'Incorrect email or password.');
  });

  test('signUp forwards all three fields to the repository', () async {
    when(() => authRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => const Right(_user));

    final controller = container.read(authControllerProvider.notifier);
    final ok = await controller.signUp('jane@example.com', 'password123', 'Jane Doe');

    expect(ok, isTrue);
    verify(() => authRepository.signUpWithEmail(
          email: 'jane@example.com',
          password: 'password123',
          displayName: 'Jane Doe',
        )).called(1);
  });

  test('signOut propagates a failure into AsyncError state', () async {
    when(() => authRepository.signOut())
        .thenAnswer((_) async => const Left(AuthFailure('Sign-out failed.')));

    final controller = container.read(authControllerProvider.notifier);
    await controller.signOut();

    expect(container.read(authControllerProvider).hasError, isTrue);
  });

  test('sendPasswordReset returns true on success', () async {
    when(() => authRepository.sendPasswordResetEmail(any())).thenAnswer((_) async => const Right(null));

    final controller = container.read(authControllerProvider.notifier);
    final ok = await controller.sendPasswordReset('jane@example.com');

    expect(ok, isTrue);
  });
}
