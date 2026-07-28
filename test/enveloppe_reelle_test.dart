import 'package:atelier/atelier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L'ENVELOPPE FACE AUX VRAIS GESTIONNAIRES D'ÉTAT.
///
/// La promesse est écrite dans le README : « ça marche avec tout ce qui passe
/// par le contexte, Provider, le ProviderScope de Riverpod, un
/// InheritedWidget maison ». Elle n'était vérifiée qu'avec le troisième,
/// c'est-à-dire avec le seul que j'avais écrit moi-même, ce qui ne prouve
/// rien : les deux autres ont leurs propres règles de portée et de
/// reconstruction, et c'est là que ça peut casser.
///
/// Ces deux paquets sont en `dev_dependencies` : personne n'a à les installer
/// pour se servir de l'atelier.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget mur(List<AtelierCase> cases) => MaterialApp(
    home: Atelier(
      echelle: 0.15,
      versions: [
        AtelierVersion('V', [AtelierSection('s', cases)]),
      ],
    ),
  );

  testWidgets('Provider : chaque case a son etat', (t) async {
    await t.pumpWidget(
      mur([
        AtelierCase(
          'Vide',
          () => const _LecteurProvider(),
          enveloppe: (e) => Provider<int>.value(value: 0, child: e),
        ),
        AtelierCase(
          'Plein',
          () => const _LecteurProvider(),
          enveloppe: (e) => Provider<int>.value(value: 42, child: e),
        ),
      ]),
    );

    expect(find.text('articles: 0'), findsOneWidget);
    expect(find.text('articles: 42'), findsOneWidget);
  });

  testWidgets('Riverpod : chaque case a son scope', (t) async {
    await t.pumpWidget(
      mur([
        AtelierCase(
          'Vide',
          () => const _LecteurRiverpod(),
          enveloppe: (e) => riverpod.ProviderScope(
            overrides: [_articles.overrideWithValue(0)],
            child: e,
          ),
        ),
        AtelierCase(
          'Plein',
          () => const _LecteurRiverpod(),
          enveloppe: (e) => riverpod.ProviderScope(
            overrides: [_articles.overrideWithValue(42)],
            child: e,
          ),
        ),
      ]),
    );

    expect(find.text('articles: 0'), findsOneWidget);
    expect(find.text('articles: 42'), findsOneWidget);
  });
}

class _LecteurProvider extends StatelessWidget {
  const _LecteurProvider();

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text('articles: ${context.watch<int>()}'),
  );
}

final _articles = riverpod.Provider<int>((ref) => -1);

class _LecteurRiverpod extends riverpod.ConsumerWidget {
  const _LecteurRiverpod();

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text('articles: ${ref.watch(_articles)}'),
  );
}
