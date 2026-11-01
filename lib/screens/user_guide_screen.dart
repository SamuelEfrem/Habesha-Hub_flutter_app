import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';
import '../utils/theme_notifier.dart';
import '../utils/translations.dart';

/// "How to use Habesha Hub" — short step-by-step help for every part of the app
/// (written for people who are not used to apps). Opened from Profile and from the intro.
class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  static List<(IconData, String, Color Function(), Color Function(), List<String>)> get _sections => [
        (Icons.waving_hand_outlined, 'Getting started', () => kTintGreen, () => kInkGreen, [
          'Change the language (EN / ትግ / አማ) with the button at the top right of the home screen.',
          'The moon / sun button next to it switches between dark and light.',
          'Create an account under Profile > Log in. You need it to sell, book and open a shop.',
          'Allow location so the app can show Habesha places near you.',
        ]),
        (Icons.place_outlined, 'Find Habesha places near you', () => kTintRed, () => kInkRed, [
          'On the home screen, press the green round button to find places near you.',
          'Choose a category (restaurant, shop, café …) or press Map to see them on a map.',
          'Tap a place to call, get directions, see opening hours, chat or book.',
          'Tap the heart to save it. You find your favourites under Profile.',
          'Explore in the bottom menu shows Habesha places in every country.',
        ]),
        (Icons.work_outline_rounded, 'Services and booking', () => kTintYellow, () => kInkYellow, [
          'Press Services on the home screen and choose a country.',
          'Choose a category, for example photographer, transport or flight & visa.',
          'Open a provider to see photos and videos, then press Book now.',
          'Habesha Hub contacts you on WhatsApp. You get a receipt with how to pay.',
          'Your bookings are under Profile > My bookings.',
        ]),
        (Icons.smart_display_outlined, 'Hab Tok videos', () => kTintBlue, () => kInkBlue, [
          'Hab Tok in the bottom menu shows short videos from service providers.',
          'Swipe up for the next video. Tap the video to pause.',
          'Tap the heart to like it, and the round picture to see the provider and book.',
        ]),
        (Icons.shopping_bag_outlined, 'Market: buy, sell, swap and rent', () => kTintBlue, () => kInkBlue, [
          'Press Market on the home screen. Use the search and the buttons to filter.',
          'Habesha clothes: zuria, kemis, netela, gabi and more, with size and occasion.',
          'To sell: press + Sell, add photos, choose For sale, Swap, For rent (price per day) or Free.',
          'Habesha Hub checks every listing before it is shown.',
          'When it is gone, open your listing and press Mark as sold.',
          'Use the share button to send your listing on WhatsApp.',
        ]),
        (Icons.storefront_outlined, 'Home shops', () => kTintGreen, () => kInkGreen, [
          'Home shops are small sellers who make things at home: injera, spices, coffee, clothes, beauty, crafts.',
          'Open a shop to see the products and prices, then press Order on WhatsApp or call.',
          'You pay the seller directly. The address is only shared after you agree.',
          'Your own shop: Home shops > Open your shop. Add a photo, name, area, WhatsApp number and products.',
          'Habesha Hub checks the shop first. Later you can choose Available now / On order, or pause it.',
          'Selling food regularly from home in Norway needs registration with Mattilsynet.',
        ]),
        (Icons.chat_bubble_outline_rounded, 'Habesha AI', () => kTintBlue, () => kInkBlue, [
          'Habesha AI in the bottom menu answers your questions about the app and the community.',
          'Write, or press the microphone and speak (up to 30 seconds) – Tigrinya, Amharic or English.',
          'Press the camera to send a photo and ask about it.',
          'Say that you want to sell something: the AI asks for the details and posts it in the Market for you.',
          'You can ask up to 20 questions per hour.',
        ]),
        (Icons.sports_esports_outlined, 'Games and driving theory', () => kTintGreen, () => kInkGreen, [
          'Press Games on the home screen.',
          'Habesha Games: Dama, Genna, racing and riddles – against the phone, a friend or online.',
          'Life Tools: driving theory class B in Tigrinya. 20 questions are free.',
          'The full course is opened with a code you get on WhatsApp. The code works for your phone number after an SMS check.',
        ]),
        (Icons.send_outlined, 'Send money home', () => kTintRed, () => kInkRed, [
          'Press Send money and choose the country.',
          'You see trusted partners. You send the money in their app or office.',
          'Habesha Hub never handles money itself.',
        ]),
        (Icons.add_business_outlined, 'Your business on Habesha Hub', () => kTintYellow, () => kInkYellow, [
          'Profile > Register your business. It is free.',
          'Add the name, address, photo, phone and opening hours.',
          'After approval you can edit your own page and answer chats.',
        ]),
        (Icons.shield_outlined, 'Safety and help', () => kTintRed, () => kInkRed, [
          'Never send money to people you only know from the internet.',
          'If something looks wrong, use Report on the listing or shop.',
          'Need help? Write to us on WhatsApp: +47 973 74 482.',
          'You can delete your account under Profile at any time.',
        ]),
      ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([languageNotifier, themeNotifier]),
      builder: (context, _) => Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(title: Text(tr('How to use Habesha Hub'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(tr('Tap a topic to see the steps.'), style: tsBodyLg(color: kTextSub)),
            const SizedBox(height: 12),
            for (final s in _sections)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: kCard, borderRadius: BorderRadius.circular(20)),
                clipBehavior: Clip.antiAlias,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    leading: Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(color: s.$3(), shape: BoxShape.circle),
                      child: Icon(s.$1, color: s.$4(), size: 23),
                    ),
                    title: Text(tr(s.$2), style: tsTitleLg(color: kText)),
                    iconColor: kText,
                    collapsedIconColor: kTextSub,
                    children: [
                      for (var i = 0; i < s.$5.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 26, height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: s.$3(), shape: BoxShape.circle),
                              child: Text('${i + 1}', style: tsTitleMd(color: s.$4()).copyWith(fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(tr(s.$5[i]), style: tsBodyLg(color: kText).copyWith(fontSize: 15))),
                          ]),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: kHabGreen, foregroundColor: Colors.white),
              onPressed: () => launchUrl(Uri.parse('https://wa.me/4797374482'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.chat_outlined),
              label: Text(tr('Ask us on WhatsApp')),
            ),
          ],
        ),
      ),
    );
  }
}
