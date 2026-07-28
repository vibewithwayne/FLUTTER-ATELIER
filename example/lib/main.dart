// DÉMONSTRATION DE L'ATELIER.
//
// Une petite app générique, en anglais, montée dans tous ses états. Elle sert
// deux choses : montrer la forme d'un catalogue à qui découvre le paquet, et
// donner un mur présentable en capture sans exposer l'app de personne.
//
// Ce qu'il faut regarder est en bas de fichier : le catalogue. Les écrans
// au-dessus sont volontairement banals.
//
//   cd example && flutter create --platforms=web . && flutter run -d chrome

import 'package:atelier/atelier.dart';
import 'package:flutter/material.dart';

void main() => runApp(
  AtelierApp(
    titre: 'Atelier',
    canvas: AtelierCanvas.iphone,
    tokens: _tokens,
    themeSelon: _theme,
    sections: _sections(),
    briques: _briques(),
  ),
);

// ── LES TOKENS ────────────────────────────────────────────────────────────
// Déclarés ici, réglés dans le panneau, appliqués à tous les écrans en même
// temps. Le bouton « Exporter » rend le Dart correspondant : le mur sert à
// décider, le code reste la source de vérité.
const _tokens = [
  TokenCouleur('marque', 'Brand colour', Color(0xFF6C5CE7)),
  TokenNombre('rayon', 'Corner radius', 18, max: 40),
  TokenNombre('espace', 'Spacing', 16, min: 4, max: 40),
];

/// VOTRE fonction de thème. L'atelier n'en fabrique aucun : il ne fait que
/// vous rappeler avec des valeurs différentes, donc ce que vous voyez est ce
/// que votre app produirait.
ThemeData _theme(Map<String, Object> t, {required bool clair}) {
  final rayon = t['rayon'] as double;
  final forme = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(rayon),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: t['marque'] as Color,
      brightness: clair ? Brightness.light : Brightness.dark,
    ),
    cardTheme: CardThemeData(shape: forme, margin: EdgeInsets.zero),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: forme,
        minimumSize: const Size(0, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: forme,
        minimumSize: const Size(0, 48),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(rayon)),
      filled: true,
    ),
    extensions: [_Espace(t['espace'] as double)],
  );
}

/// Un espacement transporté par le thème : c'est ce qui le rend réglable. Une
/// constante de classe (`static const espace = 16.0`) serait figée à la
/// compilation et le panneau ne pourrait rien en faire.
class _Espace extends ThemeExtension<_Espace> {
  const _Espace(this.valeur);
  final double valeur;

  static double de(BuildContext c) =>
      Theme.of(c).extension<_Espace>()?.valeur ?? 16;

  @override
  ThemeExtension<_Espace> copyWith({double? valeur}) =>
      _Espace(valeur ?? this.valeur);

  @override
  ThemeExtension<_Espace> lerp(ThemeExtension<_Espace>? autre, double t) =>
      autre is _Espace ? _Espace(valeur + (autre.valeur - valeur) * t) : this;
}

// ── L'ÉTAT, PORTÉ PAR LE CONTEXTE ─────────────────────────────────────────
// C'est ce que l'enveloppe d'une case pose autour de l'écran. Comme il vit
// dans la branche, deux vignettes du même écran montrent deux états
// différents sans se marcher dessus.
class Panier extends InheritedWidget {
  const Panier({
    super.key,
    required this.articles,
    required this.premium,
    required super.child,
  });

  final int articles;
  final bool premium;

  static Panier de(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<Panier>() ??
      const Panier(articles: 0, premium: false, child: SizedBox.shrink());

  @override
  bool updateShouldNotify(Panier old) =>
      old.articles != articles || old.premium != premium;
}

// ── LES ÉCRANS ────────────────────────────────────────────────────────────

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(e * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.hexagon_rounded, size: 72, color: c.primary),
              SizedBox(height: e),
              Text(
                'Everything you need,\nin one place.',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: e / 2),
              Text(
                'Browse, save, and check out in seconds.',
                style: TextStyle(color: c.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton(onPressed: () {}, child: const Text('Get started')),
              SizedBox(height: e / 2),
              OutlinedButton(onPressed: () {}, child: const Text('Sign in')),
            ],
          ),
        ),
      ),
    );
  }
}

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: EdgeInsets.all(e),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: e),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: e),
            FilledButton(onPressed: () {}, child: const Text('Continue')),
            SizedBox(height: e / 2),
            TextButton(onPressed: () {}, child: const Text('Forgot password?')),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    final panier = Panier.de(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: Padding(
        padding: EdgeInsets.all(e),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (panier.premium) ...[
              Card(
                color: c.primaryContainer,
                child: Padding(
                  padding: EdgeInsets.all(e),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: c.onPrimaryContainer,
                      ),
                      SizedBox(width: e / 2),
                      Text(
                        'Premium member',
                        style: TextStyle(color: c.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: e),
            ],
            if (panier.articles == 0)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: c.onSurfaceVariant,
                      ),
                      SizedBox(height: e / 2),
                      const Text('Nothing here yet'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: panier.articles,
                  separatorBuilder: (_, _) => SizedBox(height: e / 2),
                  itemBuilder: (_, i) => Card(
                    child: ListTile(
                      leading: CircleAvatar(child: Text('${i + 1}')),
                      title: Text('Item ${i + 1}'),
                      subtitle: const Text('Ships tomorrow'),
                      trailing: const Text(r'$24'),
                    ),
                  ),
                ),
              ),
            SizedBox(height: e),
            FilledButton(onPressed: () {}, child: const Text('Checkout')),
          ],
        ),
      ),
    );
  }
}

