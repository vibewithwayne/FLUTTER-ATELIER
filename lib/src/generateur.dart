/// LE PREMIER CATALOGUE, écrit à votre place.
///
/// Le mur s'explique tout seul dès qu'on le voit. Ce qui bloque, c'est ce
/// qu'il faut faire AVANT de le voir : écrire à la main trente lignes de
/// catalogue sans rien recevoir en échange. Personne ne va au bout, et l'outil
/// meurt avant le premier écran.
///
/// Ce module lit vos fichiers comme du TEXTE, pas comme du Dart analysé. C'est
/// un choix : embarquer `package:analyzer` alourdirait les dépendances de tous
/// ceux qui installent l'atelier, pour un fichier qu'on relit de toute façon.
/// Il se trompera donc parfois. Ce n'est pas grave et c'est même prévu : ce
/// qu'il écrit est un POINT DE DÉPART, une erreur se voit à la compilation, et
/// la corriger prend cinq secondes. Ce qui compte est de voir son app en
/// trente secondes.
library;

/// Un écran repéré dans le code.
class EcranTrouve {
  const EcranTrouve({
    required this.classe,
    required this.chemin,
    required this.section,
    required this.constant,
    this.manque = const [],
  });

  /// Le nom de la classe, tel qu'il sera construit.
  final String classe;

  /// Chemin relatif à `lib/`, pour l'import.
  final String chemin;

  /// Le groupe où la case atterrit, déduit du dossier.
  final String section;

  /// Le constructeur est-il `const` ?
  final bool constant;

  /// Les paramètres obligatoires. Non vide = la case sort EN COMMENTAIRE :
  /// l'atelier ne peut pas inventer un identifiant de produit ou un objet de
  /// partie, et une ligne qui ne compile pas ferait échouer tout le fichier.
  final List<String> manque;

  bool get constructible => manque.isEmpty;
}

/// Les classes qui ressemblent à un écran. Le suffixe est le seul critère
/// honnête : sans lui on ramasserait chaque bouton et chaque carte, et le mur
/// deviendrait un inventaire de widgets au lieu d'une vue de l'app.
///
/// La majuscule initiale n'est pas cosmétique : une classe privée
/// (`_RotateScreen`) ne s'importe pas depuis `tool/`, et la mettre au
/// catalogue ferait échouer la compilation du fichier entier.
///
/// Même raison pour le rejet d'`abstract` et de `sealed` : ces classes-là ne
/// se construisent pas. Un `abstract class BaseScreen` au catalogue, et le
/// fichier de démarrage ne compile plus, ce qui est exactement la seule chose
/// que ce générateur promet de ne jamais faire.
///
/// Le paramètre de type est toléré (`class ListePage<T> extends ...`) : la
/// classe se déclare avec, mais s'écrit sans à la construction.
final _classe = RegExp(
  r'(abstract\s+|sealed\s+|base\s+|final\s+|interface\s+|mixin\s+)?'
  r'class\s+([A-Z]\w*(?:Screen|Page|View))\s*(?:<[^>]*>)?\s+extends\s+'
  r'(?:StatelessWidget|StatefulWidget|ConsumerWidget|'
  r'ConsumerStatefulWidget|HookWidget|HookConsumerWidget)\b',
);

/// Les écrans d'un fichier source.
List<EcranTrouve> ecransDuFichier(String source, String chemin) {
  final out = <EcranTrouve>[];
  for (final m in _classe.allMatches(source)) {
    // Un modificateur devant `class` (abstract, sealed) = classe non
    // constructible : on ne la met pas au catalogue.
    final modificateur = m.group(1)?.trim();
    if (modificateur == 'abstract' || modificateur == 'sealed') continue;
    final nom = m.group(2)!;
    final corps = _corps(source, m.start);
    final ctor = RegExp(
      '(const\\s+)?\\b$nom\\b\\s*\\(([^)]*)\\)',
    ).firstMatch(corps);
    out.add(
      EcranTrouve(
        classe: nom,
        chemin: chemin,
        section: sectionDepuisChemin(chemin),
        constant: ctor?.group(1) != null,
        manque: _obligatoires(ctor?.group(2) ?? ''),
      ),
    );
  }
  return out;
}

