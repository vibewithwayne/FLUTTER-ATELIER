# Changelog

## 0.12.1

Premiere installation sur un projet VIERGE, et elle a montre son trou : sur une
app fraiche de `flutter create`, le seul ecran demande un argument, donc tout
part en « A completer » et le mur s'ouvre VIDE. L'ecran d'accueil conseillait
alors de lancer `atelier:init`, c'est-a-dire la commande qu'on venait de
lancer.

- La commande le dit quand AUCUN ecran ne se construit seul, et ou aller.
- Le mur vide ajoute le cas : vos ecrans demandent peut-etre des arguments, la
  liste vous attend en bas du fichier.
- Les lignes a completer montrent un vrai marqueur (`title: /* ? */`) au lieu
  d'un parametre vide qu'on croirait pret a decommenter.

## 0.12.0

- `atelier:init` ecrit aussi `.claude/launch.json` : « ouvre l'atelier » suffit
  desormais, plus besoin de retenir une commande de soixante caracteres. Le
  fichier est FUSIONNE, jamais ecrase, et laisse tel quel s'il est illisible.
- L'installation du README devient une phrase a coller a son assistant. C'est
  la forme que prend une installation quand on code en parlant.

## 0.11.3

- Le README est refait pour celui qui INSTALLE : installer, ce qu'on dit a son
  assistant, ce qu'on fait quand ca coince. Il expliquait le produit en trois
  cents lignes, ce que personne ne lit avant de s'en servir.
- Ce qui en sort n'est pas perdu : les planches, le design systeme et les
  tokens rejoignent le `SKILL.md`, c'est-a-dire le lecteur qui en a vraiment
  besoin.

## 0.11.2

Une passe de VERIFICATION, pas de fonctionnalites : trois promesses du paquet
n'etaient tenues que sur un seul projet, le mien.

- **Le generateur ecartait mal les classes non constructibles.** Un
  `abstract class BaseScreen extends StatelessWidget` atterrissait au
  catalogue et le fichier de demarrage ne compilait plus, ce qui est la seule
  chose que ce generateur promet de ne jamais faire. Les classes `abstract` et
  `sealed` sont ecartees, et les classes a parametre de type
  (`class ListePage<T>`) sont enfin reconnues.
- **`enveloppe` est prouve avec Provider ET Riverpod.** La promesse « ca marche
  avec tout ce qui passe par le contexte » n'etait verifiee qu'avec un
  `InheritedWidget` maison, c'est-a-dire avec le seul cas que j'avais ecrit
  moi-meme. Les deux paquets sont en `dev_dependencies` : personne n'a a les
  installer pour se servir de l'atelier.
- **Le panneau de tokens est teste de bout en bout.** C'etait la fonctionnalite
  la plus ambitieuse et la seule qui n'avait jamais servi une fois : sur l'app
  qui heberge l'outil, les couleurs sont des `static const`, donc le panneau y
  est inactif depuis le premier jour. On regle maintenant un curseur et une
  couleur DANS le panneau, et on verifie que l'ecran du mur a change.

## 0.11.1

- Le `SKILL.md` deconseille les sections qui doublent un reglage de la barre,
  « Formats » en tete : le selecteur rejoue deja tout le mur dans la taille
  voulue, sur tous les ecrans plutot que sur trois choisis a la main. Une
  section pareille coute des vignettes en permanence pour une question deja
  repondue.

## 0.11.0

- **`briques`** : le design systeme sort du mur et passe derriere un bouton de
  la barre. Ce sont les memes sections, les memes cases, la meme recherche ;
  seul l'endroit change. Le mur est une CARTE DU PRODUIT, une galerie de
  composants n'en est pas une etape : posee entre deux ecrans elle dilue la
  carte, et sa planche ecrase les vignettes de telephone autour.
- Les onglets de version et « Comparer » disparaissent dans cette vue : on y
  regarde des pieces, pas un design d'ensemble.
- Rien n'est declare en double : c'est le meme catalogue, deplace d'un champ.

## 0.10.2

- Le `SKILL.md` depose par `init` explique deux choses que le generateur ne
  peut pas deviner : que les sections sont une CARTE DU PRODUIT et non un
  miroir des dossiers (rangees dans l'ordre de l'utilisateur, coupees des
  qu'une section depasse sept ou huit vignettes), et que le mur tourne dans un
  navigateur, donc qu'il faut forcer les branches de plateforme et semer des
  donnees de demo. Sans ca, on juge le design d'un produit qui n'est pas celui
  qu'on publie.

## 0.10.1

- Le catalogue genere s'intitule « Atelier » et non « Monprojet . Atelier » :
  c'est le nom de l'outil, pas celui du projet, et on sait quel projet on
  regarde puisqu'on est dedans.

## 0.10.0

- **La barre tient sur une seule ligne.** Le nom, les axes et la recherche
  etaient repartis sur deux etages sans que rien ne le justifie : la recherche
  flottait en haut a droite pendant que les reglages vivaient en bas a gauche,
  et il fallait traverser la page pour passer de l'un a l'autre. Le mur
  recupere la hauteur perdue.
- Sur une fenetre etroite, ce sont les AXES qui glissent, jamais la recherche :
  le champ qui sert a retrouver un ecran quand il y en a quarante ne doit pas
  pouvoir sortir du cadre.

## 0.9.1

- La planche faisait planter le mur ENTIER sur un ecran qui s'etire (`Scaffold`,
  `ListView`) : sans hauteur imposee, il essayait de remplir l'infini. Une
  galerie de composants est justement souvent ecrite comme ca. La hauteur libre
  est desormais bornee (`hauteurMax`, 4000 par defaut) : un contenu qui se
  mesure prend ce qu'il lui faut, un contenu qui s'etire prend la borne. Trouve
  dans le navigateur, et par aucun des vingt et un tests d'alors.

