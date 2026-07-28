import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

import 'package:atelier/src/modele.dart';
import 'package:atelier/src/reglages.dart';

/// LE PANNEAU DE TOKENS : régler la couleur, l'espacement ou le rayon, et voir
/// les quarante écrans changer en même temps.
///
/// C'est la raison d'être du mur poussée à son terme. Regarder tous les écrans
/// ensemble permet de VOIR qu'une couleur ne va pas ; les régler tous ensemble
/// permet d'en SORTIR, sans faire l'aller-retour éditeur / recompilation /
/// « où était cet écran déjà ».
///
/// Le bouton d'export rend le Dart correspondant : le mur sert à décider, le
/// code reste la source de vérité. Rien n'est écrit dans vos fichiers.
class PanneauTokens extends StatelessWidget {
  const PanneauTokens({
    super.key,
    required this.tokens,
    required this.reglages,
  });

  final List<AtelierToken> tokens;
  final ReglagesAtelier reglages;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 340,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TOKENS',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: reglages.reinitialiserTokens,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final t in tokens) _ligne(context, t),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _exporter(context),
                icon: const Icon(Icons.code),
                label: const Text('Exporter le Dart'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ligne(BuildContext context, AtelierToken t) => switch (t) {
    TokenCouleur() => _couleur(context, t),
    TokenNombre() => _nombre(t),
  };

  Widget _couleur(BuildContext context, TokenCouleur t) {
    final valeur = reglages.valeur(t) as Color;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.libelle, style: const TextStyle(fontSize: 13)),
                Text(
                  _hex(valeur),
                  style: TextStyle(
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _choisirCouleur(context, t, valeur),
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: valeur,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _nombre(TokenNombre t) {
    final valeur = reglages.valeur(t) as double;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${t.libelle}   ${valeur.toStringAsFixed(valeur % 1 == 0 ? 0 : 1)}',
            style: const TextStyle(fontSize: 13),
          ),
          Slider(
            value: valeur.clamp(t.min, t.max),
            min: t.min,
            max: t.max,
            onChanged: (v) => reglages.poserToken(t.cle, v),
          ),
        ],
      ),
    );
  }

  /// Palette FIXE plutôt qu'une roue chromatique : on ne cherche pas la teinte
  /// parfaite au pixel près dans un outil de décision, on compare des
  /// candidats. La valeur exacte se met au propre dans le code.
  void _choisirCouleur(BuildContext context, TokenCouleur t, Color actuelle) {
    const teintes = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.blueGrey,
    ];
    const nuances = [900, 800, 700, 600, 500, 400, 300, 200, 100];
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(t.libelle),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final teinte in teintes)
                  Row(
                    children: [
                      for (final n in nuances)
                        _pastille(c, t, teinte[n] ?? teinte),
                    ],
                  ),
                Row(
                  children: [
                    for (final g in const [
                      Colors.white,
                      Color(0xFFE0E0E0),
                      Color(0xFF9E9E9E),
                      Color(0xFF424242),
                      Color(0xFF212121),
                      Colors.black,
                      Color(0xFF0D2E1C),
                      Color(0xFF0B0B0D),
                      Color(0xFFF5F0E8),
                    ])
                      _pastille(c, t, g),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pastille(BuildContext context, TokenCouleur t, Color c) => InkWell(
    onTap: () {
      reglages.poserToken(t.cle, c);
      Navigator.of(context).pop();
    },
    child: Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
    ),
  );

  void _exporter(BuildContext context) {
    final lignes = <String>[
      '// Tokens retenus dans l\'atelier.',
      '// À reporter dans votre fichier de thème : c\'est le code qui fait foi,',
      '// pas le mur.',
    ];
    for (final t in tokens) {
      final v = reglages.valeur(t);
      lignes.add(
        v is Color
            ? 'const ${t.cle} = Color(0x${_hex(v).substring(1)});'
            : 'const ${t.cle} = ${(v as double).toStringAsFixed(1)};',
      );
    }
    final dart = lignes.join('\n');
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tokens'),
        content: SizedBox(
          width: 520,
          child: SelectableText(
            dart,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: dart));
              Navigator.of(c).pop();
            },
            child: const Text('Copier'),
          ),
        ],
      ),
    );
  }

  static String _hex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