/// Le texte de la classe : de sa déclaration à la suivante. Approximatif et
/// suffisant, on ne cherche qu'un constructeur.
String _corps(String source, int debut) {
  final suivante = source.indexOf('\nclass ', debut + 1);
  return source.substring(debut, suivante == -1 ? source.length : suivante);
}

/// Les paramètres SANS lesquels l'écran ne se construit pas : les positionnels
/// et les nommés `required`. La clé de widget ne compte pas, elle est toujours
/// facultative.
List<String> _obligatoires(String params) {
  if (params.trim().isEmpty) return const [];
  final iAcc = params.indexOf('{');
  final iCro = params.indexOf('[');
  final coupe = [
    iAcc,
    iCro,
  ].where((i) => i >= 0).fold<int>(params.length, (a, b) => a < b ? a : b);

  final positionnels = params.substring(0, coupe);
  final nommes = coupe < params.length
      ? params.substring(coupe).replaceAll(RegExp(r'[{}\[\]]'), '')
      : '';

  final out = <String>[];
  for (final p in positionnels.split(',')) {
    if (p.trim().isEmpty || _estCle(p)) continue;
    out.add(_nomDuParam(p));
  }
  for (final p in nommes.split(',')) {
    if (!p.contains('required') || _estCle(p)) continue;
    out.add(_nomDuParam(p));
  }
  return out;
}

bool _estCle(String p) => p.contains('key') || p.contains('Key');

String _nomDuParam(String p) {
  final mots = p.trim().split(RegExp(r'[\s.]+'));
  return mots.isEmpty ? p.trim() : mots.last.replaceAll(RegExp(r'[^\w]'), '');
}

/// La section déduite du dossier. `features/boutique/pack_screen.dart` donne
/// « Boutique » : c'est l'arborescence qui dit déjà comment vous rangez votre
/// app, autant s'en servir plutôt que d'inventer un classement.
String sectionDepuisChemin(String chemin) {
  final parts = chemin.split('/')..removeLast();
  const traversants = {'features', 'pages', 'screens', 'views', 'ui', 'src'};
  final utiles = [...parts];
  while (utiles.isNotEmpty && traversants.contains(utiles.first)) {
    utiles.removeAt(0);
  }
  final brut = utiles.isNotEmpty
      ? utiles.first
      : (parts.isNotEmpty ? parts.last : 'Écrans');
  return _titre(brut);
}

/// « profile_setup_screen » donne « Profile setup » : le libellé se lit sous
/// la vignette, il doit être une étiquette, pas un nom de classe.
String libelleDepuisClasse(String classe) {
  final sansSuffixe = classe.replaceAll(RegExp(r'(Screen|Page|View)$'), '');
  final mots = sansSuffixe
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .trim();
  return mots.isEmpty ? classe : _majuscule(mots);
}

String _titre(String brut) =>
    _majuscule(brut.replaceAll('_', ' ').replaceAll('-', ' ').trim());

