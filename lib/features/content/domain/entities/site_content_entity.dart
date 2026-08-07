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
class SiteContentEntity extends Equatable {
  const SiteContentEntity({
    this.aboutUs,
    this.socialLinks,
    this.privacyPolicy,
    this.termsConditions,
  });

  final AboutContentEntity? aboutUs;
  final SocialLinksEntity? socialLinks;
  final LegalPageEntity? privacyPolicy;
  final LegalPageEntity? termsConditions;

  @override
  List<Object?> get props => [aboutUs, socialLinks, privacyPolicy, termsConditions];
}
