// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:airconcept/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AirGraph home opens the interactive graph editor',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const AirGraphApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue dans votre espace AirGraph'), findsOneWidget);
    await tester.tap(find.text('Créer un graphe'));
    await tester.pumpAndSettle();

    expect(find.text('Votre graphe conceptuel'), findsOneWidget);
    expect(find.text('Ajouter un concept'), findsOneWidget);

    final conceptField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField && widget.decoration?.hintText == 'Ex. Passager',
    );
    await tester.enterText(conceptField, 'Avion');
    await tester.tap(find.text('Ajouter un concept'));
    await tester.pumpAndSettle();
    expect(find.text('Avion'), findsOneWidget);

    await tester.tap(find.text('Enregistrer localement'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const AirGraphApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Représentation des phrases').first);
    await tester.pumpAndSettle();
    expect(find.text('Avion'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('exercise catalogue opens a question and tracks correct answers',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const AirGraphApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exercices').first);
    await tester.pumpAndSettle();
    expect(find.text('À vous de jouer.'), findsOneWidget);
    expect(find.text('EXERCICE 06'), findsOneWidget);
    expect(find.text('0 / 6 exercices réussis'), findsOneWidget);

    await tester.tap(find.text('Commencer').first);
    await tester.pumpAndSettle();
    expect(
      find.text(
          'Dans « Un passager réserve un billet », lequel est un concept ?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Passager'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vérifier ma réponse'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bonne réponse !'), findsOneWidget);
    expect(find.text('1 / 6 exercices réussis'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('specialization expands a selectable concept hierarchy',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const AirGraphApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Spécialisation').first);
    await tester.pumpAndSettle();
    expect(find.text('Explorez les branches.'), findsOneWidget);
    expect(find.text('Hiérarchie des concepts'), findsOneWidget);
    expect(find.text('Votre exploration commence ici.'), findsOneWidget);

    await tester.tap(find.text('Spécialiser'));
    await tester.pumpAndSettle();
    expect(find.text('Avion commercial'), findsOneWidget);
    expect(find.text('Avion cargo'), findsOneWidget);

    await tester.tap(find.text('Avion commercial'));
    await tester.tap(find.text('Spécialiser'));
    await tester.pumpAndSettle();
    expect(find.text('Airbus A320'), findsOneWidget);
    expect(find.text('Boeing 737'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('generalization builds the path from specific to general',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1360, 900);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const AirGraphApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Généralisation').first);
    await tester.pumpAndSettle();
    expect(find.text('Prenez de la hauteur.'), findsOneWidget);
    expect(find.text('Du particulier au général'), findsOneWidget);
    expect(find.text('Votre exploration commence ici.'), findsOneWidget);

    await tester.tap(find.text('Généraliser'));
    await tester.pumpAndSettle();
    expect(find.text('Avion commercial'), findsOneWidget);
    expect(find.text('Avion'), findsOneWidget);
    expect(find.text('Moyen de transport'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
