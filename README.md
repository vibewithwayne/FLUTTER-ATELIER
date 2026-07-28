# Atelier

Tous les écrans de ton app Flutter sur une seule page.

Tu changes une couleur, tu vois les trente écrans d'un coup au lieu d'en
ouvrir un et d'espérer pour les autres.

## Installer

Colle ça à ton assistant, dans ton projet Flutter :

> Installe Atelier depuis https://github.com/vibewithwayne/FLUTTER-ATELIER.git en
> dev_dependency, lance `dart run atelier:init`, puis ouvre le mur.

Il fait tout : la dépendance, le catalogue de tes écrans, sa propre
documentation, et il démarre le serveur. Tu regardes.

`atelier:init` écrit trois choses : `tool/atelier.dart`, la liste de tes
écrans ; un mode d'emploi pour ton assistant dans `.claude/skills/` ; et la
config de lancement dans `.claude/launch.json`, pour qu'« ouvre l'atelier »
suffise ensuite.

## Comment on s'en sert

Tu ne touches presque jamais au fichier. Tu parles à ton assistant.

| Tu dis | Ce qui se passe |
| --- | --- |
| « change la couleur des boutons » | il modifie le composant, tout le mur bouge |
| « j'hésite entre deux accueils » | il fabrique deux pistes, tu les compares côte à côte |
| « j'ai ajouté un écran » | il l'ajoute au catalogue |
| « la boutique est vide » | il y pose des données de démo |
| « on refait tout le design » | il crée une Version 2 à côté de la Version 1 |
| « range mieux les sections » | il regroupe les écrans dans l'ordre du joueur |

## Dans le mur

Un clic sur une vignette l'ouvre en grand, vivante et cliquable. Les flèches
passent à la suivante, Échap ferme.

La barre du haut : la version, le format d'appareil imposé à tout le mur, la
taille des vignettes, la recherche. Et le design système, si tu en as déclaré
un.

## Quand ça coince

**Page noire au lancement.** Le premier build web est long. Recharge (F5) une
fois qu'il a fini.

**Un écran manque.** Il n'est pas dans le catalogue, demande à ton assistant de
l'ajouter.

**Pas de prix, pas de données.** Normal, il n'y a pas de backend derrière. Ce
sont des données de démo à poser, ton assistant sait faire.

**Ça montre la version web de mon app.** Le mur tourne dans un navigateur.
Demande à ton assistant de forcer la plateforme mobile.

## Le reste

Le détail de l'outil est écrit pour ton assistant, dans
`.claude/skills/atelier/SKILL.md`, déposé chez toi par `atelier:init`. Le
pourquoi de chaque choix est dans le code, fichier par fichier.

MIT.