String _majuscule(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// LE MODE D'EMPLOI DE L'AGENT, déposé dans le projet.
///
/// Le pari du paquet est là : la personne qui installe l'atelier ne lira pas
/// le README, elle demandera à son assistant. Autant que l'assistant sache. Ce
/// fichier lui apprend le VOCABULAIRE (changement direct, piste, version) et
/// surtout ce qui n'est pas évident : qu'une piste est du code, que trancher
/// n'est pas un bouton, et qu'un changement transverse ne se copie pas.
String skill() => '''
---
name: atelier
description: Voir tous les écrans de l'app en même temps et itérer sur le design. À charger dès qu'on parle de design, d'écrans, de « à quoi ça ressemble », d'une refonte, ou qu'on hésite entre plusieurs directions visuelles.
---

# Atelier

Le catalogue des écrans vit dans `tool/atelier.dart`. Le mur se lance par la
configuration `atelier` de `.claude/launch.json`, déposée par `atelier:init` :
démarrez-la et ouvrez le navigateur, sans rien demander à la personne. À
défaut :

```bash
flutter run -d web-server --web-port 8081 -t tool/atelier.dart
```

Le premier chargement d'un build web de développement est long, et la page
reste parfois sur l'écran de démarrage : rechargez une fois avant de conclure
à une panne.

Un écran ajouté à l'app doit être ajouté au catalogue, sinon le mur ment par
omission.

## Les sections sont une carte du produit

`atelier:init` groupe les écrans par DOSSIER, ce qui est un premier jet, pas un
classement. Un mur rangé comme `lib/` raconte l'architecture du code, ce qui
n'intéresse personne au moment de juger un design.

Rangez-les dans l'ordre où l'utilisateur les rencontre : il découvre, il se
crée un compte, il arrive sur l'écran principal, il fait la chose pour laquelle
il est venu, il paie, il règle. L'outillage (design système, formats) ferme la
marche, ce n'est pas du produit.

Une section qui dépasse sept ou huit vignettes est devenue un fourre-tout :
cherchez le moment qu'elle mélange et coupez-la en deux. « Entrée » qui avale
les six écrans de connexion en est le cas typique : découverte et identité sont
deux moments différents.

Ne créez PAS de section « Formats » ou « Responsive » avec le même écran en
trois tailles : le sélecteur de format de la barre rejoue déjà tout le mur dans
la taille voulue, sur tous les écrans plutôt que sur ceux qu'on aurait choisis.
Une section qui double un réglage coûte des vignettes en permanence pour une
question déjà répondue. Même règle pour toute section qui refait à la main ce
que la barre fait d'un clic.

## Les planches : ce qui n'est pas un écran

Une galerie de composants, une gamme de couleurs, une échelle typographique ne
sont pas des pages de l'app. Dans un téléphone de 390 sur 844 elles deviennent
un rouleau dont on ne voit que le haut. Donnez-leur une planche : largeur fixe,
hauteur du contenu, et le format imposé de la barre ne s'y applique pas.

```dart
AtelierCase('Boutons', () => const GalerieBoutons(),
  canvas: const AtelierCanvas.planche()),
```

## Le design système, hors du mur

Ces galeries se déclarent dans `briques` plutôt que dans `sections`, et un
bouton apparaît dans la barre :

```dart
AtelierApp(
  sections: [...],
  briques: [
    AtelierSection('Composants', [
      AtelierCase('Boutons', () => const GalerieBoutons(),
        canvas: const AtelierCanvas.planche()),
    ]),
  ],
)
```

Même déclaration, autre endroit. Le mur raconte le parcours ; une galerie de
composants n'en est pas une étape, et sa planche écraserait les vignettes de
téléphone autour d'elle.

Ne créez PAS de liste de composants dans l'outil : la galerie qui les montre
est un écran à écrire dans le projet. Une liste déclarée ici dériverait dès la
première variante supprimée, et un catalogue qui ment vaut moins que pas de
catalogue.

## Les tokens, quand les couleurs passent par le thème

Si l'app calcule son thème à partir de valeurs nommées, déclarez-les : un
panneau les rend réglables, appliquées à tous les écrans en direct, et un
bouton exporte le Dart correspondant.

```dart
AtelierApp(
  tokens: const [
    TokenCouleur('marque', 'Couleur de marque', Color(0xFF7C4DFF)),
    TokenNombre('rayon', 'Rayon des cartes', 16, max: 40),
  ],
  themeSelon: (t, {required clair}) => monTheme(t['marque'] as Color, clair),
)
```

⚠️ Un token ne change que ce qui LIT le thème. Une couleur écrite en dur dans
un widget, ou un `static const` de classe, est figée à la compilation : le
panneau ne pourra rien pour elle. Si les couleurs du projet sont des
constantes, ne déclarez pas de tokens, ils ne feraient rien.

## Ce que le mur doit croire

Le mur tourne dans un NAVIGATEUR. Toute branche `kIsWeb` y prend donc le
chemin web, et l'app qu'on juge n'est plus celle qu'on publie. Si le projet a
des divergences de plateforme, donnez-leur un point de forçage et posez-le
depuis `tool/atelier.dart`.

Même chose pour les données que seul un appareil peut fournir : prix d'un
magasin d'applications, réponse d'une API. Semez des valeurs de DÉMO au
démarrage du catalogue, avec les vraies valeurs du produit. Un prix n'est pas
un détail de contenu, c'est l'élément le plus regardé d'un écran d'achat, et
sans lui on dessine à côté du sujet.

## Trois gestes, et un seul est fréquent

**Changement direct.** « Change la couleur des boutons », « remonte la
boutique ». Modifiez le vrai écran ou le vrai composant. C'est le cas normal.
Un changement transverse (icônes, couleurs, style de bouton) vit dans UN
fichier et se voit aussitôt sur tout le mur : ne le dupliquez jamais.

**Piste.** Seulement quand la personne HÉSITE (« j'hésite entre », « propose
plusieurs directions », « fais-moi deux versions »). Copiez l'écran dans
`tool/pistes/`, appliquez la variation, déclarez-la :

```dart
AtelierCase('Accueil', () => const Accueil(), variantes: [
  AtelierVariante('Titre plus gros', () => const AccueilTitreGros()),
]),
```

Nommez la piste par ce qu'elle tente, jamais « B ». Une piste vit deux jours :
quand la personne tranche, la gagnante devient l'écran, et `tool/pistes/` est
supprimé. Trancher n'est PAS un bouton dans le navigateur : c'est vous qui
modifiez le code, sur sa décision.

**Version.** Seulement pour une refonte, quand toute la peau de l'app change.
`AtelierVersion('Version 2', ...)` à côté de la Version 1, et l'onglet
« Comparer » les met face à face. Trancher une piste ne crée jamais une
version.

## Les états d'un écran

Le cas nominal est toujours joli, ce sont les autres qui débordent. Montrez le
même écran vide, plein, en erreur, en enveloppant chaque case dans son état :

```dart
AtelierCase('Panier · vide', () => const Panier(),
  enveloppe: (e) => MonScope(articles: 0, child: e)),
AtelierCase('Panier · plein', () => const Panier(),
  enveloppe: (e) => MonScope(articles: 12, child: e)),
```

L'enveloppe, pas un réglage global : l'état reste dans la branche de la case,
il ne fuit pas vers la vignette voisine et il tient même si l'écran relit ses
données après coup.

## Ce que l'atelier n'est pas

Ce n'est pas une maquette à resynchroniser : le mur monte le VRAI code, il n'y
a rien à réappliquer ensuite. Et il ne touche pas au backend, les écrans se
rendent sans lui.
''';

/// Le fichier `tool/atelier.dart` complet.
String catalogue({required String paquet, required List<EcranTrouve> ecrans}) {
  // LES DEUX TAS, séparés d'entrée. Ce qui se construit fait le catalogue ;
  // ce qui demande des arguments part en LISTE DE COURSES à la fin du fichier.
  // Éparpiller les lignes mortes au milieu des vivantes rendrait le catalogue
  // illisible, et une section qui ne contiendrait QUE des commentaires
  // apparaîtrait vide au mur, ce qui se lit comme un bug.
  final prets = ecrans.where((e) => e.constructible).toList();
  final aFaire = ecrans.where((e) => !e.constructible).toList();

  final sections = <String, List<EcranTrouve>>{};
  for (final e in prets) {
    sections.putIfAbsent(e.section, () => []).add(e);
  }
  final titres = sections.keys.toList()..sort();
  // IMPORTS DES SEULS ÉCRANS ACTIFS : importer un fichier dont toutes les
  // cases sont commentées ferait un avertissement à la première ouverture.
  final imports =
      prets.map((e) => "import 'package:$paquet/${e.chemin}';").toSet().toList()
        ..sort();

  final b = StringBuffer()
    ..writeln("// L'ATELIER DE $paquet — le catalogue, et rien d'autre.")
    ..writeln('//')
    ..writeln('// ÉCRIT PAR `dart run atelier:init`, puis à vous : le')
    ..writeln("// générateur lit vos fichiers comme du texte, il n'a donc pas")
    ..writeln('// tout compris. Ce qui manque se voit vite, et se corrige')
    ..writeln('// ligne par ligne.')
    ..writeln('//')
    ..writeln('// POINT D\'ENTRÉE SÉPARÉ, hors de `lib/` : c\'est ce qui garde')
    ..writeln("// l'outil à coût zéro pour l'app publiée.")
    ..writeln('//')
    ..writeln(
      '//   flutter run -d web-server --web-port 8081 -t tool/atelier.dart',
    )
    ..writeln()
    ..writeln("import 'package:atelier/atelier.dart';")
    ..writeln("import 'package:flutter/material.dart';")
    ..writeln();
  for (final i in imports) {
    b.writeln(i);
  }
  b
    ..writeln()
    ..writeln('void main() {')
    ..writeln('  runApp(')
    ..writeln('    AtelierApp(')
    // « Atelier » tout court : c'est le nom de l'outil, pas celui du projet.
    // On sait quel projet on regarde, on est dedans.
    ..writeln("      titre: 'Atelier',")
    ..writeln('      // VOTRE thème. Sans lui, le mur montre des écrans qui ne')
    ..writeln('      // sont pas les vôtres.')
    ..writeln('      // theme: monTheme(),')
    ..writeln('      canvas: AtelierCanvas.iphone,')
    ..writeln('      sections: [');

  for (final titre in titres) {
    final cases = sections[titre]!
      ..sort((a, b) => a.classe.compareTo(b.classe));
    b.writeln("        AtelierSection('$titre', [");
    for (final e in cases) {
      final ctor = e.constant ? 'const ${e.classe}()' : '${e.classe}()';
      b.writeln(
        "          AtelierCase('${libelleDepuisClasse(e.classe)}', "
        '() => $ctor),',
      );
    }
    b.writeln('        ]),');
  }

  b
    ..writeln('      ],')
    ..writeln('    ),')
    ..writeln('  );')
    ..writeln('}');

  if (aFaire.isNotEmpty) {
    aFaire.sort((a, b) => a.classe.compareTo(b.classe));
    b
      ..writeln()
      ..writeln('// ── À COMPLÉTER ─────────────────────────────────────────')
      ..writeln('//')
      ..writeln('// Ces écrans demandent des arguments que le générateur ne')
      ..writeln("// peut pas inventer : un identifiant de produit, une partie")
      ..writeln('// en cours, un rappel. Donnez-leur des valeurs de DÉMO,')
      ..writeln("// ajoutez-les dans une section, et l'import qui va avec.")
      ..writeln('//')
      ..writeln('// Ce sont souvent les écrans les plus intéressants du mur :')
      ..writeln("// ceux qui dépendent de données sont ceux qui débordent.")
      ..writeln('//');
    for (final e in aFaire) {
      b.writeln(
        "// AtelierCase('${libelleDepuisClasse(e.classe)}', "
        '() => ${e.classe}('
        '${e.manque.map((p) => '$p: /* ? */').join(', ')})),',
      );
    }
  }
  return b.toString();
}
