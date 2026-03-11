import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

const List<Map<String, String>> _ppSections = [
  {
    "title": "1. Introduction",
    "body":
        "This Privacy Policy explains how NAVIG8 Ltd collects, uses, stores, and protects personal information when users access or use the INOTRA mobile application, website, and related services. By using INOTRA, you agree to the collection and use of information in accordance with this policy."
  },
  {
    "title": "2. Company Information",
    "body":
        "INOTRA is operated by NAVIG8 Ltd.\nLocation: Kigali, Rwanda\nContact Email: info@naviig8.com"
  },
  {
    "title": "3. Information We Collect",
    "body":
        "We may collect the following categories of information:\n\nA. Personal Information\n• Full name\n• Email address\n• Phone number\n• Country or location\n• Language preferences\n\nB. Account Information\n• Login credentials\n• Profile information\n• Preferences submitted for trip personalization\n\nC. Booking Information\n• Reservation details\n• Travel preferences\n• Payment confirmations\n\nD. Device and Technical Information\n• Device type\n• Operating system\n• App version\n• IP address\n\nE. Location Information\n• Approximate or precise location (if permission is granted) used for nearby place recommendations and navigation."
  },
  {
    "title": "4. How We Use Your Information",
    "body":
        "We use collected information to:\n• Create and manage user accounts\n• Provide travel recommendations and personalized experiences\n• Process bookings and reservations\n• Communicate with users regarding services or support\n• Improve the functionality and performance of the platform\n• Prevent fraud and maintain platform security\n• Comply with legal and regulatory obligations"
  },
  {
    "title": "5. AI Features and Personalization",
    "body":
        "INOTRA may use artificial intelligence to generate travel suggestions and assist with trip planning. AI systems may analyze user preferences and interaction history to improve recommendations. AI-generated responses are intended to assist users but may not always be completely accurate."
  },
  {
    "title": "6. Chat and Communication Data",
    "body":
        "INOTRA provides chat communication between users and customer representatives. Messages may be automatically translated between languages.\n\nFor quality assurance, support, and dispute resolution:\n• Chat conversations may be stored\n• Translated versions of messages may be generated\n• Conversations may be reviewed by authorized staff"
  },
  {
    "title": "7. Location Services",
    "body":
        "The platform may request permission to access your device location to provide:\n• Nearby travel recommendations\n• Map navigation\n• Distance estimates\n\nUsers can disable location permissions through their device settings. Disabling location services may limit certain features of the app."
  },
  {
    "title": "8. Sharing of Information",
    "body":
        "NAVIG8 Ltd does not sell personal information.\n\nInformation may be shared with:\n• Service providers (hotels, tour operators, or partners) for booking fulfillment\n• Payment processors to complete transactions\n• Technical service providers who support app infrastructure\n• Legal authorities if required by law"
  },
  {
    "title": "9. Payment Information",
    "body":
        "Payments may be processed through third-party payment providers such as card processors or mobile money platforms.\n\nNAVIG8 Ltd does not store full credit card information. Payment processing is handled by certified payment service providers."
  },
  {
    "title": "10. Data Security",
    "body":
        "NAVIG8 Ltd takes reasonable technical and organizational measures to protect personal data, including:\n• Secure authentication systems\n• Encrypted communication where applicable\n• Access controls for internal systems\n\nHowever, no digital system can guarantee absolute security."
  },
  {
    "title": "11. Data Retention",
    "body":
        "Personal data is retained only for as long as necessary to:\n• Provide services\n• Fulfill bookings\n• Comply with legal requirements\n• Resolve disputes\n\nUsers may request deletion of their account and associated personal data, subject to legal obligations."
  },
  {
    "title": "12. User Rights",
    "body":
        "Depending on applicable laws, users may have rights to:\n• Access their personal information\n• Request correction of inaccurate information\n• Request deletion of their data\n• Withdraw consent for certain data uses\n\nRequests may be submitted through the app or by contacting NAVIG8 Ltd."
  },
  {
    "title": "13. Children's Privacy",
    "body":
        "INOTRA is not intended for children under the age of 18 without parental supervision. NAVIG8 Ltd does not knowingly collect personal information from children."
  },
  {
    "title": "14. International Users",
    "body":
        "Users accessing the platform from outside Rwanda understand that their information may be processed in Rwanda or other jurisdictions where service providers operate."
  },
  {
    "title": "15. Changes to this Privacy Policy",
    "body":
        "NAVIG8 Ltd may update this Privacy Policy from time to time. Significant changes may be communicated through the application or via email. Continued use of the platform indicates acceptance of the updated policy."
  },
  {
    "title": "16. Contact Information",
    "body":
        "If you have questions regarding this Privacy Policy or your personal data, you may contact:\n\nNAVIG8 Ltd\nKigali, Rwanda\nEmail: info@naviig8.com"
  },
];

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(
      fontSize: 12,
      height: 1.35,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface.withOpacity(0.86),
    );
    final titleStyle = bodyStyle.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w800,
    );

    return MainScaffold(
      title: t(lang, "privacy.title"),
      showAppBar: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: t(lang, "privacy.title")),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedShield02,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t(lang, "privacy.title"),
                            style: titleStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _ppSections.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final section = _ppSections[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(section["title"] ?? "", style: titleStyle),
                                const SizedBox(height: 6),
                                Text(section["body"] ?? "", style: bodyStyle),
                              ],
                            );
                          },
                        ),
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
}
