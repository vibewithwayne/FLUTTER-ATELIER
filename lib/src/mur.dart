import 'package:flutter/material.dart';

import 'package:atelier/src/loupe.dart';
import 'package:atelier/src/modele.dart';
import 'package:atelier/src/panneau_tokens.dart';
import 'package:atelier/src/reglages.dart';
import 'package:atelier/src/variantes.dart';

/// LE MUR : tous les écrans rendus EN MÊME TEMPS, à l'échelle.
///
/// Un écran à la fois, c'est bon pour vérifier ; ça ne permet pas de DÉCIDER.
/// Une couleur, un espacement, un relief se jugent d'un coup d'œil sur
/// l'ensemble, sinon on corrige écran par écran et la cohérence se perd.
///
/// Ce sont les VRAIS écrans, montés et animés, pas des captures : une planche
/// d'images est périmée dès le commit suivant, et une maquette refaite dans un
/// autre outil diverge encore plus vite.
///
/// Trois barres de réglages, dans l'ordre où on s'en sert :
/// 1. la RECHERCHE et l'échelle, pour trouver et cadrer ;
/// 2. les AXES (thème clair, format imposé), qui rejouent les quarante écrans
///    d'un coup — c'est là qu'on voit lesquels débordent ;
/// 3. les TOKENS, qui changent le design lui-même (panneau latéral).
class Atelier extends StatefulWidget {
  const Atelier({
    super.key,
    required this.versions,
    this.canvas = AtelierCanvas.iphone,
    this.titre = 'ATELIER',
    this.fond = const Color(0xFF0B0B0D),
    this.echelle = 0.32,
    this.theme,
    this.themeSelon,
    this.tokens = const [],
    this.briques = const [],
  });

  /// Les versions du design. Une seule : aucun onglet, le mur d'avant. Deux ou
  /// plus : des onglets, et la bascule « Comparer ».
  final List<AtelierVersion> versions;

  /// Le format dans lequel chaque case est rendue (une case, ou le sélecteur
  /// de la barre, peuvent le surcharger).
  final AtelierCanvas canvas;

  final String titre;

  /// Fond du mur. Volontairement NEUTRE et sombre par défaut : le mur doit
  /// disparaître derrière les écrans, pas concourir avec eux.
  final Color fond;

  final double echelle;

  /// VOTRE thème. Sans lui, le mur montre des écrans qui ne sont pas les
  /// vôtres. Ignoré si [themeSelon] est fourni.
  final ThemeData? theme;

  /// Thème CALCULÉ à partir des tokens réglés dans le panneau et du mode
  /// clair/sombre. Le fournir active les deux bascules correspondantes.
  ///
  /// C'est votre fonction de thème, pas une approximation de l'atelier : ce
  /// que vous voyez est ce que votre app produirait avec ces valeurs.
  final ThemeData Function(Map<String, Object> tokens, {required bool clair})?
  themeSelon;

  /// Les réglages de design exposés dans le panneau. Vide = pas de panneau.
  final List<AtelierToken> tokens;

  /// LE DESIGN SYSTÈME : les pièces, pas les écrans.
  ///
  /// Des sections comme les autres, mais derrière un bouton plutôt que dans le
  /// mur. Le mur est une CARTE DU PRODUIT, et une galerie de composants n'est
  /// pas une étape du parcours : posée entre deux écrans, elle dilue la carte,
  /// et sa planche écrase les vignettes de téléphone qui l'entourent.
  ///
  /// Vide = pas de bouton, rien ne change.
  final List<AtelierSection> briques;

  @override
  State<Atelier> createState() => _AtelierState();
}

class _AtelierState extends State<Atelier> {
  int _version = 0;
  bool _comparer = false;
  bool _voirBriques = false;

  late final ReglagesAtelier _r = ReglagesAtelier(
    echelle: widget.echelle,
    format: null,
  );

  @override
  void initState() {
    super.initState();
    _r.addListener(_rafraichir);
    _r.charger(widget.tokens);
  }

  @override
  void dispose() {
    _r.removeListener(_rafraichir);
    _r.dispose();
    super.dispose();
  }

  void _rafraichir() {
    if (mounted) setState(() {});
  }

  /// COMBIEN CHAQUE ÉCRAN DÉFILE, en points, dans le format en cours.
  ///
  /// C'est le défaut le plus cher du mur, parce qu'il est INVISIBLE : à 32 %,
  /// une page qui déborde ressemble trait pour trait à une page qui tient. La
  /// vignette montre le haut, et rien ne dit qu'il manque le bas. On valide
  /// alors un écran dont une partie des gens ne verra jamais la fin, ce qui
  /// est exactement le contraire de ce que le mur promet.
  ///
  /// MESURÉ, pas deviné : tout `Scrollable` annonce ses métriques dès sa
  /// première mise en page, et `maxScrollExtent` est précisément « ce qu'il
  /// faut pousser pour atteindre le bas ». Zéro veut dire que tout tient.
  ///
  /// Clé = libellé + format, parce que la réponse dépend des deux : le même
  /// écran déborde sur un petit écran et respire sur un Pro Max.
  final Map<String, double> _defile = {};

