import '../models/site_content_model.dart';
import 'content_remote_datasource.dart';

/// Mirrors the backend's seeded site content exactly (see
/// albmap-backend/src/db/seed.js's SITE_CONTENT) so mock and real mode
/// show identical About Us / Privacy Policy / Terms & Conditions copy.
class ContentMockDataSource implements ContentDataSource {
  static const SiteContentModel _content = SiteContentModel(
    aboutUs: AboutContentModel(
      tagline: 'Discover local businesses & events around you',
      missionTitle: 'Our mission',
      missionBody:
          'AlbMap connects communities with the local businesses and events that make their neighborhoods vibrant — making discovery effortless for guests and giving business owners the tools to reach the people around them.',
      visionTitle: 'Our vision',
      visionBody: 'To become the go-to platform for local discovery — one map, every community.',
    ),
    socialLinks: SocialLinksModel(
      facebook: 'https://facebook.com/albmap',
      instagram: 'https://instagram.com/albmap',
      twitter: 'https://twitter.com/albmap',
    ),
    privacyPolicy: LegalPageModel(
      title: 'Privacy Policy',
      sections: [
        LegalSectionModel(
          heading: 'Information we collect',
          body:
              '• Account information: name, email address, and phone number (if provided) when you sign up, including via Google or Facebook Sign-In.\n'
              "• Location: your device's location, used to show nearby businesses and calculate distances. Only used while the app is in use.\n"
              '• Business listing data: if you register a business, its name, address, description, category, phone/WhatsApp number, opening hours, and any logo image you upload.\n'
              '• Event data: events you create, including any images you upload.\n'
              "• Device push token: to deliver notifications you're eligible to receive.\n"
              '• Favorites: businesses you save, synced to your account.',
        ),
        LegalSectionModel(
          heading: 'How we use information',
          body:
              "To operate the app and website's core features: showing nearby businesses and events, managing your account and business listings, and delivering notifications you're eligible to receive. We do not sell your personal information to third parties.",
        ),
        LegalSectionModel(
          heading: 'Third-party services',
          body:
              "We use Google Sign-In and Facebook Login for authentication, and Firebase Cloud Messaging for push notifications. Each provider's own privacy policy governs their handling of data during that interaction.",
        ),
        LegalSectionModel(
          heading: 'Data retention & deletion',
          body:
              'You can request deletion of your account and associated data at any time via our Contact Us page. We will delete your account, business listings, and personal data within 30 days of a verified request.',
        ),
        LegalSectionModel(
          heading: 'Contact',
          body: 'Questions about this policy? Reach us via our Contact Us page.',
        ),
      ],
    ),
    termsConditions: LegalPageModel(
      title: 'Terms & Conditions',
      sections: [
        LegalSectionModel(
          heading: '1. Acceptance of terms',
          body:
              "By creating an account or using AlbMap (the app or this website), you agree to these terms. If you don't agree, please don't use the service.",
        ),
        LegalSectionModel(
          heading: '2. Accounts',
          body:
              "You're responsible for the accuracy of the information you provide and for keeping your account credentials secure. You must be legally able to enter into these terms in your jurisdiction.",
        ),
        LegalSectionModel(
          heading: '3. Business listings',
          body:
              "Business owners are responsible for the accuracy of their listing's information (name, address, hours, contact details, images). Every new listing — and certain edits to an existing one — goes through admin review before appearing publicly. We reserve the right to reject, suspend, or remove any listing that violates these terms or is inaccurate, fraudulent, or misleading.",
        ),
        LegalSectionModel(
          heading: '4. Notifications',
          body:
              'Business owners may submit offers or announcements for broadcast to users. Every submission is reviewed by an admin before being sent — nothing reaches users automatically. We reserve the right to reject any submission.',
        ),
        LegalSectionModel(
          heading: '5. User conduct',
          body:
              "You agree not to submit false reviews, impersonate another business or person, upload content you don't have rights to, or otherwise misuse the platform.",
        ),
        LegalSectionModel(
          heading: '6. Content',
          body:
              'You retain ownership of content you submit (business descriptions, images, reviews), but grant AlbMap a license to display it as part of the service.',
        ),
        LegalSectionModel(
          heading: '7. Limitation of liability',
          body:
              'AlbMap is provided "as is." We don\'t guarantee the accuracy of listings, opening hours, or event details submitted by business owners, and we\'re not liable for any loss arising from reliance on that information.',
        ),
        LegalSectionModel(
          heading: '8. Changes to these terms',
          body:
              'We may update these terms from time to time. Continued use of the service after a change constitutes acceptance of the updated terms.',
        ),
        LegalSectionModel(
          heading: '9. Contact',
          body: 'Questions about these terms? Reach us via our Contact Us page.',
        ),
      ],
    ),
  );

  @override
  Future<SiteContentModel> getSiteContent() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _content;
  }
}