class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: ListView(
        padding: EdgeInsets.all(e),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: c.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.image_outlined, size: 48, color: c.outline),
          ),
          SizedBox(height: e),
          Text('Walnut chair', style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: e / 4),
          Text(r'$249', style: TextStyle(color: c.primary, fontSize: 20)),
          SizedBox(height: e),
          const Text(
            'Solid walnut, hand finished. Built to last a decade, and then '
            'another one.',
          ),
          SizedBox(height: e),
          FilledButton(onPressed: () {}, child: const Text('Add to cart')),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: EdgeInsets.all(e),
        children: [
          const Center(child: CircleAvatar(radius: 36, child: Text('AW'))),
          SizedBox(height: e),
          const Center(child: Text('alex@example.com')),
          SizedBox(height: e),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('Orders'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.favorite_border),
                  title: Text('Saved'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Help'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(e),
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: const Text('Notifications'),
          ),
          SwitchListTile(
            value: false,
            onChanged: (_) {},
            title: const Text('Dark mode'),
          ),
          const ListTile(title: Text('Language'), trailing: Text('English')),
          const ListTile(title: Text('Version'), trailing: Text('1.0.0')),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(e * 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 48, color: c.error),
              SizedBox(height: e),
              const Text('You are offline'),
              SizedBox(height: e / 2),
              Text(
                'Check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.onSurfaceVariant),
              ),
              SizedBox(height: e),
              OutlinedButton(onPressed: () {}, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    final n = Panier.de(context).articles;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: n == 0
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 48,
                    color: c.onSurfaceVariant,
                  ),
                  SizedBox(height: e / 2),
                  const Text('Your cart is empty'),
                  SizedBox(height: e),
                  OutlinedButton(onPressed: () {}, child: const Text('Browse')),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.all(e),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView.separated(
                      itemCount: n,
                      separatorBuilder: (_, _) => SizedBox(height: e / 2),
                      itemBuilder: (_, i) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.chair_outlined),
                          title: Text('Walnut chair'),
                          subtitle: const Text('Qty 1'),
                          trailing: const Text(r'$249'),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: e),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total'),
                      Text(
                        '\$${249 * n}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                  SizedBox(height: e),
                  FilledButton(onPressed: () {}, child: const Text('Checkout')),
                ],
              ),
            ),
    );
  }
}

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: EdgeInsets.all(e),
        children: [
          const Text('Delivery'),
          SizedBox(height: e / 2),
          const TextField(decoration: InputDecoration(labelText: 'Address')),
          SizedBox(height: e),
          const Text('Payment'),
          SizedBox(height: e / 2),
          const Card(
            child: ListTile(
              leading: Icon(Icons.credit_card),
              title: Text('Visa ending 4242'),
              trailing: Icon(Icons.check_circle_outline),
            ),
          ),
          SizedBox(height: e * 1.5),
          FilledButton(onPressed: () {}, child: const Text(r'Pay $249')),
        ],
      ),
    );
  }
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView.separated(
        padding: EdgeInsets.all(e),
        itemCount: 3,
        separatorBuilder: (_, _) => SizedBox(height: e / 2),
        itemBuilder: (_, i) => Card(
          child: ListTile(
            title: Text('Order #${1042 + i}'),
            subtitle: Text(i == 0 ? 'On its way' : 'Delivered'),
            trailing: Icon(
              i == 0 ? Icons.local_shipping_outlined : Icons.check,
              color: i == 0 ? c.primary : c.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: EdgeInsets.all(e),
        child: Column(
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: e),
            Expanded(
              child: ListView.separated(
                itemCount: 5,
                separatorBuilder: (_, _) => SizedBox(height: e / 2),
                itemBuilder: (_, i) => Card(
                  child: ListTile(
                    title: Text('Result ${i + 1}'),
                    subtitle: const Text('In stock'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: EdgeInsets.all(e),
        children: [
          Card(
            color: c.primaryContainer,
            child: ListTile(
              leading: Icon(Icons.local_offer, color: c.onPrimaryContainer),
              title: Text(
                '20% off this week',
                style: TextStyle(color: c.onPrimaryContainer),
              ),
            ),
          ),
          SizedBox(height: e / 2),
          const Card(
            child: ListTile(
              leading: Icon(Icons.local_shipping_outlined),
              title: Text('Your order shipped'),
              subtitle: Text('2 days ago'),
            ),
          ),
          SizedBox(height: e / 2),
          const Card(
            child: ListTile(
              leading: Icon(Icons.star_border),
              title: Text('Rate your last order'),
              subtitle: Text('1 week ago'),
            ),
          ),
        ],
      ),
    );
  }
}

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    Widget ligne(String t) => Padding(
      padding: EdgeInsets.only(bottom: e / 2),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: c.primary),
          SizedBox(width: e / 2),
          Expanded(child: Text(t)),
        ],
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(e * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: e),
              Icon(Icons.workspace_premium, size: 56, color: c.primary),
              SizedBox(height: e),
              Text(
                'Go Premium',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: e),
              ligne('Free delivery, every order'),
              ligne('Early access to new drops'),
              ligne('Extended returns'),
              const Spacer(),
              FilledButton(onPressed: () {}, child: const Text(r'$9 / month')),
              SizedBox(height: e / 2),
              TextButton(onPressed: () {}, child: const Text('Not now')),
            ],
          ),
        ),
      ),
    );
  }
}

