import 'package:equatable/equatable.dart';

/// Mission/vision copy shown on the About Us screen — see
/// albmap-backend's site_content table, key 'about_us'. Previously this
/// was a hardcoded localization string; now it's admin-editable from the
/// admin portal's Content page and fetched live here.
class AboutContentEntity extends Equatable {
  const AboutContentEntity({
    required this.tagline,
    required this.missionTitle,
    required this.missionBody,
    required this.visionTitle,
    required this.visionBody,
  });

  final String tagline;
  final String missionTitle;
  final String missionBody;
  final String visionTitle;
  final String visionBody;

  @override
  List<Object?> get props => [tagline, missionTitle, missionBody, visionTitle, visionBody];
}

/// Every field is optional — a null/blank one means "don't show that
/// icon," not a broken link. Key 'social_links' in site_content.
class SocialLinksEntity extends Equatable {
  const SocialLinksEntity({
    this.facebook,
    this.instagram,
    this.twitter,
    this.tiktok,
    this.youtube,
    this.linkedin,
  });

  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? tiktok;
  final String? youtube;
  final String? linkedin;

  /// True once at least one platform has a URL — screens use this to
  /// decide whether to render the "Follow us" row at all.
  bool get hasAny =>
      facebook != null || instagram != null || twitter != null || tiktok != null || youtube != null || linkedin != null;

  @override
  List<Object?> get props => [facebook, instagram, twitter, tiktok, youtube, linkedin];
}

class LegalSectionEntity extends Equatable {
  const LegalSectionEntity({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  List<Object?> get props => [heading, body];
}

/// Shared shape for Privacy Policy and Terms & Conditions (keys
/// 'privacy_policy' / 'terms_conditions') — a title plus an ordered list
/// of heading/body sections, admin-editable as free text (no rich
/// formatting) via the admin portal.
class LegalPageEntity extends Equatable {
  const LegalPageEntity({required this.title, required this.sections});

  final String title;
  final List<LegalSectionEntity> sections;

  @override
  List<Object?> get props => [title, sections];
}

/// Every page GET /content returns in one call — About Us and Privacy
/// Policy/Terms & Conditions each read one field of this, but fetching
/// them together means one round trip instead of three and lets
/// siteContentProvider be shared/cached across all of them.
///
/// [aboutUs]/[privacyPolicy]/[termsConditions] are keyed by language code
/// ('en'/'de'/'sq') — an admin must fill in all three on the admin
/// portal's Content page (see albmap-backend's content.service.js), so a
/// screen picks its current locale out of the map via [aboutUsFor] etc.
/// rather than this entity trying to resolve "the" content on its own
/// (it has no BuildContext to read the locale from, and re-fetching on
/// every language switch would be wasteful when the data for every
/// language is already sitting in memory). Falls back to English if the
/// current locale is somehow missing — defensive, not expected in
/// practice once an admin has saved all three. [socialLinks] is
/// deliberately not locale-keyed — a URL isn't translated.
class SiteContentEntity extends Equatable {
  const SiteContentEntity({
    this.aboutUs,
    this.socialLinks,
    this.privacyPolicy,
    this.termsConditions,
  });

  final Map<String, AboutContentEntity>? aboutUs;
  final SocialLinksEntity? socialLinks;
  final Map<String, LegalPageEntity>? privacyPolicy;
  final Map<String, LegalPageEntity>? termsConditions;

  AboutContentEntity? aboutUsFor(String languageCode) => aboutUs?[languageCode] ?? aboutUs?['en'];
  LegalPageEntity? privacyPolicyFor(String languageCode) => privacyPolicy?[languageCode] ?? privacyPolicy?['en'];
  LegalPageEntity? termsConditionsFor(String languageCode) =>
      termsConditions?[languageCode] ?? termsConditions?['en'];

  @override
  List<Object?> get props => [aboutUs, socialLinks, privacyPolicy, termsConditions];
}
