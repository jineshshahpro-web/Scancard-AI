import 'package:flutter_test/flutter_test.dart';
import 'package:scancard_ai/features/contacts/domain/entities/contact_entity.dart';
import 'package:scancard_ai/features/contacts/domain/usecases/search_contacts.dart';

ContactEntity _contact({
  required String id,
  required String name,
  String? company,
  String? jobTitle,
  List<String> emails = const [],
  List<String> phones = const [],
  bool isFavorite = false,
  List<String> tags = const [],
}) {
  final now = DateTime(2026, 1, 1);
  return ContactEntity(
    id: id,
    ownerId: 'owner-1',
    fullName: name,
    company: company,
    jobTitle: jobTitle,
    emails: emails,
    phones: phones,
    isFavorite: isFavorite,
    tags: tags,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  const search = SearchContacts();

  final contacts = [
    _contact(id: '1', name: 'Ada Lovelace', company: 'Analytical Engines', emails: ['ada@ae.com']),
    _contact(id: '2', name: 'Grace Hopper', jobTitle: 'Rear Admiral', isFavorite: true, tags: ['navy']),
    _contact(id: '3', name: 'Alan Turing', company: 'Bletchley Park', phones: ['+441234567890']),
    _contact(id: '4', name: 'Margaret Hamilton', company: 'NASA', isFavorite: true, tags: ['nasa']),
  ];

  test('returns everything when query and filters are empty', () {
    expect(search(contacts).length, contacts.length);
  });

  test('matches by name (case-insensitive)', () {
    final result = search(contacts, query: 'ada');
    expect(result.map((c) => c.id), ['1']);
  });

  test('matches by company', () {
    final result = search(contacts, query: 'nasa');
    expect(result.map((c) => c.id), ['4']);
  });

  test('matches by job title', () {
    final result = search(contacts, query: 'admiral');
    expect(result.map((c) => c.id), ['2']);
  });

  test('matches by email substring', () {
    final result = search(contacts, query: 'ae.com');
    expect(result.map((c) => c.id), ['1']);
  });

  test('matches by phone substring', () {
    final result = search(contacts, query: '1234567890');
    expect(result.map((c) => c.id), ['3']);
  });

  test('favoritesOnly filters down to starred contacts', () {
    final result = search(contacts, favoritesOnly: true);
    expect(result.map((c) => c.id).toSet(), {'2', '4'});
  });

  test('tag filter narrows to a single tag', () {
    final result = search(contacts, tag: 'nasa');
    expect(result.map((c) => c.id), ['4']);
  });

  test('combines query + favoritesOnly', () {
    final result = search(contacts, query: 'hamilton', favoritesOnly: true);
    expect(result.map((c) => c.id), ['4']);
  });

  test('returns empty list for a query matching nothing', () {
    expect(search(contacts, query: 'zzz-nonexistent'), isEmpty);
  });

  test('stress: filters 20,000 contacts well within a UI-safe budget', () {
    final large = List.generate(20000, (i) {
      return _contact(
        id: 'id-$i',
        name: i % 500 == 0 ? 'Findable Person $i' : 'Person Number $i',
        company: 'Company ${i % 50}',
        isFavorite: i % 7 == 0,
        tags: i % 100 == 0 ? const ['vip'] : const [],
      );
    });

    final stopwatch = Stopwatch()..start();
    final byQuery = search(large, query: 'findable');
    final byFavorite = search(large, favoritesOnly: true);
    final byTag = search(large, tag: 'vip');
    stopwatch.stop();

    expect(byQuery.length, 40); // 20000 / 500
    expect(byFavorite.length, greaterThan(0));
    expect(byTag.length, 200); // 20000 / 100

    // In-memory filtering over 20k rows must stay well under a frame
    // budget's worth of milliseconds, otherwise search-as-you-type
    // would visibly stutter.
    expect(stopwatch.elapsedMilliseconds, lessThan(500));
  });
}
