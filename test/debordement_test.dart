import 'package:atelier/atelier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LE BADGE DE DÉBORDEMENT, prouvé plutôt qu'annoncé.
///
/// La mécanique repose sur une hypothèse qu'on ne peut pas vérifier en relisant
/// le code : `ScrollMetricsNotification` part-elle vraiment dès la PREMIÈRE
/// mise en page, sans que personne ne touche l'écran ? Si elle n'arrivait qu'au
/// premier geste, le mur n'afficherait jamais rien, et le badge serait une
/// promesse silencieuse — la pire espèce, parce qu'on lui fait confiance.
///
/// Trois choses à tenir :
/// 1. un écran trop long est SIGNALÉ, sans interaction ;
/// 2. un écran qui tient ne l'est pas (un badge qui crie tout le temps ne se
///    lit plus) ;
/// 3. une rangée HORIZONTALE ne compte pas : un carrousel est une intention,
///    pas un défaut.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget hote(List<AtelierCase> cases, {AtelierCanvas? canvas}) => MaterialApp(
    home: Atelier(
      versions: [
        AtelierVersion('Version 1', [AtelierSection('s', cases)]),
      ],
      canvas: canvas ?? AtelierCanvas.iphone,
      // Grande échelle : le badge vit sous le libellé, et à 32 % la vignette
      // sortirait de la fenêtre de test avant qu'on puisse le lire.
      echelle: 0.5,
    ),
  );

  /// Une page dont le contenu dépasse la hauteur du canvas.
  Widget longue(double hauteur) => Scaffold(
    body: SingleChildScrollView(child: SizedBox(height: hauteur, width: 200)),
  );

  testWidgets('un écran plus long que le téléphone annonce ce qui est caché', (
    t,
  ) async {
    t.view.physicalSize = const Size(1400, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    // Le corps d'un `Scaffold` reçoit TOUTE la hauteur du canvas, marges
    // système comprises : c'est à l'écran de les respecter avec un `SafeArea`,
    // pas au conteneur de les retrancher. Viewport 844, contenu 1000, donc 156
    // de caché. (Attendu 234 au premier jet, en croyant les marges déduites :
    // c'est le test qui avait tort, pas le mur.)
    await t.pumpWidget(hote([AtelierCase('trop long', () => longue(1000))]));
    await t.pumpAndSettle();

    expect(find.textContaining('pt cachés'), findsOneWidget);
    expect(find.textContaining('156'), findsOneWidget);
  });

  testWidgets('un écran qui tient ne porte aucun badge', (t) async {
    t.view.physicalSize = const Size(1400, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(hote([AtelierCase('court', () => longue(200))]));
    await t.pumpAndSettle();

    expect(find.textContaining('pt cachés'), findsNothing);
  });

  testWidgets('une rangée horizontale n\'est pas un débordement', (t) async {
    t.view.physicalSize = const Size(1400, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      hote([
        AtelierCase(
          'carrousel',
          () => Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: const SizedBox(width: 3000, height: 100),
            ),
          ),
        ),
      ]),
    );
    await t.pumpAndSettle();

    expect(find.textContaining('pt cachés'), findsNothing);
  });

  testWidgets('le même écran répond différemment selon le format', (t) async {
    t.view.physicalSize = const Size(1400, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    // C'est TOUT l'intérêt d'avoir ajouté le Pro Max : 926 contre 844, soit 82
    // points d'écart. Une page de 880 tient sur le grand téléphone et déborde
    // sur l'autre. Un format « ramené au même rapport » ne pourrait pas
    // montrer ça, puisqu'il aurait la même hauteur utile.
    await t.pumpWidget(
      hote([
        AtelierCase('limite', () => longue(880)),
      ], canvas: AtelierCanvas.iphoneMax),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('pt cachés'), findsNothing);

    await t.pumpWidget(
      hote([
        AtelierCase('limite', () => longue(880)),
      ], canvas: AtelierCanvas.iphone),
    );
    await t.pumpAndSettle();
    expect(find.textContaining('36'), findsOneWidget);
  });
}
