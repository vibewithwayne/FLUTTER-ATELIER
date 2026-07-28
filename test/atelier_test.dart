import 'package:atelier/atelier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ce qui est testé ici, c'est le CONTRAT du mur, pas son apparence : un outil
/// de design n'a pas de rendu de référence à figer, il en aurait un différent
/// à chaque fois qu'on change une marge.
///
/// Cinq promesses, dans l'ordre où elles cassent en vrai :
/// 1. le canvas est RESPECTÉ (sinon le mur ment sur ce que voit l'utilisateur) ;
/// 2. une case peut imposer le sien ;
/// 3. `avant` prépare l'état de CHAQUE case, pas seulement de la dernière ;
/// 4. la recherche filtre ;
/// 5. les vignettes sont muettes (sinon un clic déclenche l'écran au lieu de
///    l'agrandir).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget hote(List<AtelierSection> sections) => MaterialApp(
    home: Atelier(
      versions: [AtelierVersion('Version 1', sections)],
      echelle: 0.8,
    ),
  );

  testWidgets('le canvas impose sa taille et ses marges système', (t) async {
    late Size taille;
    late EdgeInsets marges;
    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase(
            'a',
            () => Builder(
              builder: (c) {
                taille = MediaQuery.sizeOf(c);
                marges = MediaQuery.paddingOf(c);
                return const SizedBox.shrink();
              },
            ),
          ),
        ]),
      ]),
    );
    expect(taille, const Size(390, 844));
    expect(marges, const EdgeInsets.only(top: 44, bottom: 34));
  });

  testWidgets('une case peut imposer son propre format', (t) async {
    late Size taille;
    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase(
            'a',
            () => Builder(
              builder: (c) {
                taille = MediaQuery.sizeOf(c);
                return const SizedBox.shrink();
              },
            ),
            canvas: AtelierCanvas.tablette,
          ),
        ]),
      ]),
    );
    expect(taille.width, 834);
  });

  testWidgets('`avant` prépare l\'état de CHAQUE case', (t) async {
    var etat = 'depart';
    final vus = <String>[];
    // La sonde lit l'état dans son BUILD, comme un vrai écran. C'est tout
    // l'enjeu du test : si les crochets s'exécutaient en fabriquant la LISTE
    // des vignettes, les deux écrans se construiraient ensuite avec l'état du
    // DERNIER, et on lirait ['plein', 'plein'] sans que rien n'ait l'air cassé.
    Widget sonde() => Builder(
      builder: (_) {
        vus.add(etat);
        return const SizedBox.shrink();
      },
    );
    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase('vide', sonde, avant: () => etat = 'vide'),
          AtelierCase('plein', sonde, avant: () => etat = 'plein'),
        ]),
      ]),
    );
    expect(vus, containsAllInOrder(['vide', 'plein']));
    expect(vus, isNot(contains('depart')));
  });

  testWidgets('la recherche filtre les cases', (t) async {
    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase('Accueil', () => const SizedBox.shrink()),
          AtelierCase('Profil', () => const SizedBox.shrink()),
        ]),
      ]),
    );
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    await t.enterText(find.byType(TextField), 'prof');
    await t.pump();

    expect(find.text('Accueil'), findsNothing);
    expect(find.text('Profil'), findsOneWidget);
  });

  testWidgets(
    'une vignette est muette : le clic agrandit, il n\'actionne pas',
    (t) async {
      var touche = false;
      await t.pumpWidget(
        hote([
          AtelierSection('s', [
            AtelierCase(
              'a',
              () => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => touche = true,
                    child: const Text('NE PAS TOUCHER'),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      );
      await t.tap(find.text('NE PAS TOUCHER'), warnIfMissed: false);
      await t.pump();
      expect(
        touche,
        isFalse,
        reason: 'le bouton de la vignette a été actionné',
      );
    },
  );

  testWidgets(
    'deux versions : des onglets, et la comparaison les met face a face',
    (t) async {
      // Le meme libelle dans les deux versions : c'est LUI qui fait la paire.
      // Un ecran qui n'existe que d'un cote doit quand meme se voir, avec un
      // vide en face, sinon la grille decale et laisse croire a une
      // correspondance qui n'existe pas.
      await t.pumpWidget(
        MaterialApp(
          home: Atelier(
            echelle: 0.8,
            versions: [
              AtelierVersion('V1', [
                AtelierSection('s', [
                  AtelierCase('Accueil', () => const SizedBox.shrink()),
                  AtelierCase('Ancien', () => const SizedBox.shrink()),
                ]),
              ]),
              AtelierVersion('V2', [
                AtelierSection('s', [
                  AtelierCase('Accueil', () => const SizedBox.shrink()),
                ]),
              ]),
            ],
          ),
        ),
      );

      // Les onglets existent, et on est sur la V1.
      expect(find.text('V1'), findsOneWidget);
      expect(find.text('V2'), findsOneWidget);
      expect(find.text('Comparer'), findsOneWidget);
      expect(find.text('Ancien'), findsOneWidget);

      // La V2 seule : l'ecran retire a disparu.
      await t.tap(find.text('V2'));
      await t.pump();
      expect(find.text('Ancien'), findsNothing);
      expect(find.text('Accueil'), findsOneWidget);

      // En comparaison : « Accueil » une seule fois comme libelle de groupe, et
      // « Ancien » revient, avec un vide en face.
      await t.tap(find.text('Comparer'));
      await t.pump();
      expect(find.text('Ancien'), findsOneWidget);
      expect(find.text('absent'), findsOneWidget);
    },
  );

  testWidgets('une seule version : son nom est affiche, pas la comparaison', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.8,
          versions: [
            AtelierVersion('Version 1', [
              AtelierSection('s', [
                AtelierCase('Accueil', () => const SizedBox.shrink()),
              ]),
            ]),
          ],
        ),
      ),
    );
    // On doit toujours savoir quelle version on regarde, meme quand il n'y en
    // a qu'une : sans etiquette, le mur laisse croire qu'il n'y a qu'un design
    // possible.
    expect(find.text('Version 1'), findsOneWidget);
    // Mais comparer un ecran a lui-meme n'a aucun sens.
    expect(find.text('Comparer'), findsNothing);
  });

  testWidgets('la barre glisse au lieu de deborder, et dit l\'echelle', (
    t,
  ) async {
    // Une fenetre etroite : avant, les controles se coupaient au bord et le
    // dernier devenait injoignable. Ils tiennent maintenant dans une bande qui
    // defile, donc aucune exception de debordement ne doit sortir.
    t.view.physicalSize = const Size(420, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase('Accueil', () => const SizedBox.shrink()),
        ]),
      ]),
    );

    expect(t.takeException(), isNull);
    // La valeur est ECRITE : un curseur nu ne dit pas ou on en est, on ne peut
    // ni retrouver un cadrage ni en parler a quelqu'un.
    expect(find.text('80 %'), findsOneWidget);
  });

  testWidgets('les pistes d\'un ecran : un repere, puis le vis-a-vis', (
    t,
  ) async {
    // Echelle BASSE : a 0.8 une vignette fait 675 de haut, son libelle tombe
    // hors de la fenetre de test et le repere devient intouchable.
    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.15,
          versions: [
            AtelierVersion('Version 1', [
              AtelierSection('s', [
                AtelierCase(
                  'Accueil',
                  () => const SizedBox.shrink(),
                  variantes: [
                    AtelierVariante(
                      'Titre plus gros',
                      () => const SizedBox.shrink(),
                    ),
                    AtelierVariante(
                      'Sans banniere',
                      () => const SizedBox.shrink(),
                    ),
                  ],
                ),
                AtelierCase('Profil', () => const SizedBox.shrink()),
              ]),
            ]),
          ],
        ),
      ),
    );

    // LE MUR NE TRIPLE PAS : une vignette par ecran, et un simple repere sous
    // celle qui a des pistes. Les afficher en ligne ferait quatre-vingt-dix
    // vignettes pour trente ecrans, et on perdrait la vue d'ensemble.
    expect(find.textContaining('2 pistes'), findsOneWidget);

    await t.tap(find.textContaining('2 pistes'));
    await t.pumpAndSettle();

    // L'ACTUEL EST LA, en premier : comparer trois brouillons sans l'ecran qui
    // existe deja revient a choisir le meilleur des trois sans se demander
    // s'il vaut mieux que ce qu'on a.
    expect(find.text('Actuel'), findsOneWidget);
    expect(find.text('Titre plus gros'), findsOneWidget);
    expect(find.text('Sans banniere'), findsOneWidget);
  });

  testWidgets('sans piste declaree, aucun repere', (t) async {
    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase('Accueil', () => const SizedBox.shrink()),
        ]),
      ]),
    );
    expect(find.textContaining('piste'), findsNothing);
  });

  testWidgets('les ecrans hors champ ne se construisent pas', (t) async {
    // LA PARESSE EST UNE PROMESSE DE TENUE : un mur qui monte quatre-vingts
    // ecrans d'un coup fige le navigateur, et un outil de design qui rame ne
    // sert a rien. On compte donc ce qui se construit vraiment.
    var construits = 0;
    Widget compteur() {
      construits++;
      return const SizedBox.shrink();
    }

    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.5,
          versions: [
            AtelierVersion('V', [
              for (var s = 0; s < 6; s++)
                AtelierSection('Section $s', [
                  for (var i = 0; i < 4; i++) AtelierCase('e$s$i', compteur),
                ]),
            ]),
          ],
        ),
      ),
    );

    // MESURE du 28/07/2026 : 4 sur 24. Le ListView n'inflate que la section
    // visible, la paresse est donc deja acquise. Ce test ne l'ameliore pas, il
    // empeche de la perdre : passer les sections dans une Column, ou toutes
    // les vignettes dans un seul Wrap, monterait les quatre-vingts ecrans d'un
    // coup et figerait le navigateur.
    expect(construits, lessThan(24), reason: 'construits: $construits');
  });

  testWidgets(
    'l\'enveloppe donne a CHAQUE case son etat, meme relu apres coup',
    (t) async {
      // LE RATE QUE CE TEST GARDE FERME : avec un etat global et le crochet
      // `avant`, les cinq vignettes sortaient identiques, toutes avec l'etat
      // pose par la derniere. Ici l'etat vit dans la BRANCHE de la case, il ne
      // peut donc pas fuir vers la voisine.
      //
      // L'ecran lit son etat dans `didChangeDependencies`, c'est-a-dire APRES sa
      // construction : c'est exactement le cas ou `avant` echoue.
      await t.pumpWidget(
        MaterialApp(
          home: Atelier(
            echelle: 0.15,
            versions: [
              AtelierVersion('V', [
                AtelierSection('s', [
                  AtelierCase(
                    'Vide',
                    () => const _Lecteur(),
                    enveloppe: (e) => _Etat(parties: 0, child: e),
                  ),
                  AtelierCase(
                    'Installe',
                    () => const _Lecteur(),
                    enveloppe: (e) => _Etat(parties: 42, child: e),
                  ),
                ]),
              ]),
            ],
          ),
        ),
      );

      expect(find.text('parties: 0'), findsOneWidget);
      expect(find.text('parties: 42'), findsOneWidget);
    },
  );

  testWidgets('un mur vide explique quoi faire, il ne reste pas noir', (
    t,
  ) async {
    // C'est le seul ecran de l'atelier qui doit ENSEIGNER : celui qui vient
    // d'installer l'outil est ici, et il ne lira pas le README.
    await t.pumpWidget(hote([]));
    expect(find.text('Le mur est vide.'), findsOneWidget);
    expect(find.textContaining('dart run atelier:init'), findsOneWidget);
  });

  testWidgets('une recherche sans resultat n\'est pas un mur vide', (t) async {
    await t.pumpWidget(
      hote([
        AtelierSection('s', [
          AtelierCase('Accueil', () => const SizedBox.shrink()),
        ]),
      ]),
    );
    await t.enterText(find.byType(TextField), 'zzz');
    await t.pump();
    // Un non-evenement, pas quelqu'un qui a besoin d'aide : lui servir le mode
    // d'emploi a chaque frappe malheureuse serait insultant.
    expect(find.textContaining('zzz'), findsWidgets);
    expect(find.text('Le mur est vide.'), findsNothing);
  });

  testWidgets('une planche prend la hauteur de son contenu', (t) async {
    // Une galerie de composants enfermee dans un telephone donne un rouleau
    // dont on ne voit que le haut. La planche existe pour ca : largeur fixe,
    // hauteur du contenu.
    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.5,
          versions: [
            AtelierVersion('V', [
              AtelierSection('s', [
                AtelierCase(
                  'Boutons',
                  () => const SizedBox(height: 200),
                  canvas: const AtelierCanvas.planche(largeur: 400),
                ),
              ]),
            ]),
          ],
        ),
      ),
    );

    // La vignette suit le rapport du CONTENU (400 sur 200), pas celui d'un
    // telephone, qui a la meme echelle ferait plus de 400 de haut. Les deux
    // pixels manquants sont la bordure de la vignette.
    final taille = t.getSize(find.byType(FittedBox).first);
    expect(taille.height / taille.width, closeTo(0.5, 0.01));
    expect(taille.height, lessThan(150));
  });

  testWidgets('un format impose ne recadre pas une planche', (t) async {
    // Forcer une gamme de couleurs en iPhone SE ne repond a aucune question,
    // et couperait justement ce qu'on voulait voir en entier.
    const planche = AtelierCanvas.planche(largeur: 400);
    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.5,
          versions: [
            AtelierVersion('V', [
              AtelierSection('s', [
                AtelierCase(
                  'Boutons',
                  () => const SizedBox(height: 200),
                  canvas: planche,
                ),
              ]),
            ]),
          ],
        ),
      ),
    );

    final avant = t.getSize(find.byType(FittedBox).first);
    await t.tap(find.byType(DropdownButton<AtelierCanvas?>));
    await t.pumpAndSettle();
    await t.tap(find.text('Format : Petit').last);
    await t.pumpAndSettle();
    expect(t.getSize(find.byType(FittedBox).first), avant);
  });

  testWidgets('une planche encaisse un ecran qui veut remplir l\'infini', (
    t,
  ) async {
    // LE PLANTAGE DU 28/07/2026, trouve dans le navigateur et par aucun des
    // vingt et un tests d'alors : une galerie de composants est souvent un
    // Scaffold avec une ListView, ca ne se mesure pas, ca s'etire. Sans borne,
    // le rendu partait en assertion et TOUT le mur tombait en erreur.
    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.3,
          versions: [
            AtelierVersion('V', [
              AtelierSection('s', [
                AtelierCase(
                  'Galerie',
                  () => Scaffold(
                    body: ListView(
                      children: const [SizedBox(height: 100), Text('bouton')],
                    ),
                  ),
                  canvas: const AtelierCanvas.planche(
                    largeur: 400,
                    hauteurMax: 1000,
                  ),
                ),
              ]),
            ]),
          ],
        ),
      ),
    );

    expect(t.takeException(), isNull);
    // Il prend la borne, pas l'infini, et le contenu est bien rendu.
    expect(t.getSize(find.byType(FittedBox).first).height, closeTo(300, 5));
    expect(find.text('bouton'), findsOneWidget);
  });

  testWidgets('le design systeme sort du mur et revient par un bouton', (
    t,
  ) async {
    // Fenetre LARGE : la barre glisse horizontalement, et dans 800 de large le
    // bouton sort du cadre. Le finder le trouverait quand meme et le clic
    // tomberait a cote, ce qui ferait passer le test pour un faux positif.
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(
      MaterialApp(
        home: Atelier(
          echelle: 0.15,
          versions: [
            AtelierVersion('Version 1', [
              AtelierSection('Hub', [
                AtelierCase('Accueil', () => const SizedBox.shrink()),
              ]),
            ]),
          ],
          briques: [
            AtelierSection('Composants', [
              AtelierCase('Boutons', () => const SizedBox.shrink()),
            ]),
          ],
        ),
      ),
    );

    // LE MUR EST UNE CARTE DU PRODUIT : une galerie de composants n'en est pas
    // une etape, et sa planche ecrasait les vignettes de telephone autour.
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Boutons'), findsNothing);

    await t.tap(find.text('Design système'));
    await t.pump();

    expect(find.text('Boutons'), findsOneWidget);
    expect(find.text('Accueil'), findsNothing);
    // Les versions ne veulent rien dire ici : on regarde des pieces, pas un
    // design d'ensemble.
    expect(find.text('Version 1'), findsNothing);

    await t.tap(find.text('Design système'));
    await t.pump();
    expect(find.text('Accueil'), findsOneWidget);
  });

  testWidgets('sans briques declarees, aucun bouton', (t) async {
    await t.pumpWidget(
      hote([
        AtelierSection('Hub', [
          AtelierCase('Accueil', () => const SizedBox.shrink()),
        ]),
      ]),
    );
    expect(find.text('Design système'), findsNothing);
  });
}

/// Un etat porte par le contexte, comme un Provider ou un ProviderScope.
class _Etat extends InheritedWidget {
  const _Etat({required this.parties, required super.child});

  final int parties;

  static int de(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_Etat>()?.parties ?? -1;

  @override
  bool updateShouldNotify(_Etat old) => old.parties != parties;
}

/// Un ecran qui lit son etat APRES sa construction, comme la plupart des
/// vrais : c'est le cas que le crochet global ne sait pas servir.
class _Lecteur extends StatefulWidget {
  const _Lecteur();

  @override
  State<_Lecteur> createState() => _LecteurState();
}

class _LecteurState extends State<_Lecteur> {
  int _parties = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _parties = _Etat.de(context);
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: Text('parties: $_parties'),
  );
}