  static String _cleDefile(AtelierCase c, AtelierCanvas canvas) =>
      '${c.label}|${canvas.nom}';

  /// Retient le débordement d'un écran, et ne garde que le PLUS GRAND vu.
  ///
  /// Monotone volontairement : la mesure arrive pendant la mise en page, donc
  /// elle déclenche un `setState` qui déclenche une mise en page. Une valeur
  /// qui pourrait redescendre ferait osciller le mur sans jamais se poser ;
  /// une valeur qui ne fait que monter converge en un tour. Et pour la
  /// question posée, « est-ce que ça déborde », le maximum est de toute façon
  /// la bonne statistique.
  void _noteDefilement(String cle, double px) {
    final v = px.roundToDouble();
    if (v <= (_defile[cle] ?? 0)) return;
    _defile[cle] = v;
    // On ne peut pas reconstruire maintenant : on est au milieu d'une mise en
    // page, et `setState` pendant un layout est une erreur Flutter.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  /// Le thème appliqué aux ÉCRANS (pas au chrome de l'atelier, qui reste
  /// neutre : un panneau de réglages illisible parce qu'on vient de pousser
  /// une couleur à l'extrême ne rend service à personne).
  ThemeData? get _themeEcrans =>
      widget.themeSelon?.call({
        for (final t in widget.tokens) t.cle: _r.valeur(t),
      }, clair: _r.clair) ??
      widget.theme;

  /// Les sections après filtrage par la recherche. Une section qui ne contient
  /// plus rien disparaît : un titre suivi du vide se lit comme un bug.
  List<AtelierSection> get _sectionsCourantes => _voirBriques
      ? widget.briques
      : widget.versions[_version.clamp(0, widget.versions.length - 1)].sections;

  List<AtelierSection> get _visibles {
    final q = _r.recherche.trim().toLowerCase();
    final sections = _sectionsCourantes;
    if (q.isEmpty) return sections;
    return [
      for (final s in sections)
        if (s.cases.any((c) => c.label.toLowerCase().contains(q)))
          AtelierSection(s.titre, [
            for (final c in s.cases)
              if (c.label.toLowerCase().contains(q)) c,
          ]),
    ];
  }

  /// Toutes les cases affichées, à plat : c'est sur cette liste que les
  /// flèches de la loupe circulent, donc dans l'ordre où on les voit.
  List<AtelierCase> get _aPlat => [
    for (final s in _visibles)
      if (!_r.repliees.contains(s.titre)) ...s.cases,
  ];

  /// Le canvas d'une case.
  ///
  /// Le format imposé par la barre gagne sur celui de la case, SAUF pour une
  /// planche : forcer une gamme de couleurs en iPhone SE ne répond à aucune
  /// question, et couperait précisément ce qu'on voulait voir en entier.
  AtelierCanvas _canvasDe(AtelierCase c) {
    final propre = c.canvas ?? widget.canvas;
    return propre.estLibre ? propre : (_r.format ?? propre);
  }

  /// Rend une case dans son canvas, avec le thème et les axes en cours.
  ///
  /// [build] remplace le constructeur de la case sans rien changer d'autre :
  /// c'est ce qui sert à rendre une PISTE de cet écran.
  Widget _rendu(
    AtelierCase c, {
    required bool anime,
    Widget Function()? build,
  }) {
    final canvas = _canvasDe(c);
    final theme = _themeEcrans;
    // LE `Builder` N'EST PAS DÉCORATIF. Sans lui, `avant` s'exécuterait en
    // fabriquant la LISTE des vignettes : les quarante crochets tourneraient
    // à la suite, et les quarante écrans se construiraient ensuite, tous avec
    // l'état posé par le DERNIER. Ici, chaque crochet s'exécute au moment où
    // son sous-arbre se construit, donc juste avant l'écran qu'il prépare.
    final ecran = Builder(
      builder: (_) {
        c.avant?.call();
        // `build` PLUTÔT QUE `c.build` : une piste de cette case se rend dans
        // le même canvas, le même thème et le même état préparé que l'écran
        // qu'elle veut remplacer. Comparer deux rendus obtenus dans des
        // conditions différentes ne dirait rien.
        final brut = (build ?? c.build)();
        // L'ENVELOPPE EST DANS LA BRANCHE de la case : son état ne peut donc
        // pas fuir vers la vignette d'à côté, et il reste vrai même si l'écran
        // relit ses données après coup. C'est ce que `avant` ne sait pas
        // faire, et c'est ce qui permet cinq vignettes réellement différentes.
        final e = c.enveloppe?.call(brut) ?? brut;
        // Le thème PAR-DESSUS l'enveloppe : ce qu'elle ajoute (bandeaux,
        // fournisseurs qui construisent des widgets) doit être habillé comme
        // le reste, sinon le mur montre deux styles dans la même vignette.
        return theme == null ? e : Theme(data: theme, child: e);
      },
    );
    // LA MESURE DU DÉBORDEMENT, posée ici et pas dans la vignette : elle doit
    // englober l'écran DÉJÀ enfermé dans son canvas, sinon on mesurerait un
    // écran libre de s'étendre, qui ne déborde jamais.
    //
    // Seul l'axe VERTICAL compte. Une rangée qui défile horizontalement est
    // une intention de design (un carrousel de packs), pas un défaut ; la
    // signaler ferait passer le badge pour du bruit, et un badge qu'on
    // apprend à ignorer ne sert plus à rien.
    final mesure = NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical) {
          _noteDefilement(_cleDefile(c, canvas), n.metrics.maxScrollExtent);
        }
        // `false` : la notification continue de monter. D'autres widgets
        // peuvent l'attendre, et l'atelier n'a pas à leur couper la parole.
        return false;
      },
      child: ecran,
    );
    return _canvas(canvas, mesure, anime: anime);
  }

  @override
  Widget build(BuildContext context) {
    final sections = _visibles;
    final aPlat = _aPlat;
    final surFond =
        ThemeData.estimateBrightnessForColor(widget.fond) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Scaffold(
      backgroundColor: widget.fond,
      endDrawer: widget.tokens.isEmpty
          ? null
          : PanneauTokens(tokens: widget.tokens, reglages: _r),
      appBar: AppBar(
        backgroundColor: widget.fond,
        foregroundColor: surFond,
        elevation: 0,
        titleSpacing: 20,
        toolbarHeight: 56,
        centerTitle: false,
        // UNE SEULE LIGNE pour toute la barre. Le nom, les axes et la
        // recherche étaient répartis sur deux étages sans que rien ne le
        // justifie : la recherche flottait en haut à droite pendant que les
        // réglages vivaient en bas à gauche, et il fallait traverser la page
        // pour passer de l'un à l'autre. Une ligne, et le mur récupère la
        // hauteur perdue.
        title: Row(
          children: [
            // Le nom du mur est une ÉTIQUETTE, pas un titre : il dit où on est
            // et se tait. En blanc plein il devenait le premier point de
            // contraste de la page, avant les écrans qu'on est venu regarder.
            Text(
              widget.titre,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: surFond.withValues(alpha: .7),
              ),
            ),
            const SizedBox(width: 22),
            // LES AXES GLISSENT, la recherche NON : sur une fenêtre étroite ce
            // sont les réglages qui défilent, jamais le champ qui sert à
            // retrouver un écran quand il y en a quarante.
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: _axes(surFond)),
              ),
            ),
            const SizedBox(width: 16),
            _recherche(surFond),
          ],
        ),
        actions: const [SizedBox(width: 20)],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          // LE FILET DU BAS : la barre et le mur partagent le même fond, sans
          // lui rien ne dit où l'un s'arrête et où les écrans commencent.
          child: Container(height: 1, color: surFond.withValues(alpha: .11)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        children: _compare
            ? _corpsCompare(surFond)
            : [
                for (final s in sections) ...[
                  _titre(s, surFond),
                  if (!_r.repliees.contains(s.titre)) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      children: [
                        for (final c in s.cases) _tuile(c, aPlat, surFond),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
                // DEUX VIDES DIFFÉRENTS, deux réponses différentes. Une
                // recherche sans résultat est un non-événement ; un catalogue
                // vide est quelqu'un qui vient d'installer l'outil et ne sait
                // pas quoi faire. Lui montrer une page noire, c'est le perdre
                // au seul moment où il lit vraiment, et à l'endroit exact où
                // il se trouve déjà.
                if (sections.isEmpty)
                  _r.recherche.trim().isEmpty
                      ? _guide(surFond)
                      : Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Text(
                            'Aucun écran ne porte « ${_r.recherche} ».',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: surFond.withValues(alpha: .5),
                            ),
                          ),
                        ),
              ],
      ),
    );
  }

  /// La comparaison n'a de sens qu'a plusieurs versions, et seulement quand on
  /// l'a demandee.
  bool get _compare => _comparer && widget.versions.length > 1 && !_voirBriques;

  /// LE MUR EN VIS-A-VIS : le meme ecran, une colonne par version.
  ///
  /// C'est la que se prend la decision d'une refonte. Un ecran refait parait
  /// toujours meilleur quand on le regarde seul ; c'est cote a cote qu'on voit
  /// s'il l'est vraiment, et surtout ce qu'on a perdu en chemin.
  ///
  /// Les sections et les cases sont l'UNION des versions, dans l'ordre ou
  /// chacune apparait pour la premiere fois. Un ecran qui n'existe que d'un
  /// cote s'affiche donc quand meme, avec un vide en face : c'est une
  /// information, pas une erreur.
  List<Widget> _corpsCompare(Color surFond) {
    final q = _r.recherche.trim().toLowerCase();
    final titres = <String>[];
    for (final v in widget.versions) {
      for (final s in v.sections) {
        if (!titres.contains(s.titre)) titres.add(s.titre);
      }
    }
    final out = <Widget>[];
    for (final titre in titres) {
      final labels = <String>[];
      final parVersion = <String, Map<String, AtelierCase>>{};
      for (final v in widget.versions) {
        final m = <String, AtelierCase>{};
        for (final sec in v.sections.where((x) => x.titre == titre)) {
          for (final c in sec.cases) {
            if (q.isNotEmpty && !c.label.toLowerCase().contains(q)) continue;
            m[c.label] = c;
            if (!labels.contains(c.label)) labels.add(c.label);
          }
        }
        parVersion[v.nom] = m;
      }
      if (labels.isEmpty) continue;
      out.add(_entete(titre, labels.length, surFond));
      if (_r.repliees.contains(titre)) {
        out.add(const SizedBox(height: 24));
        continue;
      }
      out.add(const SizedBox(height: 12));
      out.add(
        Wrap(children: [for (final l in labels) _vis(l, parVersion, surFond)]),
      );
      out.add(const SizedBox(height: 24));
    }
    if (out.isEmpty) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(top: 48),
          child: Text(
            'Aucun ecran ne porte cette recherche.',
            textAlign: TextAlign.center,
            style: TextStyle(color: surFond.withValues(alpha: .5)),
          ),
        ),
      );
    }
    return out;
  }

  /// UN ECRAN, toutes versions cote a cote, sous son libelle.
  Widget _vis(
    String label,
    Map<String, Map<String, AtelierCase>> parVersion,
    Color surFond,
  ) {
    final canvas = _r.format ?? widget.canvas;
    return Padding(
      padding: const EdgeInsets.only(right: 32, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: surFond,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final v in widget.versions)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (parVersion[v.nom]?[label] case final c?)
                        _tuile(c, _aPlat, surFond, sansLabel: true)
                      else
                        _absent(canvas, surFond),
                      const SizedBox(height: 4),
                      Text(
                        v.nom,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: surFond.withValues(alpha: .55),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// LE VIDE EN FACE : cet ecran n'existe pas dans cette version. Le montrer
  /// vaut mieux que de decaler la grille en silence, qui laisserait croire a
  /// une correspondance la ou il n'y en a pas.
  Widget _absent(AtelierCanvas canvas, Color surFond) => Container(
    width: canvas.largeur * _r.echelle,
    // Un vide n'a pas de contenu qui lui donnerait sa hauteur : on lui donne
    // celle d'un écran, faute de mieux, pour qu'il occupe une place crédible.
    height: (canvas.hauteur ?? 844) * _r.echelle,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: surFond.withValues(alpha: .12)),
    ),
    child: Text(
      'absent',
      style: TextStyle(fontSize: 11, color: surFond.withValues(alpha: .35)),
    ),
  );

  Widget _entete(String titre, int n, Color surFond) => InkWell(
    onTap: () => _r.basculerSection(titre),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            _r.repliees.contains(titre)
                ? Icons.chevron_right
                : Icons.expand_more,
            size: 20,
            color: surFond.withValues(alpha: .6),
          ),
          const SizedBox(width: 8),
          Text(
            '${titre.toUpperCase()}  .  $n',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: surFond.withValues(alpha: .6),
            ),
          ),
        ],
      ),
    ),
  );

  // ── LA BARRE ─────────────────────────────────────────────────────────────
  //
  // UN SEUL LANGAGE pour tous les contrôles : même hauteur, même rayon, même
  // cadre à peine visible. Ils cohabitaient sans se ressembler (un champ
  // bordé, un menu nu, un curseur indigo), et le curseur, en couleur d'accent,
  // était l'élément le plus contrasté de la page : le premier endroit où
  // l'œil se posait était un réglage, pas un écran.
  //
  // Toutes les couleurs dérivent de [surFond], donc du fond que l'app a
  // choisi : la barre reste lisible sur clair comme sur sombre sans qu'on ait
  // à la reparamétrer.
  static const double _hControle = 32;

  BoxDecoration _peau(Color surFond, {bool actif = false}) => BoxDecoration(
    borderRadius: BorderRadius.circular(9),
    color: surFond.withValues(alpha: actif ? .16 : .045),
    border: Border.all(color: surFond.withValues(alpha: actif ? .4 : .12)),
  );

  /// Le cadre commun de tous les contrôles.
  Widget _cadre(Color surFond, {required Widget enfant}) => Container(
    height: _hControle,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    alignment: Alignment.center,
    decoration: _peau(surFond),
    child: enfant,
  );

  /// Un filet vertical entre deux groupes : ce qui choisit CE QU'on regarde
  /// d'un côté, ce qui règle COMMENT de l'autre.
  Widget _filet(Color surFond) => Container(
    width: 1,
    height: 18,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: surFond.withValues(alpha: .12),
  );

  /// Un onglet. Volontairement pauvre : le mur doit rester la seule chose
  /// qu'on regarde, la barre n'est qu'un moyen d'y arriver.
  Widget _onglet(
    String texte, {
    required bool actif,
    required VoidCallback onTap,
    required Color surFond,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(9),
    child: Container(
      height: _hControle,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: _peau(surFond, actif: actif),
      child: Text(
        texte,
        style: TextStyle(
          fontSize: 12,
          fontWeight: actif ? FontWeight.w800 : FontWeight.w600,
          color: surFond.withValues(alpha: actif ? 1 : .6),
        ),
      ),
    ),
  );

  /// LA RECHERCHE, seule dans la barre haute : c'est le seul contrôle qui ne
  /// change pas le rendu, il ne fait que raccourcir la liste. Les autres, ceux
  /// qui changent ce qu'on voit, sont ensemble sur la ligne des axes.
  Widget _recherche(Color surFond) => SizedBox(
    width: 210,
    height: _hControle,
    child: TextField(
      style: TextStyle(
        color: surFond,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: surFond,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.only(right: 10),
        hintText: 'Chercher un écran',
        hintStyle: TextStyle(
          color: surFond.withValues(alpha: .35),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.search,
          size: 16,
          color: surFond.withValues(alpha: .4),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: _hControle,
        ),
        filled: true,
        fillColor: surFond.withValues(alpha: .045),
        border: _bord(surFond, .12),
        enabledBorder: _bord(surFond, .12),
        focusedBorder: _bord(surFond, .4),
      ),
      onChanged: (v) => _r.recherche = v,
    ),
  );

  OutlineInputBorder _bord(Color surFond, double alpha) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: BorderSide(color: surFond.withValues(alpha: alpha)),
  );

  /// Format IMPOSÉ : le même mur rejoué en petit, c'est le test de
  /// débordement le plus rapide qui existe.
  Widget _format(Color surFond) => _cadre(
    surFond,
    enfant: DropdownButtonHideUnderline(
      child: DropdownButton<AtelierCanvas?>(
        value: _r.format,
        isDense: true,
        dropdownColor: widget.fond,
        borderRadius: BorderRadius.circular(9),
        icon: Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            Icons.expand_more,
            size: 16,
            color: surFond.withValues(alpha: .45),
          ),
        ),
        // La police vient du THÈME, elle n'est pas repartie de zéro : un
        // `TextStyle` neuf ne merge pas avec l'ambiant, et ce menu écrivait
        // dans une autre fonte que le reste de la barre dès que l'app en
        // imposait une.
        style: (Theme.of(context).textTheme.bodyMedium ?? const TextStyle())
            .copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: surFond.withValues(alpha: .8),
            ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Format : par écran'),
          ),
          for (final c in AtelierCanvas.tous)
            DropdownMenuItem(value: c, child: Text('Format : ${c.nom}')),
        ],
        onChanged: (v) => _r.format = v,
      ),
    ),
  );

  /// L'ÉCHELLE, avec sa valeur écrite. Un curseur nu ne dit pas où on en est :
  /// on ne peut ni retrouver un cadrage, ni en parler à quelqu'un.
  Widget _echelle(Color surFond) => _cadre(
    surFond,
    enfant: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.photo_size_select_small,
          size: 15,
          color: surFond.withValues(alpha: .45),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 118,
          child: SliderTheme(
            // Le curseur en NIVEAUX DE GRIS, pas en couleur d'accent : c'est
            // un réglage, il ne doit jamais gagner contre les écrans.
            data: SliderThemeData(
              trackHeight: 3,
              activeTrackColor: surFond.withValues(alpha: .5),
              inactiveTrackColor: surFond.withValues(alpha: .14),
              thumbColor: surFond.withValues(alpha: .85),
              overlayColor: surFond.withValues(alpha: .08),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              // CLAMP : une app peut passer une echelle de depart hors bornes,
              // et un Slider hors bornes est une assertion, donc un ecran
              // blanc.
              value: _r.echelle.clamp(0.12, 0.8),
              min: 0.12,
              max: 0.8,
              onChanged: (v) => _r.echelle = v,
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Largeur FIXE : sinon passer de 9 % à 10 % décale toute la barre.
        SizedBox(
          width: 32,
          child: Text(
            '${(_r.echelle * 100).round()} %',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: surFond.withValues(alpha: .5),
            ),
          ),
        ),
      ],
    ),
  );

  /// LES AXES : ce qui se règle une fois et s'applique aux quarante écrans.
  ///
  /// Tous sur UNE ligne, dans l'ordre de la question qu'on se pose : quel
  /// design (version), sur quel appareil (format), à quelle taille (échelle),
  /// sous quel thème. Ils étaient répartis entre deux barres selon rien, et la
  /// ligne du bas paraissait vide pendant que celle du haut débordait.
  List<Widget> _axes(Color surFond) => [
    // LES VERSIONS EN PREMIER : c'est le contexte de tout le
    // reste, donc l'onglet est TOUJOURS la, meme seul. Le masquer
    // tant qu'il n'y en a qu'une paraissait plus propre, et
    // c'etait une erreur : on ne sait alors pas quelle version on
    // regarde, ni meme que la notion existe. Un mur sans etiquette
    // laisse croire qu'il n'y a qu'un design possible, exactement
    // ce qu'une refonte doit remettre en question.
    if (!_voirBriques)
      for (var i = 0; i < widget.versions.length; i++)
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _onglet(
            widget.versions[i].nom,
            actif: !_comparer && _version == i,
            onTap: () => setState(() {
              _version = i;
              _comparer = false;
            }),
            surFond: surFond,
          ),
        ),
    // « Comparer », en revanche, n'a de sens qu'a plusieurs : un
    // bouton qui met un ecran face a lui-meme serait une promesse
    // vide.
    if (widget.versions.length > 1 && !_voirBriques)
      Padding(
        padding: const EdgeInsets.only(left: 6),
        child: _onglet(
          'Comparer',
          actif: _comparer,
          onTap: () => setState(() => _comparer = !_comparer),
          surFond: surFond,
        ),
      ),
    _filet(surFond),
    _format(surFond),
    const SizedBox(width: 8),
    _echelle(surFond),
    if (widget.themeSelon != null) ...[
      const SizedBox(width: 8),
      _onglet(
        _r.clair ? 'Thème clair' : 'Thème sombre',
        actif: _r.clair,
        onTap: () => _r.clair = !_r.clair,
        surFond: surFond,
      ),
    ],
    if (widget.briques.isNotEmpty) ...[
      _filet(surFond),
      // LE DESIGN SYSTÈME SORT DU MUR, mais reste à portée : c'est la même
      // passe de travail, on y va vérifier d'où sort un bouton et on revient à
      // l'écran qu'on jugeait.
      _onglet(
        'Design système',
        actif: _voirBriques,
        onTap: () => setState(() {
          _voirBriques = !_voirBriques;
          _comparer = false;
        }),
        surFond: surFond,
      ),
    ],
    if (widget.tokens.isNotEmpty) ...[
      _filet(surFond),
      Builder(
        builder: (c) => _onglet(
          'Tokens',
          actif: false,
          onTap: () => Scaffold.of(c).openEndDrawer(),
          surFond: surFond,
        ),
      ),
    ],
  ];

  /// LE MUR VIDE : ce qu'on voit avant d'avoir rien compris.
  ///
  /// C'est le seul écran de l'atelier qui doit ENSEIGNER quelque chose. Un
  /// catalogue est une liste de libellés et de constructeurs, ça s'explique en
  /// six lignes, et les montrer ici évite d'aller chercher un README qu'on ne
  /// lira pas.
  Widget _guide(Color surFond) => Center(
    child: Padding(
      padding: const EdgeInsets.only(top: 64),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le mur est vide.',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: surFond.withValues(alpha: .9),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Un catalogue, c'est une liste de libellés et de constructeurs. "
              'Un constructeur, jamais un écran déjà fabriqué : la case est '
              'montée deux fois, dans la vignette et dans la loupe.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: surFond.withValues(alpha: .6),
              ),
            ),
            const SizedBox(height: 18),
            _code(surFond, '''
sections: [
  AtelierSection('Parcours', [
    AtelierCase('Accueil', () => const Accueil()),
    AtelierCase('Profil', () => const Profil()),
  ]),
],'''),
            const SizedBox(height: 18),
            Text(
              "Ou laissez-le s'écrire tout seul, à la racine du projet :",
              style: TextStyle(
                fontSize: 13,
                color: surFond.withValues(alpha: .6),
              ),
            ),
            const SizedBox(height: 8),
            _code(surFond, r'dart run atelier:init'),
            const SizedBox(height: 18),
            // LE CAS DU PREMIER CONTACT : `atelier:init` vient de tourner, il
            // a trouvé des écrans, mais tous demandaient des arguments qu'il
            // ne pouvait pas inventer. Le catalogue existe donc, vide, avec la
            // liste en bas du fichier. Sans cette phrase, le mur conseille de
            // lancer la commande qu'on vient justement de lancer.
            Text(
              "Vous venez de lancer `atelier:init` ? Vos écrans demandent "
              "sans doute des arguments : ils vous attendent dans la liste "
              '« À COMPLÉTER », en bas de ce même fichier.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: surFond.withValues(alpha: .6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "Pensez aussi au thème : sans lui, le mur montre des écrans qui "
              'ne sont pas les vôtres.',
              style: TextStyle(
                fontSize: 12,
                color: surFond.withValues(alpha: .4),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _code(Color surFond, String texte) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(9),
      color: surFond.withValues(alpha: .045),
      border: Border.all(color: surFond.withValues(alpha: .12)),
    ),
    child: SelectableText(
      texte,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12.5,
        height: 1.5,
        color: surFond.withValues(alpha: .85),
      ),
    ),
  );

  Widget _titre(AtelierSection s, Color surFond) {
    final repliee = _r.repliees.contains(s.titre);
    return InkWell(
      onTap: () => _r.basculerSection(s.titre),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              repliee ? Icons.chevron_right : Icons.expand_more,
              size: 20,
              color: surFond.withValues(alpha: .6),
            ),
            const SizedBox(width: 8),
            Text(
              '${s.titre.toUpperCase()}  ·  ${s.cases.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: surFond.withValues(alpha: .6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tuile(
    AtelierCase c,
    List<AtelierCase> aPlat,
    Color surFond, {
    bool sansLabel = false,
  }) {
    final canvas = _canvasDe(c);
    final l = canvas.largeur * _r.echelle;
    return Padding(
      padding: const EdgeInsets.only(right: 16, bottom: 16),
      child: SizedBox(
        width: l,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                // OPAQUE, sinon la vignette reste muette : par défaut un
                // GestureDetector délègue la détection à son enfant, et
                // l'enfant est justement un IgnorePointer.
                behavior: HitTestBehavior.opaque,
                onTap: () => ouvrirLoupe(
                  context,
                  cases: aPlat,
                  index: aPlat.indexOf(c),
                  rendu: (x) => _rendu(x, anime: true),
                ),
                child: Container(
                  width: l,
                  // UNE PLANCHE N'A PAS DE HAUTEUR IMPOSÉE : c'est son
                  // contenu qui la donne, et `BoxFit.fitWidth` la met à
                  // l'échelle sans la couper. Lui coller la hauteur d'un
                  // téléphone reviendrait à ce qu'on veut éviter, une gamme de
                  // couleurs dont on ne voit que le premier tiers.
                  height: canvas.estLibre ? null : canvas.hauteur! * _r.echelle,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: surFond.withValues(alpha: .18)),
                  ),
                  child: FittedBox(
                    fit: canvas.estLibre ? BoxFit.fitWidth : BoxFit.fill,
                    // Chaque vignette repeint dans son coin : sans ça, un seul
                    // écran animé forcerait le repaint de tout le mur.
                    child: RepaintBoundary(
                      // On REGARDE le mur : un clic agrandit, il n'actionne
                      // pas le bouton qui se trouve dessous.
                      //
                      // FIGÉ, toujours : quarante écrans qui bouclent en même
                      // temps font tourner le ventilateur sans rien apprendre,
                      // et un clic suffit pour voir l'animation dans la loupe.
                      child: IgnorePointer(child: _rendu(c, anime: false)),
                    ),
                  ),
                ),
              ),
            ),
            if (!sansLabel) ...[
              const SizedBox(height: 4),
              Text(
                c.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: surFond.withValues(alpha: .7),
                ),
              ),
              // CE QUI MANQUE SOUS LA LIGNE DE FLOTTAISON. La vignette montre
              // le haut de l'écran et rien d'autre : sans ce chiffre, un écran
              // qui cache ses mentions légales, son prix ou son bouton
              // derrière 200 points de défilement se valide sans qu'on le
              // sache. Le nombre est en points, la même unité que le canvas,
              // donc il se compare directement à la hauteur affichée.
              if ((_defile[_cleDefile(c, canvas)] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '↕ ${_defile[_cleDefile(c, canvas)]!.toInt()} pt cachés',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      // Ambre plutôt que rouge : ce n'est pas une erreur, un
                      // écran long a parfaitement le droit de défiler. C'est
                      // une chose à REGARDER, et à trancher au cas par cas.
                      color: Color(0xFFFFB020),
                    ),
                  ),
                ),
              // LE REPÈRE DES PISTES, sous le libellé et non sur la vignette :
              // un badge posé sur l'écran cacherait justement ce qu'on est
              // venu regarder.
              if (c.variantes.isNotEmpty)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => ouvrirVariantes(
                      context,
                      cas: c,
                      rendu: (b) => _rendu(c, anime: true, build: b),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 2),
                      child: Text(
                        '${c.variantes.length} '
                        '${c.variantes.length > 1 ? 'pistes' : 'piste'}  ›',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: surFond.withValues(alpha: .45),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Enferme [enfant] dans le canvas demandé : même taille logique, mêmes marges
/// système, et AUCUN agrandissement de texte — le réglage du poste de travail
/// n'a rien à voir avec l'appareil qu'on simule.
Widget _canvas(AtelierCanvas c, Widget enfant, {required bool anime}) {
  final marges = EdgeInsets.only(top: c.safeHaut, bottom: c.safeBas);
  // UNE PLANCHE prend la hauteur de son contenu, BORNÉE. Un contenu qui se
  // mesure prend ce qu'il lui faut ; un `Scaffold` ou une `ListView`
  // essaieraient de remplir l'infini et feraient planter le rendu, alors ils
  // prennent la borne. La taille annoncée à MediaQuery est la même, sinon un
  // widget qui calcule sur `MediaQuery.height` travaillerait sur une valeur
  // que sa boîte ne lui donnera jamais.
  final h = c.hauteur;
  return MediaQuery(
    data: MediaQueryData(
      size: Size(c.largeur, h ?? c.hauteurMax),
      devicePixelRatio: 1,
      textScaler: TextScaler.noScaling,
      padding: marges,
      viewPadding: marges,
      disableAnimations: !anime,
    ),
    child: SizedBox(
      width: c.largeur,
      height: h,
      // LE NAVIGATEUR LOCAL EST RÉSERVÉ AUX ÉCRANS À HAUTEUR FIXE.
      //
      // Un `Navigator` porte un `Overlay`, et un `Overlay` ne sait pas se
      // dimensionner sous une contrainte de hauteur infinie : sur une planche,
      // il jette. Ce n'est pas une perte : une planche est une galerie de
      // composants, elle ne pousse jamais de route.
      child: h != null
          ? _navigateurLocal(enfant)
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: c.hauteurMax),
              child: enfant,
            ),
    ),
  );
}

