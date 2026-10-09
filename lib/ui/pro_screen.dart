import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../theme/atelier.dart';
import '../state/settings.dart';
import '../audio/sound_engine.dart';
import '../services/iap_service.dart';
import 'widgets.dart';

/// PRO screen: Free-vs-Pro comparison, Pro purchase, tip jar, restore.
/// Graceful when products aren't created in Play Console yet — an honest
/// "available after store setup" state, never a fake buy button.
class ProScreen extends StatefulWidget {
  final AtelierSettings settings;
  final SoundEngine sound;
  final StoreService store;
  const ProScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
    widget.store.proPurchased.addListener(_onPro);
    widget.store.purchaseError.addListener(_onError);
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.purchaseError.removeListener(_onError);
    super.dispose();
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
      widget.store.lastThanks.value = null;
    }
  }

  void _onPro() {
    if (widget.store.proPurchased.value) {
      widget.settings.setProUnlocked(true);
      widget.sound.play(SfxKind.win);
      if (mounted) setState(() {});
    }
  }

  void _onError() {
    final err = widget.store.purchaseError.value;
    if (err != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
      widget.store.purchaseError.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final store = widget.store;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: VelvetBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 2),
                child: Row(
                  children: [
                    BrassIconButton(
                      icon: Icons.arrow_back,
                      size: 42,
                      onTap: () {
                        widget.sound.play(SfxKind.click);
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: BrassPlaque(
                        text: 'PRO ATELIER',
                        fontSize: 18,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(width: 50),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _comparisonCard(s),
                      const SizedBox(height: 16),
                      _proCard(s, store),
                      const SizedBox(height: 16),
                      _tipJarCard(store),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          widget.sound.play(SfxKind.click);
                          store.restore();
                        },
                        child: Text('Restore purchases',
                            style: Atelier.body.copyWith(
                                color: Atelier.brassBright,
                                decoration:
                                    TextDecoration.underline)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comparisonCard(AtelierSettings s) {
    return WalnutPanel(
      child: Column(
        children: [
          Text('FREE vs PRO',
              style:
                  Atelier.display.copyWith(fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 8),
          const EngravedDivider(),
          const SizedBox(height: 8),
          _row('Velvet themes', '4 workbenches', 'All 13 + custom creator'),
          _row('Gem cuts', '3 classic cuts', 'All 9 jeweler\u2019s cuts'),
          _row('Metal accents', 'Polished brass', 'All 5 metals'),
          _row('Apprentice hints',
              '3 free, then 5 coins', 'Unlimited, always free'),
          _row('New themes forever', '\u2713', '\u2713'),
          _row('Offline play', '\u2713', '\u2713'),
          _row('Ads', 'None. Ever.', 'None. Ever.'),
        ],
      ),
    );
  }

  Widget _row(String label, String free, String pro) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(label,
                  style: Atelier.body
                      .copyWith(color: Atelier.creamDim))),
          Expanded(
              flex: 3,
              child: Text(free,
                  textAlign: TextAlign.center,
                  style: Atelier.body.copyWith(fontSize: 13))),
          Expanded(
              flex: 4,
              child: Text(pro,
                  textAlign: TextAlign.center,
                  style: Atelier.body.copyWith(
                      fontSize: 13,
                      color: Atelier.brassBright,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _proCard(AtelierSettings s, StoreService store) {
    final ready = store.storeReady && store.proProduct != null;
    return WalnutPanel(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium,
                  color: Atelier.brassBright, size: 30),
              const SizedBox(width: 10),
              Text('JEWEL MATCH PRO',
                  style: Atelier.display
                      .copyWith(fontSize: 20, letterSpacing: 2)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'One purchase, yours forever.\nEvery theme, every cut, every metal \u2014\nplus unlimited apprentice hints.',
            textAlign: TextAlign.center,
            style: Atelier.bodyItalic
                .copyWith(color: Atelier.creamDim),
          ),
          const SizedBox(height: 14),
          if (s.proUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Atelier.brassBright, Atelier.brass],
                ),
              ),
              child: Text('PRO ENGRAVED \u2713',
                  style: Atelier.numeralOnBrass
                      .copyWith(fontSize: 16)),
            )
          else if (!ready)
            Column(
              children: [
                Text(
                  store.error ?? 'Available after store setup',
                  style: Atelier.body.copyWith(
                      color: Atelier.creamDim,
                      fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'The Pro upgrade appears here once it is configured in the Play Store.',
                  style: Atelier.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => SizedBox(
                width: double.infinity,
                child: BrassButton(
                  label: busy
                      ? 'CONTACTING THE STORE\u2026'
                      : 'UNLOCK PRO \u00b7 ${store.proProduct!.price}',
                  onTap: busy ? () {} : store.buyPro,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tipJarCard(StoreService store) {
    return WalnutPanel(
      child: Column(
        children: [
          Text('THE TIP JAR',
              style:
                  Atelier.display.copyWith(fontSize: 20, letterSpacing: 2)),
          const SizedBox(height: 6),
          Text(
            'Jewel Match is made by one independent jeweler of games. If the atelier made you smile, a small tip keeps the lamp lit.',
            textAlign: TextAlign.center,
            style:
                Atelier.bodyItalic.copyWith(color: Atelier.creamDim),
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup',
              style: Atelier.body.copyWith(
                  color: Atelier.creamDim,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            )
          else
            Row(
              children: [
                Expanded(
                    child: _tipButton(
                        store, store.coffeeProduct, 'Coffee', Icons.coffee)),
                const SizedBox(width: 10),
                Expanded(
                    child: _tipButton(store,
                        store.chocolateProduct, 'Chocolate', Icons.cake)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _tipButton(StoreService store, ProductDetails? product,
      String label, IconData icon) {
    if (product == null) {
      return Text('Soon',
          textAlign: TextAlign.center, style: Atelier.caption);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: store.purchaseInProgress,
      builder: (_, busy, _) => BrassButton(
        label: label.toUpperCase(),
        sublabel: product.price,
        primary: false,
        fontSize: 15,
        onTap: busy ? () {} : () => store.buyTip(product),
      ),
    );
  }
}
