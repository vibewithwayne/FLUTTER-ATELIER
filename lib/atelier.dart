/// ATELIER — voir tous les écrans d'une app Flutter EN MÊME TEMPS, et les
/// régler ensemble.
///
/// Un outil de design, pas un outil de test. Il ne vérifie rien : il montre.
/// Le problème qu'il règle est celui-ci : tant qu'on regarde un écran à la
/// fois, on ne peut pas décider d'une couleur, d'un espacement ou d'un relief,
/// parce que ces choses-là ne se jugent que sur l'ensemble.
///
/// Trois raisons de préférer ça à une planche d'images ou à une maquette :
/// ce sont les VRAIS écrans (rendus, animés, avec vos vraies polices), ils
/// suivent le code sans effort, et vous n'avez rien à annoter dans vos widgets.
///
/// ```dart
/// void main() {
///   runApp(AtelierApp(
///     titre: 'Mon app · Atelier',
///     theme: monTheme(),
///     canvas: AtelierCanvas.iphone,
///     sections: [
///       AtelierSection('Parcours', [
///         AtelierCase('Accueil · vide', () => const Accueil(),
///           avant: () => Store.parties = 0),
///         AtelierCase('Accueil · installé', () => const Accueil(),
///           avant: () => Store.parties = 42),
///       ]),
///     ],
///   ));
/// }
/// ```
///
/// Lancer, de préférence par un POINT D'ENTRÉE séparé (`tool/atelier.dart`),
/// ce qui permet de déclarer le paquet en `dev_dependencies` et garantit qu'il
/// ne coûte rien à l'app publiée :
///
/// ```sh
/// flutter run -d web-server --web-port 8081 -t tool/atelier.dart
/// ```
library;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import 'package:atelier/src/modele.dart';
import 'package:atelier/src/mur.dart';

export 'package:atelier/src/modele.dart'
    show
        AtelierCanvas,
        AtelierCase,
        AtelierSection,
        AtelierVariante,
        AtelierVersion,
        AtelierToken,
        TokenCouleur,
        TokenNombre;
export 'package:atelier/src/mur.dart' show Atelier;

/// L'adresse demande-t-elle l'atelier ?
///
/// Utile si vous préférez le monter depuis le `main` de l'app plutôt que par
/// un point d'entrée séparé. Sur le web, `#/atelier` dans l'URL ; ailleurs,
/// toujours faux. TOUJOURS faux en release, quoi qu'il arrive.
bool atelierDemande([String chemin = '/atelier']) =>
    kDebugMode && Uri.base.fragment.startsWith(chemin);

/// RACINE dédiée : `MaterialApp` + [Atelier], à passer directement à `runApp`.
///
/// Le chrome (barres, panneau, boutons) garde un thème NEUTRE, indépendant du
/// vôtre : un panneau de réglages illisible parce qu'on vient de pousser une
/// couleur à l'extrême ne rend service à personne. Votre thème, lui, habille
/// les écrans.
class AtelierApp extends StatelessWidget {
  const AtelierApp({
    super.key,
    this.sections = const [],
    this.versions = const [],
    this.theme,
    this.themeSelon,
    this.tokens = const [],
    this.briques = const [],
    this.canvas = AtelierCanvas.iphone,
    this.titre = 'Atelier',
    this.fond = const Color(0xFF0B0B0D),
    this.echelle = 0.32,
  });

  /// Le mur, en une seule version. Raccourci de `versions` pour le cas
  /// courant : tant qu'il n'y a qu'un design, il n'y a rien a comparer.
  final List<AtelierSection> sections;

  /// PLUSIEURS VERSIONS du design, quand une refonte est en cours. Des onglets
  /// apparaissent, et avec eux la bascule « Comparer » qui met le meme ecran
  /// en vis-a-vis d'une version a l'autre. Prioritaire sur [sections].
  final List<AtelierVersion> versions;

  /// VOTRE thème, celui de l'app. Ignoré si [themeSelon] est fourni.
  final ThemeData? theme;

  /// Thème calculé à partir des tokens réglés dans le panneau et du mode
  /// clair/sombre. Le fournir active le panneau et la bascule de thème.
  final ThemeData Function(Map<String, Object> tokens, {required bool clair})?
  themeSelon;

  /// Les réglages de design exposés dans le panneau. Vide = pas de panneau.
  final List<AtelierToken> tokens;

  /// LE DESIGN SYSTÈME : les pièces, derrière un bouton, hors du mur. Le mur
  /// est une carte du produit, une galerie de composants n'en est pas une
  /// étape.
  final List<AtelierSection> briques;

  final AtelierCanvas canvas;
  final String titre;
  final Color fond;
  final double echelle;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: titre,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C8CFF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: Atelier(
      versions: versions.isNotEmpty
          ? versions
          : [AtelierVersion('Version 1', sections)],
      canvas: canvas,
      titre: titre,
      fond: fond,
      echelle: echelle,
      theme: theme,
      themeSelon: themeSelon,
      tokens: tokens,
      briques: briques,
    ),
  );
}
