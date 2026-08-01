import 'package:flutter/widgets.dart';

/// LE CANVAS du produit : la taille logique dans laquelle chaque écran est
/// rendu, et les marges système qu'il doit croire avoir.
///
/// C'est le réglage qui décide si le mur DIT LA VÉRITÉ. Un écran rendu à la
/// taille de la fenêtre du bureau ne montre pas ce que voit l'utilisateur :
/// les `SafeArea` ne réservent rien, les boutons collent au bord, et on juge
/// une mise en page qui n'existe sur aucun appareil.
class AtelierCanvas {
  const AtelierCanvas({
    required this.nom,
    required this.largeur,
    required this.hauteur,
    this.safeHaut = 0,
    this.safeBas = 0,
  }) : hauteurMax = 0;

  /// UNE PLANCHE, pas un écran : largeur fixe, hauteur LIBRE.
  ///
  /// Pour tout ce qui n'est pas une page de l'app et qu'on veut voir en
  /// entier : une galerie de composants, une gamme de couleurs, une échelle
  /// typographique. Enfermer ça dans un téléphone donne un rouleau dont on ne
  /// voit que le haut, et à 32 % ça ne se lit pas.
  ///
  /// ```dart
  /// AtelierCase('Boutons', () => const Boutons(),
  ///   canvas: const AtelierCanvas.planche()),
  /// ```
  ///
  /// Une planche IGNORE le format imposé de la barre : forcer une gamme de
  /// couleurs en iPhone SE ne répond à aucune question.
  ///
  /// [hauteurMax] BORNE la hauteur libre, et ce n'est pas une précaution de
  /// confort. Un contenu qui se mesure (une `Column`, un `Wrap`) prend la
  /// hauteur qu'il lui faut ; un contenu qui s'étire (un `Scaffold`, une
  /// `ListView`) essaierait de remplir l'infini et ferait planter le rendu.
  /// Avec une borne, il prend cette borne : on voit tout, avec du vide en
  /// dessous, ce qui vaut infiniment mieux qu'un mur en erreur.
  const AtelierCanvas.planche({
    this.nom = 'Planche',
    this.largeur = 900,
    this.hauteurMax = 4000,
  }) : hauteur = null,
       safeHaut = 0,
       safeBas = 0;

  /// Nom lisible, affiché dans le sélecteur de format.
  final String nom;

  final double largeur;

  /// `null` = hauteur libre, celle du contenu. Voir [AtelierCanvas.planche].
  final double? hauteur;

  /// Plafond de la hauteur libre. Sans objet quand [hauteur] est fixée.
  final double hauteurMax;

  /// Cette case est-elle une planche plutôt qu'un écran ?
  bool get estLibre => hauteur == null;

  /// Marges système simulées. Sur iPhone : ~44 px de barre d'état en haut,
  /// ~34 px de barre home en bas. À zéro, `SafeArea` ne réserve rien et le mur
  /// ment sur l'espace réellement disponible.
  final double safeHaut;
  final double safeBas;

  /// iPhone 13/14/15 Pro, et la taille de tous les iPhone « normaux » depuis
  /// le 12. C'est le format de référence, celui qu'on regarde par défaut.
  static const iphone = AtelierCanvas(
    nom: 'iPhone',
    largeur: 390,
    hauteur: 844,
    safeHaut: 44,
    safeBas: 34,
  );

  /// iPhone Pro Max, taille RÉELLE (428×926, barre d'état de 47).
  ///
  /// Ce format existait auparavant sous [iphone], « ramené au canvas 390 par
  /// le même rapport ». Le raccourci est faux dès qu'on cherche un
  /// débordement : deux écrans de rapport identique ne cassent pas au même
  /// endroit, parce qu'un texte ne se met pas à l'échelle comme sa boîte. Sur
  /// 82 points de plus en largeur, une phrase tient sur deux lignes au lieu de
  /// trois et la page cesse de défiler ; à hauteur égale en proportion, elle
  /// défilerait quand même.
  ///
  /// À regarder EN PLUS de [petit], pas à la place : le grand écran dit ce
  /// que voit la personne qui a payé le téléphone cher, le petit dit où la
  /// mise en page rompt.
  static const iphoneMax = AtelierCanvas(
    nom: 'Pro Max',
    largeur: 428,
    hauteur: 926,
    safeHaut: 47,
    safeBas: 34,
  );

  /// Pixel récent : plus haut, marges système plus discrètes.
  static const android = AtelierCanvas(
    nom: 'Android',
    largeur: 412,
    hauteur: 915,
    safeHaut: 24,
    safeBas: 24,
  );

