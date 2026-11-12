import 'package:url_launcher/url_launcher.dart';

/// Habesha Hub's contact for questions and help: e-mail only.
/// (The WhatsApp number is only used for booking a service.)
const kSupportEmail = 'support@habesha-hub.no';

/// Opens the e-mail app with a new message to support@habesha-hub.no.
Future<void> emailSupport({String subject = 'Habesha Hub', String body = ''}) {
  final q = ['subject=${Uri.encodeComponent(subject)}', if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}'].join('&');
  return launchUrl(Uri.parse('mailto:$kSupportEmail?$q'), mode: LaunchMode.externalApplication);
}
