import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;

import 'package:atelier/src/modele.dart';

/// LES PISTES D'UN ÉCRAN, côte à côte, en grand.
///
/// C'est le moment de la décision, et il demande le vis-à-vis : une piste
/// regardée seule paraît toujours bonne, c'est à côté de l'actuelle qu'on voit
/// ce qu'elle apporte et surtout ce qu'elle coûte.
///
/// L'ACTUELLE EST TOUJOURS LÀ, en premier. Comparer trois brouillons entre eux
/// sans l'écran qui existe déjà, c'est choisir le meilleur des trois sans
/// jamais se demander s'il vaut mieux que ce qu'on a.
void ouvrirVariantes(
  BuildContext context, {
  required AtelierCase cas,
  required Widget Function(Widget Function() build) rendu,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black.withValues(alpha: .9),
      pageBuilder: (_, _, _) => _Variantes(cas: cas, rendu: rendu),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _Variantes extends StatelessWidget {
  const _Variantes({required this.cas, required this.rendu});

  final AtelierCase cas;
  final Widget Function(Widget Function() build) rendu;

  @override
  Widget build(BuildContext context) {
    final pistes = <(String, Widget Function())>[
      ('Actuel', cas.build),
      for (final v in cas.variantes) (v.nom, v.build),
    ];
    return Focus(
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.escape) {
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
            Positioned.fill(
              child: GestureDetector(onTap: () => Navigator.of(context).pop()),
            ),
            // FittedBox : trois canvas côte à côte font largement plus qu'une
            // fenêtre. On rétrécit l'ensemble d'un bloc, jamais une piste plus
            // qu'une autre, sinon la comparaison ne veut plus rien dire.
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 64, 48, 32),
              child: FittedBox(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < pistes.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          right: i == pistes.length - 1 ? 0 : 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: rendu(pistes[i].$2),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pistes[i].$1,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                // L'actuelle en retrait : c'est le point de
                                // comparaison, pas une candidate.
                                color: Colors.white.withValues(
                                  alpha: i == 0 ? .5 : .95,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 20,
              child: Text(
                '${cas.label}   ${cas.variantes.length} '
                '${cas.variantes.length > 1 ? 'pistes' : 'piste'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
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
          ],
        ),
      ),
    );
  }
}
