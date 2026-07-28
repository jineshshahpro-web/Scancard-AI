import 'package:mocktail/mocktail.dart';
import 'package:scancard_ai/core/network/network_info.dart';
import 'package:scancard_ai/features/ai_parsing/domain/repositories/ai_parsing_repository.dart';
import 'package:scancard_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:scancard_ai/features/contacts/data/datasources/contact_local_datasource.dart';
import 'package:scancard_ai/features/contacts/data/datasources/contact_remote_datasource.dart';
import 'package:scancard_ai/features/contacts/data/models/contact_model.dart';
import 'package:scancard_ai/features/contacts/domain/entities/contact_entity.dart';

/// Central place for every mock class + fallback-value registration
/// used across the test suite, so individual test files stay focused
/// on behavior instead of mocktail plumbing.
class MockAuthRepository extends Mock implements AuthRepository {}

class MockContactLocalDataSource extends Mock implements ContactLocalDataSource {}

class MockContactRemoteDataSource extends Mock implements ContactRemoteDataSource {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockAiParsingRepository extends Mock implements AiParsingRepository {}

final DateTime kFixedNow = DateTime(2026, 1, 1, 12);

ContactModel fakeContactModel({
  String id = 'contact-1',
  String ownerId = 'owner-1',
  String fullName = 'Test Contact',
  bool isSyncedToCloud = false,
}) {
  return ContactModel(
    id: id,
    ownerId: ownerId,
    fullName: fullName,
    createdAt: kFixedNow,
    updatedAt: kFixedNow,
    isSyncedToCloud: isSyncedToCloud,
  );
}

void registerFallbackValues() {
  registerFallbackValue(fakeContactModel());
  registerFallbackValue(
    ContactEntity(
      id: 'fallback',
      ownerId: 'fallback-owner',
      fullName: 'Fallback',
      createdAt: kFixedNow,
      updatedAt: kFixedNow,
    ),
  );
}
