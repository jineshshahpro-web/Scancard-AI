import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scancard_ai/features/contacts/domain/entities/contact_entity.dart';
import 'package:scancard_ai/features/contacts/presentation/widgets/contact_list_tile.dart';

ContactEntity _contact({bool isFavorite = false, bool isSynced = true}) {
  final now = DateTime(2026, 1, 1);
  return ContactEntity(
    id: 'c1',
    ownerId: 'owner-1',
    fullName: 'Ada Lovelace',
    jobTitle: 'Mathematician',
    company: 'Analytical Engines Ltd',
    isFavorite: isFavorite,
    isSyncedToCloud: isSynced,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('shows name, subtitle, and initials avatar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactListTile(
          contact: _contact(),
          onTap: () {},
          onToggleFavorite: () {},
          onDelete: () {},
        ),
      ),
    ));

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.textContaining('Mathematician'), findsOneWidget);
    expect(find.text('AL'), findsOneWidget); // initials
  });

  testWidgets('fires onTap when the row is tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactListTile(
          contact: _contact(),
          onTap: () => tapped = true,
          onToggleFavorite: () {},
          onDelete: () {},
        ),
      ),
    ));

    await tester.tap(find.byType(ListTile));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('shows a favorite star for favorited contacts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactListTile(
          contact: _contact(isFavorite: true),
          onTap: () {},
          onToggleFavorite: () {},
          onDelete: () {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('shows an offline indicator for unsynced contacts', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ContactListTile(
          contact: _contact(isSynced: false),
          onTap: () {},
          onToggleFavorite: () {},
          onDelete: () {},
        ),
      ),
    ));

    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });
}
