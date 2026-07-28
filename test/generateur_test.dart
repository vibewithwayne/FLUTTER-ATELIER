import 'package:atelier/src/generateur.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ce qui est testé ici, c'est ce que le générateur PROMET, pas la façon dont
/// il lit le Dart : il lit du texte, il se trompera, et c'est assumé. En
/// revanche, ce qu'il écrit doit toujours COMPILER. Une ligne morte au milieu
/// d'un fichier de démarrage, et la personne voit une erreur avant son
/// premier écran, ce qui est exactement le contraire du but.
void main() {
  const source = '''
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class PackDetailScreen extends StatefulWidget {
  const PackDetailScreen({super.key, required this.packId});
  final String packId;
  @override
  State<PackDetailScreen> createState() => _PackDetailScreenState();
}

class _PackDetailScreenState extends State<PackDetailScreen> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _RotateScreen extends StatelessWidget {
  const _RotateScreen();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class StickerButton extends StatelessWidget {
  const StickerButton({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

abstract class BaseScreen extends StatelessWidget {
  const BaseScreen({super.key});
}

class ListePage<T> extends StatelessWidget {
  const ListePage({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''';

  test('repère les écrans, et seulement eux', () {
    final trouves = ecransDuFichier(source, 'features/home/home_screen.dart');
    final noms = trouves.map((e) => e.classe).toList();

    expect(noms, contains('HomeScreen'));
    expect(noms, contains('PackDetailScreen'));
    // Une classe PRIVÉE ne s'importe pas depuis `tool/` : la mettre au
    // catalogue ferait échouer la compilation du fichier entier.
    expect(noms, isNot(contains('_RotateScreen')));
    // Sans le suffixe on ramasserait chaque bouton, et le mur deviendrait un
    // inventaire de widgets au lieu d'une vue de l'app.
    expect(noms, isNot(contains('StickerButton')));
    // Une classe ABSTRAITE ne se construit pas : au catalogue, elle casserait
    // la compilation du fichier de demarrage, ce qui est la seule chose que le
    // generateur promet de ne jamais faire.
    expect(noms, isNot(contains('BaseScreen')));
    // Un parametre de type se declare mais ne s'ecrit pas a la construction.
    expect(noms, contains('ListePage'));
  });

  test('sait ce qui se construit tout seul', () {
    final trouves = ecransDuFichier(source, 'features/home/home_screen.dart');
    final home = trouves.firstWhere((e) => e.classe == 'HomeScreen');
    final pack = trouves.firstWhere((e) => e.classe == 'PackDetailScreen');

    expect(home.constructible, isTrue);
    expect(home.constant, isTrue, reason: 'const HomeScreen({super.key})');
    // La clé de widget ne compte pas : elle est toujours facultative.
    expect(home.manque, isEmpty);

    expect(pack.constructible, isFalse);
    expect(pack.manque, ['packId']);
  });

  test('les libellés et les sections viennent du code', () {
    expect(libelleDepuisClasse('ProfileSetupScreen'), 'Profile Setup');
    expect(libelleDepuisClasse('HomeScreen'), 'Home');
    // L'arborescence dit déjà comment le projet est rangé, autant s'en servir.
    expect(
      sectionDepuisChemin('features/boutique/pack_screen.dart'),
      'Boutique',
    );
    expect(sectionDepuisChemin('screens/login_screen.dart'), 'Screens');
  });

  test('le fichier écrit compile : rien de mort dans le catalogue', () {
    final ecrans = ecransDuFichier(source, 'features/store/pack_screen.dart');
    final out = catalogue(paquet: 'monapp', ecrans: ecrans);

    expect(out, contains("AtelierCase('Home', () => const HomeScreen())"));
    // L'écran incomplet ne doit PAS être dans la liste des sections, sinon la
    // ligne ne compile pas. Il part en liste de courses, à la fin.
    expect(out.split('// ── À COMPLÉTER').first, isNot(contains('PackDetail')));
    expect(out, contains('// ── À COMPLÉTER'));
    expect(out, contains('PackDetailScreen(packId: /* ? */)'));
  });

  test('un fichier tout en commentaires ne laisse pas un import orphelin', () {
    const rienDeConstructible = '''
class CropScreen extends StatelessWidget {
  const CropScreen({super.key, required this.bytes});
  final List<int> bytes;
}
''';
    final out = catalogue(
      paquet: 'monapp',
      ecrans: ecransDuFichier(rienDeConstructible, 'profile/crop_screen.dart'),
    );
    // Importer un fichier dont toutes les cases sont commentées donnerait un
    // avertissement à la première ouverture du projet.
    expect(out, isNot(contains("import 'package:monapp/profile/crop_screen")));
  });
}
