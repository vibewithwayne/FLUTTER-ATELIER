import 'package:atelier/atelier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LE PANNEAU DE TOKENS, de bout en bout.
///
/// C'était la fonctionnalité la plus ambitieuse du paquet et la seule qui
/// n'avait jamais servi une seule fois : sur la vraie app qui l'héberge, les
/// couleurs sont des `static const`, donc le panneau y est inactif depuis le
/// premier jour. Une promesse jamais vérifiée est une déception qui attend son
/// tour.
///
/// Ce que ce test verrouille est la chaîne entière, pas un bout : on bouge un
/// réglage DANS le panneau, et l'écran du mur doit changer. Si le token
/// n'atteignait pas la fonction de thème, ou si le mur ne se reconstruisait
/// pas, on ne verrait rien ici non plus.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget hote() => MaterialApp(
    home: Atelier(
      echelle: 0.15,
      tokens: const [
        TokenCouleur('marque', 'Couleur de marque', Color(0xFF7C4DFF)),
        TokenNombre('rayon', 'Rayon', 16, max: 40),
      ],
      themeSelon: (t, {required clair}) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: t['marque'] as Color,
          brightness: clair ? Brightness.light : Brightness.dark,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(t['rayon'] as double),
          ),
        ),
      ),
      versions: [
        AtelierVersion('V', [
          AtelierSection('s', [AtelierCase('Ecran', () => const _Sonde())]),
        ]),
      ],
    ),
  );

  testWidgets('un nombre regle dans le panneau change l\'ecran du mur', (
    t,
  ) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(hote());
    expect(find.text('rayon: 16.0'), findsOneWidget);

    await t.tap(find.text('Tokens'));
    await t.pumpAndSettle();

    // Le curseur du panneau, pousse a fond : la valeur exacte importe peu, ce
    // qui compte est que l'ecran l'ait recue.
    await t.drag(find.byType(Slider).last, const Offset(500, 0));
    await t.pumpAndSettle();

    expect(find.text('rayon: 16.0'), findsNothing);
    expect(find.text('rayon: 40.0'), findsOneWidget);
  });

  testWidgets('une couleur choisie dans le panneau change l\'ecran du mur', (
    t,
  ) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(hote());
    final avant = t.widget<Text>(find.byKey(const Key('teinte'))).data;

    await t.tap(find.text('Tokens'));
    await t.pumpAndSettle();
    // C'est l'ECHANTILLON qui ouvre la palette, pas le libelle. Et pas le
    // premier InkWell du panneau non plus : celui-la est le bouton
    // « Reinitialiser », qui remet les tokens a zero sans rien changer de
    // visible ici. On vise donc la ligne du token, puis son echantillon.
    final ligne = find
        .ancestor(
          of: find.text('Couleur de marque'),
          matching: find.byType(Row),
        )
        .first;
    await t.tap(find.descendant(of: ligne, matching: find.byType(InkWell)));
    await t.pumpAndSettle();

    // Palette FIXE : on prend une pastille, n'importe laquelle, et on verifie
    // que la teinte de l'ecran a bouge.
    await t.tap(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(InkWell),
          )
          .at(30),
    );
    await t.pumpAndSettle();

    expect(t.widget<Text>(find.byKey(const Key('teinte'))).data, isNot(avant));
  });
}

/// Un écran qui ne fait que dire ce que le THÈME lui donne : c'est la seule
/// façon de prouver que le réglage a traversé toute la chaîne.
class _Sonde extends StatelessWidget {
  const _Sonde();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forme = theme.cardTheme.shape! as RoundedRectangleBorder;
    final rayon = (forme.borderRadius as BorderRadius).topLeft.x;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          Text('rayon: $rayon'),
          Text(
            '${theme.colorScheme.primary.toARGB32()}',
            key: const Key('teinte'),
          ),
        ],
      ),
    );
  }
}