## 0.9.0

- **`AtelierCanvas.planche`** : largeur fixe, hauteur libre. Pour ce qui n'est
  pas une page de l'app (galerie de composants, gamme de couleurs, échelle
  typographique) et qu'on veut voir en entier. Dans un téléphone, ces
  planches-là étaient un rouleau dont on ne voyait que le haut.
- Une planche **ignore le format imposé** de la barre : forcer une gamme de
  couleurs en iPhone SE ne répond à aucune question et couperait précisément
  ce qu'on voulait voir.
- C'est la réponse au « design system » comme onglet séparé : pas d'onglet, pas
  de second langage de déclaration. Une galerie de composants est un écran que
  vous écrivez, le mur sait déjà afficher des écrans, et une liste déclarée
  dans l'outil dériverait dès la première variante supprimée.

## 0.8.0

- **`AtelierCase.enveloppe`**, et c'est le correctif le plus important depuis
  le début. Le mur promettait de montrer le même écran vide, plein, premium
  côte à côte, et sur une vraie app les cinq vignettes sortaient IDENTIQUES :
  le crochet `avant` écrit dans un état global, que les écrans relisent après
  coup. L'enveloppe pose l'état dans la branche de la case, il ne fuit plus, et
  la promesse tient enfin. `avant` reste pour l'état qui ne passe pas par le
  contexte, avec un avertissement.
- **Un mur vide explique quoi faire** au lieu de rester noir : les six lignes
  d'un catalogue, et la commande qui l'écrit. C'est le seul moment où l'on
  lit, et l'on est déjà au bon endroit. Une recherche sans résultat garde son
  message à elle, c'est un non-événement, pas quelqu'un qui a besoin d'aide.
- **`atelier:init` dépose un `SKILL.md`** dans `.claude/skills/atelier/` :
  l'assistant de la personne apprend le vocabulaire et la boucle. Personne ne
  lit un README avant de s'en servir, tout le monde demande à son assistant.
- Un test verrouille la **paresse** du mur : sur vingt-quatre écrans déclarés,
  quatre se construisent. Elle était déjà acquise, ce test empêche de la
  perdre.
- LICENSE (MIT) à la place du TODO.

## 0.7.0

- **`dart run atelier:init`.** Balaie `lib/`, repère les écrans et écrit un
  premier `tool/atelier.dart`. Ce n'est pas un confort : écrire trente lignes
  de catalogue à l'aveugle avant de voir le moindre écran est ce qui fait
  abandonner l'outil avant de s'en servir.
- Ce qu'il écrit **compile** : les classes privées sont écartées (elles ne
  s'importent pas depuis `tool/`), les écrans qui demandent des arguments
  partent dans une liste « À compléter » en fin de fichier plutôt que dans les
  sections, et les imports ne concernent que les cases actives.
- Lecture par TEXTE, pas par `package:analyzer` : il se trompera parfois, et
  c'est le bon compromis. L'erreur se voit à la compilation et se corrige en
  cinq secondes, alors qu'une dépendance lourde se paie pour toujours.

## 0.6.0

- **Les pistes d'un écran.** `AtelierCase.variantes` déclare deux ou trois
  directions pour le même écran, et un repère sous la vignette les ouvre en
  vis-à-vis, en grand, l'actuel en premier. C'est la boucle « explorer,
  comparer, trancher » à l'échelle d'un écran, là où les versions la jouent à
  l'échelle de l'app.
- Le mur, lui, ne bouge pas : une vignette par écran. Trente écrans à trois
  pistes feraient quatre-vingt-dix vignettes, et la vue d'ensemble est la
  seule raison d'être du mur.
- Une piste se rend dans le canvas, le thème et l'état préparé de sa case :
  comparer deux rendus obtenus dans des conditions différentes ne dirait rien.

## 0.5.3

- Le menu de format écrivait dans une autre fonte que le reste de la barre dès
  qu'une app imposait une police au chrome : un `TextStyle` neuf ne fusionne
  pas avec l'ambiant. Il part maintenant du thème.
- Le filet sous la barre passe à 11 % d'opacité. À 8 % il ne se voyait pas,
  donc il ne séparait rien.

## 0.5.2

