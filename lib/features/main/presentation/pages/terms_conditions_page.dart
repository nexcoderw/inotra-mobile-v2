import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

const List<Map<String, String>> _tcSections = [
  {
    "title": "1. Introduction",
    "body":
        "Welcome to INOTRA, a travel and tourism platform operated by NAVIG8 Ltd, a company registered in Kigali, Rwanda. These Terms and Conditions govern the use of the INOTRA mobile application, website, and related services. By accessing or using the platform, you agree to comply with these Terms."
  },
  {
    "title": "2. Description of the Platform",
    "body":
        "INOTRA is a digital platform designed to help users discover places, events, accommodations, and travel experiences in Rwanda. The platform may include features such as:\n• AI-powered travel assistance and trip personalization\n• Listings of places, hotels, restaurants, and activities\n• Event discovery and highlights\n• Excursions, tours, and activities\n• Booking and reservation services\n• Chat communication with customer representatives\n• Maps, navigation, and location-based recommendations\nNAVIG8 acts primarily as a facilitator connecting users with service providers."
  },
  {
    "title": "3. Eligibility",
    "body":
        "Users must be at least 18 years old to create an account or use booking services through the platform. By creating an account, users confirm that they have the legal capacity to enter into binding agreements."
  },
  {
    "title": "4. User Accounts",
    "body":
        "Users may register using email/password or supported third-party authentication services. Users agree to:\n• Provide accurate and complete information\n• Maintain the security of their account credentials\n• Notify NAVIG8 Ltd immediately of unauthorized account use\nNAVIG8 Ltd reserves the right to suspend or terminate accounts that violate these Terms or misuse the platform."
  },
  {
    "title": "5. Platform Services",
    "body":
        "INOTRA provides services including discovery of destinations, recommendations, booking assistance, and communication with service providers. NAVIG8 does not own or directly operate most listed venues or services. Service providers remain responsible for the accuracy of their information and delivery of their services."
  },
  {
    "title": "6. Bookings and Reservations",
    "body":
        "Users may submit booking requests through the platform for trips, packages, accommodations, or other services. Bookings may require confirmation from NAVIG8 or third-party providers before being finalized. Booking statuses may include:\n• Pending\n• Awaiting Payment\n• Confirmed\n• In Progress\n• Completed\n• Cancelled\n• Refunded"
  },
  {
    "title": "7. Payments",
    "body":
        "Payments for services may be processed through third-party payment providers including mobile money services and card payment processors. NAVIG8 does not control or guarantee the performance of external payment systems. Payment processing fees, transaction failures, or delays may be subject to the policies of the payment provider."
  },
  {
    "title": "8. Cancellation and Refunds",
    "body":
        "Cancellation policies may vary depending on the service provider involved. Refund eligibility, timing, and conditions may depend on:\n• The cancellation window\n• Supplier policies\n• Payment provider processing times\nNAVIG8 reserves the right to review and determine refund requests where applicable."
  },
  {
    "title": "9. AI Recommendations Disclaimer",
    "body":
        "The platform may provide recommendations using artificial intelligence systems. AI-generated suggestions are based on available data and user preferences and should be considered informational only. NAVIG8 Ltd does not guarantee the accuracy, completeness, or suitability of AI-generated recommendations."
  },
  {
    "title": "10. Messaging and Communication",
    "body":
        "The platform may allow communication between users and NAVIG8 Ltd customer representatives through chat systems. Messages may be automatically translated between languages to facilitate communication. For quality assurance and dispute resolution purposes, messages may be stored and monitored."
  },
  {
    "title": "11. User-Generated Content",
    "body":
        "Users may submit reviews, comments, event submissions, or business listings. By submitting content, users confirm that:\n• The content is accurate and lawful\n• The content does not violate the rights of others\nNAVIG8 reserves the right to moderate, edit, or remove user content that violates platform policies."
  },
  {
    "title": "12. Business Listings and Event Submissions",
    "body":
        "Businesses and event organizers may submit information to be listed on the platform. NAVIG8 Ltd may review submissions and request supporting documentation before approval. Approval of a listing does not constitute endorsement by NAVIG8 Ltd."
  },
  {
    "title": "13. Location Services",
    "body":
        "The platform may request access to location services to provide nearby recommendations, directions, and navigation. Users may disable location permissions through their device settings. Some features may be limited if location access is disabled."
  },
  {
    "title": "14. Platform Availability",
    "body":
        "NAVIG8 Ltd aims to maintain reliable platform availability but does not guarantee uninterrupted service. Temporary interruptions may occur due to maintenance, updates, internet connectivity issues, or third-party system failures."
  },
  {
    "title": "15. Intellectual Property",
    "body":
        "All intellectual property related to the INOTRA platform, including design, software, branding, and content, remains the property of NAVIG8 Ltd or its licensors. Users may not reproduce, distribute, or modify platform materials without permission."
  },
  {
    "title": "16. Privacy and Data Protection",
    "body":
        "NAVIG8 Ltd collects and processes user information in accordance with applicable data protection laws. Personal information is used to provide services, improve the platform, and manage bookings. Users may request deletion of their personal data where legally permitted."
  },
  {
    "title": "17. Limitation of Liability",
    "body":
        "NAVIG8 Ltd acts as an intermediary between users and service providers. NAVIG8 Ltd shall not be liable for losses, injuries, delays, or damages resulting from services provided by third parties. Users are encouraged to obtain appropriate travel insurance."
  },
  {
    "title": "18. Force Majeure",
    "body":
        "NAVIG8 Ltd shall not be liable for failure or delay in providing services due to circumstances beyond its control, including natural disasters, pandemics, civil unrest, or government restrictions."
  },
  {
    "title": "19. Governing Law",
    "body":
        "These Terms and Conditions shall be governed by the laws of the Republic of Rwanda. Any disputes arising from the use of the platform shall be subject to the jurisdiction of the courts of Kigali, Rwanda."
  },
  {
    "title": "20. Changes to the Terms",
    "body":
        "NAVIG8 Ltd reserves the right to update these Terms at any time. Users will be notified of material changes through the platform or via email. Continued use of the platform constitutes acceptance of the updated Terms."
  },
];

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

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
      fontWeight: FontWeight.w800,
    );

    return MainScaffold(
      title: t(lang, "terms.title"),
      showAppBar: false,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(title: t(lang, "terms.title")),
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
                            icon: HugeIcons.strokeRoundedFile02,
                            size: 20,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            t(lang, "terms.title"),
                            style: titleStyle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: _tcSections.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final section = _tcSections[index];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(section["title"] ?? "", style: titleStyle),
                                const SizedBox(height: 4),
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