  /// iPad 11 pouces.
  static const tablette = AtelierCanvas(
    nom: 'Tablette',
    largeur: 834,
    hauteur: 1194,
    safeHaut: 24,
    safeBas: 20,
  );

  /// iPhone SE : le petit écran, celui où une mise en page déborde.
  static const petit = AtelierCanvas(
    nom: 'Petit',
    largeur: 320,
    hauteur: 568,
    safeHaut: 20,
    safeBas: 0,
  );

  /// Les formats proposés par le sélecteur du mur, du plus courant au plus
  /// extrême : la taille de référence, le grand, l'autre système, la tablette,
  /// puis le petit écran qui casse tout.
  static const tous = [iphone, iphoneMax, android, tablette, petit];

  @override
  String toString() => '$nom ${largeur.toInt()}×${hauteur?.toInt() ?? 'libre'}';
}

/// UNE CASE du mur : un libellé, et de quoi CONSTRUIRE l'écran.
///
/// Un constructeur, jamais un widget déjà fabriqué : la même case est montée
/// deux fois (la vignette et la loupe), et un widget partagé entre deux
/// positions de l'arbre est une erreur Flutter.
class AtelierCase {
  const AtelierCase(
    this.label,
    this.build, {
    this.canvas,
    this.avant,
    this.enveloppe,
    this.variantes = const [],
  });

  final String label;
  final Widget Function() build;

  /// LES BROUILLONS de cet écran : deux ou trois pistes qu'on hésite à
  /// prendre, montrées côte à côte pour trancher.
  ///
  /// ```dart
  /// AtelierCase('Accueil', () => const Accueil(), variantes: [
  ///   AtelierVariante('Titre plus gros', () => const AccueilB()),
  ///   AtelierVariante('Sans la bannière', () => const AccueilC()),
  /// ]),
  /// ```
  ///
  /// Une variante ne CHANGE PAS le mur : la case garde une seule vignette,
  /// celle de [build], sinon trente écrans à trois pistes feraient
  /// quatre-vingt-dix vignettes et on perdrait la vue d'ensemble, qui est la
  /// seule raison d'être du mur. Un repère sous la vignette les ouvre en
  /// vis-à-vis.
  ///
  /// À ne pas confondre avec [AtelierVersion] : une variante est un brouillon
  /// DANS la version courante et ne concerne qu'un écran ; une version est
  /// l'app entière dans un état décidé. Trancher une variante ne crée donc
  /// aucune version, sinon on se retrouverait avec une « Version 7 » qui ne
  /// diffère de la 6 que par un bouton, et comparer deux versions ne voudrait
  /// plus rien dire.
  ///
  /// Trancher, justement, ne peut pas être un bouton : une variante est du
  /// code, et aucun clic dans un navigateur ne réécrit un projet. On regarde,
  /// on décide, puis la piste retenue devient l'écran et les autres
  /// disparaissent du catalogue.
  final List<AtelierVariante> variantes;

  /// Canvas SPÉCIFIQUE à cette case, quand elle doit être jugée sur un autre
  /// format que le reste du mur. `null` = celui du mur.
  final AtelierCanvas? canvas;

  /// L'ÉTAT DE CETTE CASE, posé AUTOUR de l'écran. C'est ce qui permet de
  /// montrer le même écran vide, plein, premium, en erreur, côte à côte, et
  /// c'est là que vivent les vrais problèmes de design : le cas nominal est
  /// toujours joli, ce sont les autres qui débordent.
  ///
  /// ```dart
  /// AtelierCase('Accueil · vide', () => const Accueil(),
  ///   enveloppe: (e) => MonScope(parties: 0, child: e)),
  /// AtelierCase('Accueil · installé', () => const Accueil(),
  ///   enveloppe: (e) => MonScope(parties: 42, child: e)),
  /// ```
  ///
  /// UNE ENVELOPPE PLUTÔT QU'UN RÉGLAGE GLOBAL, et ce n'est pas un détail de
  /// style. L'état posé ici appartient à la BRANCHE de cette case : il ne peut
  /// pas fuir vers la vignette d'à côté, et il reste vrai même quand l'écran
  /// relit son état après coup (Future, callback de fin de frame, écouteur).
  /// C'est la seule façon d'obtenir cinq vignettes réellement différentes, et
  /// [avant] n'y arrive pas sur beaucoup d'apps.
  ///
  /// Marche avec tout ce qui passe par le contexte : `Provider`,
  /// `ProviderScope` de Riverpod, un `InheritedWidget` maison.
  final Widget Function(Widget ecran)? enveloppe;

