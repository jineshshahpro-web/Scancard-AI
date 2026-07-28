import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scancard_ai/core/widgets/common/empty_state.dart';

void main() {
  testWidgets('renders icon, title, and optional subtitle', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No contacts yet',
          subtitle: 'Scan your first business card to get started.',
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400)); // let the entrance animation settle

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.text('No contacts yet'), findsOneWidget);
    expect(find.text('Scan your first business card to get started.'), findsOneWidget);
  });

  testWidgets('renders and fires the action button when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EmptyState(
          icon: Icons.inbox_outlined,
          title: 'Empty',
          actionLabel: 'Scan a card',
          onAction: () => tapped = true,
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Scan a card'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
