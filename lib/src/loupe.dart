import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;

import 'package:atelier/src/modele.dart';

/// LA LOUPE : la case cliquée, à taille réelle et VIVANTE (animations rendues,
/// gestes acceptés). Le mur fait remarquer, la loupe fait vérifier.
///
/// Les flèches gauche/droite passent à la case suivante SANS repasser par le
/// mur : comparer deux écrans, c'est les voir l'un après l'autre au même
/// endroit de l'écran, pas les chercher deux fois dans une grille.
void ouvrirLoupe(
  BuildContext context, {
  required List<AtelierCase> cases,
  required int index,
  required Widget Function(AtelierCase) rendu,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: .88),
      pageBuilder: (_, _, _) =>
          _Loupe(cases: cases, index: index, rendu: rendu),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _Loupe extends StatefulWidget {
  const _Loupe({required this.cases, required this.index, required this.rendu});

  final List<AtelierCase> cases;
  final int index;
  final Widget Function(AtelierCase) rendu;

  @override
  State<_Loupe> createState() => _LoupeState();
}

class _LoupeState extends State<_Loupe> {
  late int _i = widget.index;

  void _bouger(int pas) {
    setState(() => _i = (_i + pas) % widget.cases.length);
    if (_i < 0) setState(() => _i += widget.cases.length);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cases[_i];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          _bouger(1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _bouger(-1);
          return KeyEventResult.handled;
        }
        if (e.logicalKey == LogicalKeyboardKey.escape) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Le fond ferme : sur un mur on entre et on sort d'un écran sans
            // arrêt, viser une croix à chaque fois serait une corvée.
            Positioned.fill(
              child: GestureDetector(onTap: () => Navigator.of(context).pop()),
            ),
            // FittedBox : sur une fenêtre plus courte que le canvas, l'écran
            // rétrécit en entier plutôt que de se faire couper en bas.
            Center(
              child: FittedBox(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  // KEY : sans elle, passer d'une case à l'autre réutilise
                  // l'état de la précédente (un champ rempli, une animation
                  // en cours) et on juge un écran qui n'existe pas.
                  child: KeyedSubtree(
                    key: ValueKey(_i),
                    child: widget.rendu(c),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 20,
              child: Row(
                children: [
                  Text(
                    '${c.label}   ${_i + 1}/${widget.cases.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // LE BOUTON DE LA CASE, s'il en a un. Il vit ICI et pas dans
                  // l'écran : un outil pour juger n'a rien à faire par-dessus
                  // ce qu'on juge. Cf. `AtelierCase.action`.
                  if (c.action != null) ...[
                    const SizedBox(width: 14),
                    c.action!(() => setState(() {})),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              left: 8,
              child: _fleche(Icons.chevron_left, () => _bouger(-1)),
            ),
            Positioned(
              right: 8,
              child: _fleche(Icons.chevron_right, () => _bouger(1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fleche(IconData icone, VoidCallback onTap) => IconButton(
    onPressed: onTap,
    iconSize: 40,
    icon: Icon(icone, color: Colors.white.withValues(alpha: .7)),
  );
}
