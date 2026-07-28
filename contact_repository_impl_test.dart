import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scancard_ai/core/error/exceptions.dart';
import 'package:scancard_ai/features/contacts/data/models/contact_model.dart';
import 'package:scancard_ai/features/contacts/data/repositories/contact_repository_impl.dart';
import 'package:scancard_ai/features/contacts/domain/entities/contact_entity.dart';

import '../../../../helpers/mocks.dart';

void main() {
  setUpAll(registerFallbackValues);

  late MockContactLocalDataSource local;
  late MockContactRemoteDataSource remote;
  late MockNetworkInfo networkInfo;
  late ContactRepositoryImpl repository;

  setUp(() {
    local = MockContactLocalDataSource();
    remote = MockContactRemoteDataSource();
    networkInfo = MockNetworkInfo();
    repository = ContactRepositoryImpl(local: local, remote: remote, networkInfo: networkInfo);

    when(() => local.upsert(any())).thenAnswer((_) async {});
    when(() => local.markSynced(any())).thenAnswer((_) async {});
    when(() => local.softDelete(any())).thenAnswer((_) async {});
    when(() => local.hardDelete(any())).thenAnswer((_) async {});
    when(() => remote.upsertContact(any())).thenAnswer((_) async {});
    when(() => remote.deleteContact(any())).thenAnswer((_) async {});
  });

  group('watchContacts', () {
    test('reads straight from the local cache (offline-first)', () {
      final rows = [fakeContactModel(id: 'a'), fakeContactModel(id: 'b')];
      when(() => local.watchAll('owner-1')).thenAnswer((_) => Stream.value(rows));

      expect(repository.watchContacts('owner-1'), emits(rows));
      verifyNever(() => remote.getContact(any()));
    });
  });

  group('saveContact', () {
    final contact = fakeContactModel(id: 'c1');

    test('when online: writes locally, pushes to remote, and marks synced', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);

      final result = await repository.saveContact(contact);

      expect(result.isRight(), isTrue);
      verify(() => local.upsert(any())).called(1);
      verify(() => remote.upsertContact(any())).called(1);
      verify(() => local.markSynced(contact.id)).called(1);
    });

    test('when offline: writes locally only, never touches remote', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.saveContact(contact);

      expect(result.isRight(), isTrue);
      verify(() => local.upsert(any())).called(1);
      verifyNever(() => remote.upsertContact(any()));
    });

    test('local save still succeeds even if the remote push throws', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => remote.upsertContact(any())).thenThrow(const ServerException('down'));

      final result = await repository.saveContact(contact);

      // The contact is safely on-device; sync will retry later via
      // syncPendingChanges — a mid-flight server error must not lose
      // the user's just-scanned contact.
      expect(result.isRight(), isTrue);
      verify(() => local.upsert(any())).called(1);
      verifyNever(() => local.markSynced(any()));
    });
  });

  group('deleteContact', () {
    test('when online: deletes remotely then hard-deletes locally', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);

      final result = await repository.deleteContact('c1');

      expect(result.isRight(), isTrue);
      verify(() => remote.deleteContact('c1')).called(1);
      verify(() => local.hardDelete('c1')).called(1);
      verifyNever(() => local.softDelete(any()));
    });

    test('when offline: soft-deletes locally, leaving it queued for sync', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.deleteContact('c1');

      expect(result.isRight(), isTrue);
      verify(() => local.softDelete('c1')).called(1);
      verifyNever(() => remote.deleteContact(any()));
    });
  });

  group('toggleFavorite', () {
    test('reads the local contact, flips the flag, and saves it back', () async {
      final existing = fakeContactModel(id: 'c1');
      when(() => local.getById('c1')).thenAnswer((_) async => existing);
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);

      final result = await repository.toggleFavorite('c1', true);

      expect(result.isRight(), isTrue);
      final captured = verify(() => local.upsert(captureAny())).captured.single as ContactModel;
      expect(captured.isFavorite, isTrue);
    });

    test('fails gracefully when the contact does not exist locally', () async {
      when(() => local.getById('missing')).thenAnswer((_) async => null);

      final result = await repository.toggleFavorite('missing', true);

      expect(result.isLeft(), isTrue);
    });
  });

  group('syncPendingChanges', () {
    test('returns a failure early when still offline', () async {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.syncPendingChanges('owner-1');

      expect(result.isLeft(), isTrue);
      verifyNever(() => local.unsynced(any()));
    });

    test('pushes every unsynced contact and marks each as synced', () async {
      final pending = [fakeContactModel(id: '1'), fakeContactModel(id: '2'), fakeContactModel(id: '3')];
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => local.unsynced('owner-1')).thenAnswer((_) async => pending);

      final result = await repository.syncPendingChanges('owner-1');

      expect(result.isRight(), isTrue);
      verify(() => remote.upsertContact(any())).called(3);
      verify(() => local.markSynced(any())).called(3);
    });

    test('one failing contact does not abort syncing the rest', () async {
      final pending = [fakeContactModel(id: '1'), fakeContactModel(id: '2'), fakeContactModel(id: '3')];
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => local.unsynced('owner-1')).thenAnswer((_) async => pending);
      var call = 0;
      when(() => remote.upsertContact(any())).thenAnswer((_) async {
        call++;
        if (call == 2) throw const ServerException('flaky');
      });

      final result = await repository.syncPendingChanges('owner-1');

      expect(result.isRight(), isTrue);
      verify(() => remote.upsertContact(any())).called(3);
      // Only the 2 successful pushes should be marked synced.
      verify(() => local.markSynced(any())).called(2);
    });

    test('stress: syncs a large backlog of offline-created contacts', () async {
      final pending = List.generate(500, (i) => fakeContactModel(id: 'pending-$i'));
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
      when(() => local.unsynced('owner-1')).thenAnswer((_) async => pending);

      final stopwatch = Stopwatch()..start();
      final result = await repository.syncPendingChanges('owner-1');
      stopwatch.stop();

      expect(result.isRight(), isTrue);
      verify(() => remote.upsertContact(any())).called(500);
      verify(() => local.markSynced(any())).called(500);
      // Sanity bound — with mocked instant I/O this should be fast;
      // catches accidental O(n^2) behavior in the sync loop.
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