  /// PRÉPARE L'ÉTAT juste avant de construire l'écran, en écrivant dans un
  /// état GLOBAL (une classe statique, un singleton).
  ///
  /// ```dart
  /// AtelierCase('Accueil · vide', () => const Accueil(),
  ///   avant: () => Store.parties = 0),
  /// ```
  ///
  /// ⚠️ Ne marche que si vos écrans lisent leur état PENDANT leur `build` ou
  /// leur `initState`. Un écran qui le relit après coup verra celui de la
  /// dernière case rendue, et vous obtiendrez cinq vignettes identiques sous
  /// cinq libellés différents, ce qui est pire que de n'en montrer qu'une : le
  /// mur mentirait. Constaté sur une vraie app en juillet 2026, d'où
  /// [enveloppe], qui n'a pas ce défaut.
  ///
  /// Préférez donc [enveloppe] dès que votre état passe par le contexte.
  /// `avant` reste utile pour ce qui n'y passera jamais : une clé de
  /// `SharedPreferences`, un drapeau statique.
  ///
  /// Appelé à CHAQUE construction de la vignette (défilement, curseur) :
  /// gardez-le court et sans effet de bord durable.
  final void Function()? avant;
}

/// UNE PISTE pour un écran : un nom court qui dit ce qu'elle tente, et de quoi
/// la construire. Le nom compte autant que le rendu : « B » ne rappelle rien
/// dans deux jours, « Titre plus gros » se décide sans rouvrir le code.
class AtelierVariante {
  const AtelierVariante(this.nom, this.build);

  final String nom;
  final Widget Function() build;
}

/// UN GROUPE de cases, repliable. Sert à séparer ce qu'on regarde ensemble :
/// le parcours d'un côté, le jeu de l'autre, les briques du design système
/// encore ailleurs.
class AtelierSection {
  const AtelierSection(this.titre, this.cases);

  final String titre;
  final List<AtelierCase> cases;
}

/// UN RÉGLAGE de design, modifiable dans le mur et appliqué à tous les écrans
/// en même temps.
///
/// L'atelier ne peut pas deviner vos tokens : vous les déclarez, et vous dites
/// comment les transformer en thème (`themeSelonTokens`). C'est le prix de
/// l'indépendance, et c'est aussi ce qui rend l'aller-retour honnête : ce que
/// vous voyez passe par VOTRE fonction de thème, pas par une approximation.
///
/// ⚠️ Un token ne change que ce qui LIT le thème. Une couleur écrite en dur
/// dans un widget (`const Color(0xFFFF6B2B)`) ou un `static const` de classe
/// ne bougera pas : ces valeurs-là sont figées à la compilation.
sealed class AtelierToken {
  const AtelierToken(this.cle, this.libelle);

  /// Clé utilisée dans la map passée à `themeSelonTokens`, et nom de la
  /// constante à l'export.
  final String cle;

  /// Libellé affiché dans le panneau.
  final String libelle;

  /// Valeur de départ.
  Object get defaut;
}

/// Une couleur, réglée par une palette de teintes et de nuances.
class TokenCouleur extends AtelierToken {
  const TokenCouleur(super.cle, super.libelle, this.valeur);

  final Color valeur;

  @override
  Object get defaut => valeur;
}

/// Un nombre : espacement, rayon, épaisseur, durée, décalage d'ombre.
class TokenNombre extends AtelierToken {
  const TokenNombre(
    super.cle,
    super.libelle,
    this.valeur, {
    this.min = 0,
    this.max = 64,
  });

  final double valeur;
  final double min;
  final double max;

  @override
  Object get defaut => valeur;
}

/// UNE VERSION du design : un nom, et le mur qui va avec.
///
/// Sert pendant une refonte, le seul moment où deux designs coexistent
/// vraiment. L'ancien reste en place tant que le nouveau n'est pas décidé, et
/// on ne décide qu'en les voyant l'un à côté de l'autre : un écran refait
/// paraît toujours meilleur seul, c'est la comparaison qui dit s'il l'est.
///
/// Une seule version déclarée : l'atelier n'affiche aucun onglet, rien ne
/// change. Deux ou plus : les onglets apparaissent, et avec eux la bascule
/// « Comparer », qui aligne les cases de MÊME LIBELLÉ d'une version à l'autre.
/// C'est le libellé qui fait la paire, donc « Accueil » en V1 et « Accueil »
/// en V2 se retrouvent côte à côte, et un écran qui n'existe que d'un côté
/// s'affiche seul, ce qui se remarque aussi.
class AtelierVersion {
  const AtelierVersion(this.nom, this.sections);

  final String nom;
  final List<AtelierSection> sections;
}
