import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:atelier/src/modele.dart';

/// LES RÉGLAGES DU MUR, retenus d'une session à l'autre.
///
/// Retrouver son échelle, ses sections repliées et ses tokens en rouvrant
/// l'atelier n'est pas du confort : c'est ce qui permet de reprendre une
/// décision de design là où on l'avait laissée, au lieu de tout re-régler
/// avant de pouvoir regarder.
///
/// Tout est préfixé `atelier.` : rien ne peut entrer en collision avec les
/// clés de l'app qui héberge l'outil.
///
/// ⚠️ Si votre point d'entrée moque le stockage
/// (`SharedPreferences.setMockInitialValues`), rien ne survit au
/// rechargement : c'est le stockage moqué qui repart de zéro, pas l'atelier.
class ReglagesAtelier extends ChangeNotifier {
  ReglagesAtelier({required double echelle, required AtelierCanvas? format})
    : _echelle = echelle,
      _format = format;

  static const _prefixe = 'atelier.';

  SharedPreferences? _prefs;

  double _echelle;
  AtelierCanvas? _format;
  bool _clair = false;
  String _recherche = '';
  Set<String> _repliees = {};
  final Map<String, Object> _tokens = {};

  double get echelle => _echelle;

  /// Format IMPOSÉ à toutes les cases (`null` = chacune garde le sien).
  AtelierCanvas? get format => _format;

  /// Thème alternatif en cours (quand l'app en fournit un).
  bool get clair => _clair;

  String get recherche => _recherche;
  Set<String> get repliees => _repliees;

  /// Valeurs courantes des tokens (vide = valeurs par défaut).
  Map<String, Object> get tokens => _tokens;

  Future<void> charger(List<AtelierToken> declares) async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (_) {
      return; // pas de stockage : on tourne sans mémoire, sans échouer
    }
    final p = _prefs!;
    _echelle = p.getDouble('${_prefixe}echelle') ?? _echelle;
    _clair = p.getBool('${_prefixe}clair') ?? _clair;
    _repliees = (p.getStringList('${_prefixe}repliees') ?? const []).toSet();
    final nomFormat = p.getString('${_prefixe}format');
    if (nomFormat != null) {
      for (final c in AtelierCanvas.tous) {
        if (c.nom == nomFormat) _format = c;
      }
    }
    // Les tokens sont rangés en JSON : les couleurs en entier, les nombres en
    // double. On ne relit QUE les clés encore déclarées, sinon un token retiré
    // du code ressusciterait à chaque lancement.
    final brut = p.getString('${_prefixe}tokens');
    if (brut != null) {
      try {
        final json = jsonDecode(brut) as Map<String, dynamic>;
        for (final t in declares) {
          final v = json[t.cle];
          if (v == null) continue;
          if (t is TokenCouleur && v is int) _tokens[t.cle] = Color(v);
          if (t is TokenNombre && v is num) _tokens[t.cle] = v.toDouble();
        }
      } catch (_) {
        /* réglage illisible : valeurs par défaut */
      }
    }
    notifyListeners();
  }

  void _ecrire(void Function(SharedPreferences p) f) {
    notifyListeners();
    final p = _prefs;
    if (p != null) f(p);
  }

  set echelle(double v) => _ecrire((p) {
    _echelle = v;
    p.setDouble('${_prefixe}echelle', v);
  });

  set clair(bool v) => _ecrire((p) {
    _clair = v;
    p.setBool('${_prefixe}clair', v);
  });

  set format(AtelierCanvas? v) => _ecrire((p) {
    _format = v;
    if (v == null) {
      p.remove('${_prefixe}format');
    } else {
      p.setString('${_prefixe}format', v.nom);
    }
  });

  /// La recherche ne se retient PAS : on la tape pour trouver une case, pas
  /// pour s'installer dedans. La retrouver au lancement suivant donnerait un
  /// mur à moitié vide sans qu'on comprenne pourquoi.
  set recherche(String v) {
    _recherche = v;
    notifyListeners();
  }

  void basculerSection(String titre) => _ecrire((p) {
    _repliees.contains(titre) ? _repliees.remove(titre) : _repliees.add(titre);
    p.setStringList('${_prefixe}repliees', _repliees.toList());
  });

  void poserToken(String cle, Object valeur) => _ecrire((p) {
    _tokens[cle] = valeur;
    p.setString('${_prefixe}tokens', _jsonTokens());
  });

  void reinitialiserTokens() => _ecrire((p) {
    _tokens.clear();
    p.remove('${_prefixe}tokens');
  });

  String _jsonTokens() => jsonEncode({
    for (final e in _tokens.entries)
      e.key: e.value is Color ? (e.value as Color).toARGB32() : e.value,
  });

  /// Valeur courante d'un token : celle qu'on a réglée, sinon celle du code.
  Object valeur(AtelierToken t) => _tokens[t.cle] ?? t.defaut;
}