- La ligne des axes etait CENTREE sur la largeur (une `Column` centre ses
  enfants par defaut) : les controles flottaient au milieu du vide, sans
  rapport avec le titre ni avec les vignettes, qui commencent a gauche.
  Trouve en rendant la barre en image, pas en la relisant.

## 0.5.1

- **La barre, refaite.** Un seul langage pour tous les contrôles : même
  hauteur, même rayon, même cadre à peine visible. Il y avait un champ bordé,
  un menu nu et un curseur en couleur d'accent qui ne se ressemblaient pas, et
  le curseur était l'élément le plus contrasté de la page : le premier endroit
  où l'œil se posait était un réglage, pas un écran.
- Les axes sont **tous sur une ligne** (version, format, échelle, thème,
  tokens), dans l'ordre de la question qu'on se pose. Ils étaient répartis
  entre deux barres selon rien, et la ligne du bas paraissait vide pendant que
  celle du haut débordait. La recherche reste en haut : c'est le seul contrôle
  qui ne change pas le rendu.
- L'**échelle affiche sa valeur** (« 32 % »). Un curseur nu ne dit pas où on
  en est : impossible de retrouver un cadrage ou d'en parler à quelqu'un.
- La barre **glisse** au lieu de déborder sur une fenêtre étroite, et un filet
  la sépare du mur, qui partageait son fond sans qu'on voie où il commence.

## 0.5.0

- **La bascule « Animations » disparaît**, et avec elle le paramètre
  `animations`. Le mur est figé, la loupe est vivante : un clic sur une
  vignette suffit pour voir l'animation, donc le réglage ne servait qu'à
  choisir entre « rien voir » et « faire tourner le ventilateur ». Une case de
  moins dans une barre qu'on veut pauvre.

## 0.4.1

- Le nom de la version est **toujours** affiché, même quand il n'y en a qu'une.
  Le masquer paraissait plus propre et c'était une erreur : sans étiquette, on
  ne sait pas quelle version on regarde, ni même que la notion existe. Un mur
  sans nom laisse croire qu'il n'y a qu'un design possible, exactement ce
  qu'une refonte doit remettre en question. « Comparer », lui, reste réservé à
  deux versions ou plus.

## 0.4.0

- **Les versions.** `AtelierVersion` déclare plusieurs designs côte à côte, et
  des onglets apparaissent dès qu'il y en a deux. Sert pendant une refonte, le
  seul moment où deux designs coexistent vraiment.
- **La comparaison.** Une bascule met le même écran en vis-à-vis d'une version
  à l'autre, apparié par libellé. C'est là que se prend la décision : un écran
  refait paraît toujours meilleur quand on le regarde seul, c'est côte à côte
  qu'on voit s'il l'est vraiment et ce qu'on a perdu en chemin.
- Un écran qui n'existe que d'un côté s'affiche quand même, avec un « absent »
  en face. Décaler la grille en silence laisserait croire à une
  correspondance qui n'existe pas.
- `sections` reste accepté pour le cas courant : une version, aucun onglet,
  rien ne change.

## 0.3.0

- L'axe d'agrandissement du texte est **retiré**. Il simulait le réglage
  système du lecteur, ce qui est une vraie condition d'usage, mais pas pour
  toutes les apps : sur un jeu, personne ne joue en texte agrandi, et un
  réglage qu'on ne regarde jamais est du bruit dans une barre d'outils. Les
  apps qui en ont besoin le couvrent mieux par un test dédié.

## 0.2.0

Le mur ne montrait qu'un état par écran, et ne réglait rien. Cette version
règle les deux.

- **Les états.** `AtelierCase.avant` pose l'état juste avant que l'écran se
  construise. Le même écran peut donc apparaître vide, plein et premium côte à
  côte, au lieu d'un seul cas sur trois.
- **Les axes**, appliqués aux quarante écrans d'un coup : thème clair, format
  imposé. Le mur devient un instrument, pas seulement une vue.
- **Le panneau de tokens.** Couleurs et nombres déclarés par l'app, réglés
  dans le mur, appliqués partout via **votre** fonction de thème
  (`themeSelon`). Bouton d'export du Dart correspondant : le mur sert à
  décider, le code reste la source de vérité.
- **Recherche** par libellé, et **réglages retenus** d'une session à l'autre
  (clés préfixées `atelier.`).
- **Loupe** : flèches gauche/droite pour passer d'un écran au suivant sans
  repasser par le mur, Échap pour fermer.
- `AtelierCanvas` porte un `nom` et expose `AtelierCanvas.tous`.
- Correctif : une échelle de départ hors bornes faisait planter la barre de
  réglages au lieu d'être ramenée dans les clous.

## 0.1.0

Première version, extraite de l'app où elle est née.

- Le mur : tous les écrans rendus en même temps, dans le canvas exact de
  l'appareil (marges système simulées).
- Sections repliables, curseur d'échelle, bascule d'animations.
- Loupe : la case cliquée à 1:1, vivante.
- `AtelierApp` pour une racine dédiée, `Atelier` pour une route ordinaire.
