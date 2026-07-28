/// `dart run atelier:init` — écrit un premier `tool/atelier.dart` d'après vos
/// écrans, pour qu'on voie son app tout de suite au lieu de taper trente
/// lignes à l'aveugle.
///
/// Options :
///   --force     écrase un catalogue existant (refusé par défaut)
///   --lib=…     dossier à balayer (`lib` par défaut)
///   --out=…     fichier à écrire (`tool/atelier.dart` par défaut)
library;

import 'dart:convert';
import 'dart:io';

import 'package:atelier/src/generateur.dart';

void main(List<String> args) {
  final force = args.contains('--force');
  final dossier = _option(args, '--lib') ?? 'lib';
  final sortie = _option(args, '--out') ?? 'tool/atelier.dart';

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    _stop('Pas de pubspec.yaml ici. Lancez la commande à la racine du projet.');
  }
  final nom = RegExp(
    r'^name:\s*(\S+)',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync())?.group(1);
  if (nom == null) _stop('pubspec.yaml sans champ `name`.');

  final racine = Directory(dossier);
  if (!racine.existsSync()) _stop('Dossier introuvable : $dossier');

  final ecrans = <EcranTrouve>[];
  for (final f in racine.listSync(recursive: true).whereType<File>()) {
    final chemin = f.path.replaceAll(r'\', '/');
    if (!chemin.endsWith('.dart')) continue;
    // Le code ENGENDRÉ n'a rien à faire au mur : il ne contient pas d'écran,
    // et le balayer ne ferait que du bruit.
    if (chemin.endsWith('.g.dart') ||
        chemin.endsWith('.freezed.dart') ||
        chemin.endsWith('.gr.dart')) {
      continue;
    }
    final relatif = chemin.substring(
      chemin.indexOf('$dossier/') + dossier.length + 1,
    );
    ecrans.addAll(ecransDuFichier(f.readAsStringSync(), relatif));
  }

  if (ecrans.isEmpty) {
    _stop(
      'Aucun écran trouvé dans $dossier/.\n'
      'Le générateur cherche des classes dont le nom finit par Screen, Page '
      'ou View. Si les vôtres s\'appellent autrement, écrivez le catalogue à '
      'la main : c\'est une liste de libellés et de constructeurs, rien de '
      'plus (cf. le README).',
    );
  }

  final fichier = File(sortie);
  if (fichier.existsSync() && !force) {
    _stop(
      '$sortie existe déjà, je n\'y touche pas.\n'
      'Relancez avec --force pour l\'écraser, ou --out=autre_fichier.dart '
      'pour comparer avant de remplacer.',
    );
  }
  fichier.parent.createSync(recursive: true);
  fichier.writeAsStringSync(catalogue(paquet: nom, ecrans: ecrans));

  // LE MODE D'EMPLOI DE L'AGENT, posé là où il ira le chercher. Celui qui
  // installe l'atelier ne lira pas le README, il demandera à son assistant :
  // autant que l'assistant sache. Jamais écrasé sans `--force`, on ne touche
  // pas à un fichier que quelqu'un a peut-être adapté.
  final skillFichier = File('.claude/skills/atelier/SKILL.md');
  final skillEcrit = !skillFichier.existsSync() || force;
  if (skillEcrit) {
    skillFichier.parent.createSync(recursive: true);
    skillFichier.writeAsStringSync(skill());
  }

  final lancement = _lancement(sortie);

  final commentes = ecrans.where((e) => !e.constructible).length;
  stdout
    ..writeln('$sortie écrit : ${ecrans.length} écrans.')
    ..writeln(switch (commentes) {
      0 => 'Tous se construisent seuls.',
      // TOUS a completer : le mur s'ouvrira VIDE, et sans cette phrase la
      // personne croira que l'outil n'a rien trouve.
      _ when commentes == ecrans.length =>
        'Aucun ne se construit seul : ils demandent tous des arguments que '
            'je ne peux pas inventer. Ouvrez $sortie, la liste « A '
            'COMPLETER » est en bas, donnez-leur des valeurs de demo. Sans '
            'ca le mur s\'ouvrira vide.',
      _ =>
        '$commentes en commentaire (ils demandent des arguments que je ne '
            'peux pas inventer).',
    })
    ..writeln(
      skillEcrit
          ? '.claude/skills/atelier/SKILL.md écrit : votre assistant connaît '
                'maintenant la boucle (changement direct, pistes, versions).'
          : '.claude/skills/atelier/SKILL.md existe déjà, laissé tel quel.',
    )
    ..writeln(lancement)
    ..writeln()
    ..writeln('Dites « ouvre l\'atelier » à votre assistant, ou lancez :')
    ..writeln()
    ..writeln('  flutter run -d web-server --web-port 8081 -t $sortie')
    ..writeln()
    ..writeln(
      'Ajoutez ensuite votre thème dans ce fichier : sans lui, le mur montre '
      'des écrans qui ne sont pas les vôtres.',
    );
}

/// LA CONFIG DE LANCEMENT, pour que l'assistant ouvre le mur tout seul.
///
/// Sans elle, la seule façon de voir le mur est de taper une commande de
/// soixante caractères, et le premier réflexe de quelqu'un qui installe
/// l'outil n'est pas d'aller la chercher dans un README. Avec elle, « ouvre
/// l'atelier » suffit.
///
/// FUSION, jamais écrasement : ce fichier appartient au projet, il contient
/// peut-être déjà le serveur de dev de l'app. Un fichier illisible est laissé
/// tel quel plutôt que remplacé, on ne détruit pas ce qu'on ne comprend pas.
String _lancement(String cible) {
  final f = File('.claude/launch.json');
  const nom = 'atelier';
  Map<String, dynamic> conf = {'version': '0.0.1', 'configurations': []};

  if (f.existsSync()) {
    try {
      conf = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return '.claude/launch.json illisible, laissé tel quel.';
    }
  }

  final configs = (conf['configurations'] as List?) ?? [];
  if (configs.any((c) => c is Map && c['name'] == nom)) {
    return '.claude/launch.json a déjà « $nom », laissé tel quel.';
  }

  configs.add({
    'name': nom,
    'runtimeExecutable': 'flutter',
    'runtimeArgs': [
      'run',
      '-d',
      'web-server',
      '-t',
      cible,
      '--web-hostname',
      '127.0.0.1',
      '--web-port',
      '8081',
    ],
    'port': 8081,
  });
  conf['configurations'] = configs;

  f.parent.createSync(recursive: true);
  f.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(conf)}\n');
  return '.claude/launch.json : « $nom » ajouté, votre assistant sait '
      'ouvrir le mur.';
}

String? _option(List<String> args, String cle) {
  for (final a in args) {
    if (a.startsWith('$cle=')) return a.substring(cle.length + 1);
  }
  return null;
}

Never _stop(String message) {
  stderr.writeln(message);
  exit(1);
}