/// UN NAVIGATEUR PAR ÉCRAN, pour que ce qu'il pousse reste dans son téléphone.
///
/// Sans lui, `Navigator.push` remonte jusqu'au navigateur de l'atelier :
/// l'écran poussé recouvre TOUTE la fenêtre, canvas compris, et on juge une
/// feuille de recadrage étalée sur un écran d'ordinateur alors qu'elle vivra
/// dans un téléphone. Constaté sur KITADI le 31/07/2026, et ça vaut pour
/// n'importe quel écran qui ouvre une feuille, un sélecteur ou une boîte de
/// dialogue en route.
///
/// `onGenerateRoute` sert l'écran comme route initiale, et tout ce qu'il pousse
/// ensuite s'empile PAR-DESSUS lui, dans la même boîte.
///
/// ⚠️ Ne concerne QUE `Navigator` : un routeur d'application (GoRouter et
/// consorts) garde le sien, il n'y a rien à faire pour l'en empêcher. Un écran
/// qui appelle `context.go()` sortira toujours du mur, et c'est normal : ce
/// n'est plus le même écran qu'on regarde.
Widget _navigateurLocal(Widget enfant) => _Socle(
  ecran: enfant,
  child: Navigator(
    onGenerateRoute: (_) => PageRouteBuilder(
      // SANS TRANSITION ni fond opaque : la route initiale n'est pas une
      // navigation, c'est juste le socle. Une animation ici ferait clignoter
      // les quarante vignettes du mur à chaque reconstruction.
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      opaque: false,
      pageBuilder: (c, _, _) => _Socle.de(c),
    ),
  ),
);

/// L'ÉCRAN COURANT, LU DEPUIS LA ROUTE et non capturé par elle.
///
/// Sans ce détour, `pageBuilder` refermerait sur l'écran du moment : la route
/// est construite une fois, donc l'écran cesserait de réagir à tout ce que le
/// mur change autour de lui, à commencer par les tokens et le thème. Les tests
/// l'ont attrapé tout de suite (`tokens_test.dart`), en constatant qu'un rayon
/// réglé dans le panneau ne bougeait plus dans la vignette.
///
/// Ici la route DÉPEND de cet héritage : quand le mur se reconstruit avec un
/// nouvel écran, la dépendance se déclenche et la route se reconstruit avec.
class _Socle extends InheritedWidget {
  const _Socle({required this.ecran, required super.child});

  final Widget ecran;

  static Widget de(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<_Socle>()!.ecran;

  @override
  bool updateShouldNotify(_Socle ancien) => !identical(ancien.ecran, ecran);
}
