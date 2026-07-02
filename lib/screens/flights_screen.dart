import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'travel_help_screen.dart';
import '../theme/app_theme.dart';
import '../utils/language_notifier.dart';

class FlightsScreen extends StatelessWidget {
  const FlightsScreen({super.key});

  static const _affiliateUrl = 'https://aviasales.tp.st/5CI35mAg';

  Future<void> _openFlights() async {
    final url = Uri.parse(_affiliateUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: languageNotifier,
      builder: (_, __) {
        final t = languageNotifier.t;
        return Scaffold(
          backgroundColor: kSurface,
          appBar: AppBar(
            backgroundColor: kSurfaceContainer,
            iconTheme: const IconThemeData(color: kSecondary),
            title: Text(t('flights_title'), style: tsTitleMd(color: kSecondary)),
          ),
          body: SingleChildScrollView(
            child: Column(children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004D40), Color(0xFF00897B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(children: [
                  const Text('✈️', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 16),
                  Text(t('flights_title'), style: tsHeadlineMd(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(t('flights_subtitle'), style: tsBodySm(color: Colors.white70), textAlign: TextAlign.center),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t('flights_popular'), style: tsHeadlineSm(color: kSecondary)),
                  const SizedBox(height: 12),

                  _routeCard(t('route_oslo_addis'), 'From ~5,000 NOK'),
                  _routeCard(t('route_oslo_asmara'), 'From ~6,000 NOK'),
                  _routeCard(t('route_stockholm_addis'), 'From ~4,500 SEK'),
                  _routeCard(t('route_london_addis'), 'From ~400 GBP'),
                  _routeCard(t('route_kampala_addis'), 'From ~150 USD'),
                  _routeCard(t('route_world_africa'), 'Search all routes'),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openFlights,
                      icon: const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF1A1200)),
                      label: Text(t('flights_search'), style: tsTitleMd(color: const Color(0xFF1A1200))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // WhatsApp button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(Uri.encodeFull('https://wa.me/4796988155?text=' + (languageNotifier.language == 'Tigrinya' ? 'ሰላም ሃበሻ ሃብ፡ ብዛዕባ ነፈርቲ ቡኪንግ ሓገዝ የድልየኒ...' : languageNotifier.language == 'Amharic' ? 'ሰላም ሃበሻ ሃብ፡ ስለ ትኬት ቦታ ማስያዝ እርዳታ ያስፈልገኛል...' : languageNotifier.language == 'Norsk' ? 'Hei Habesha Hub, jeg trenger hjelp med flybestilling...' : 'Hello Habesha Hub, I need help with a flight booking...')));
                        if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
                      },
                      icon: const Text('📱', style: TextStyle(fontSize: 18)),
                      label: Text('Chat on WhatsApp', style: tsTitleMd(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Travel help button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TravelHelpScreen())),
                      icon: const Icon(Icons.support_agent_rounded, color: kSecondary),
                      label: Text(t('travel_help_btn'), style: tsTitleMd(color: kSecondary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: kSecondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kSurfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kSecondary.withOpacity(0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.info_outline_rounded, color: kSecondary, size: 18),
                        const SizedBox(width: 8),
                        Text(t('flights_tips'), style: tsTitleMd(color: kSecondary)),
                      ]),
                      const SizedBox(height: 10),
                      Text(t('flights_tip1'), style: tsBodySm()),
                      const SizedBox(height: 6),
                      Text(t('flights_tip2'), style: tsBodySm()),
                      const SizedBox(height: 6),
                      Text(t('flights_tip3'), style: tsBodySm()),
                      const SizedBox(height: 6),
                      Text(t('flights_tip4'), style: tsBodySm()),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _routeCard(String route, String price) {
    return GestureDetector(
      onTap: _openFlights,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: kSurfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kSecondary.withOpacity(0.1)),
        ),
        child: Row(children: [
          Expanded(child: Text(route, style: tsTitleMd())),
          Text(price, style: tsBodySm(color: kSecondary)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, color: kSecondary, size: 14),
        ]),
      ),
    );
  }
}