/// LA PLANCHE DE COMPOSANTS : pas un écran de l'app, des pièces détachées.
/// Elle vit dans `briques`, derrière le bouton de la barre.
class ComponentsSheet extends StatelessWidget {
  const ComponentsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final e = _Espace.de(context);
    final c = Theme.of(context).colorScheme;
    Widget titre(String t) => Padding(
      padding: EdgeInsets.only(top: e, bottom: e / 2),
      child: Text(t.toUpperCase(), style: TextStyle(color: c.outline)),
    );
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(e),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            titre('Buttons'),
            Wrap(
              spacing: e / 2,
              runSpacing: e / 2,
              children: [
                FilledButton(onPressed: () {}, child: const Text('Primary')),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Secondary'),
                ),
                TextButton(onPressed: () {}, child: const Text('Text')),
                const FilledButton(onPressed: null, child: Text('Disabled')),
              ],
            ),
            titre('Fields'),
            const TextField(decoration: InputDecoration(labelText: 'Label')),
            titre('Badges'),
            Wrap(
              spacing: e / 2,
              children: const [
                Chip(label: Text('New')),
                Chip(label: Text('Sale')),
                Chip(label: Text('Sold out')),
              ],
            ),
            titre('Card'),
            const Card(
              child: ListTile(
                title: Text('Walnut chair'),
                subtitle: Text('Ships tomorrow'),
                trailing: Text(r'$249'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── LE CATALOGUE ──────────────────────────────────────────────────────────
// Voilà tout ce qu'il y a à écrire. Un libellé, un constructeur, et pour les
// états, une enveloppe qui pose les données de cette case-là.

Widget _avec(Widget ecran, {int articles = 0, bool premium = false}) =>
    Panier(articles: articles, premium: premium, child: ecran);

List<AtelierSection> _sections() => [
  AtelierSection('Onboarding', [
    AtelierCase('Welcome', () => const WelcomeScreen()),
    AtelierCase('Sign in', () => const SignInScreen()),
  ]),

  // LE MÊME ÉCRAN, TROIS FOIS. C'est là que le mur gagne son prix : le cas
  // nominal est toujours joli, ce sont les autres qui débordent.
  AtelierSection('Home', [
    AtelierCase(
      'Home · empty',
      () => const HomeScreen(),
      enveloppe: (e) => _avec(e),
    ),
    AtelierCase(
      'Home · filled',
      () => const HomeScreen(),
      enveloppe: (e) => _avec(e, articles: 4),
    ),
    AtelierCase(
      'Home · premium',
      () => const HomeScreen(),
      enveloppe: (e) => _avec(e, articles: 2, premium: true),
    ),
  ]),

  AtelierSection('Shop', [
    AtelierCase('Search', () => const SearchScreen()),
    AtelierCase('Product', () => const ProductScreen()),
    AtelierCase(
      'Cart · empty',
      () => const CartScreen(),
      enveloppe: (e) => _avec(e),
    ),
    AtelierCase(
      'Cart · full',
      () => const CartScreen(),
      enveloppe: (e) => _avec(e, articles: 2),
    ),
    AtelierCase('Checkout', () => const CheckoutScreen()),
    AtelierCase('Upgrade', () => const UpgradeScreen()),
  ]),

  AtelierSection('Account', [
    AtelierCase('Profile', () => const ProfileScreen()),
    AtelierCase('Orders', () => const OrdersScreen()),
    AtelierCase('Notifications', () => const NotificationsScreen()),
    AtelierCase('Settings', () => const SettingsScreen()),
    AtelierCase('Offline', () => const ErrorScreen()),
  ]),
];

List<AtelierSection> _briques() => [
  AtelierSection('Components', [
    AtelierCase(
      'Buttons, fields, badges',
      () => const ComponentsSheet(),
      canvas: const AtelierCanvas.planche(largeur: 520, hauteurMax: 900),
    ),
  ]),
];
