import '../../domain/entities/site_content_entity.dart';

class AboutContentModel extends AboutContentEntity {
  const AboutContentModel({
    required super.tagline,
    required super.missionTitle,
    required super.missionBody,
    required super.visionTitle,
    required super.visionBody,
  });

  factory AboutContentModel.fromJson(Map<String, dynamic> json) {
    return AboutContentModel(
      tagline: json['tagline'] as String? ?? '',
      missionTitle: json['missionTitle'] as String? ?? '',
      missionBody: json['missionBody'] as String? ?? '',
      visionTitle: json['visionTitle'] as String? ?? '',
      visionBody: json['visionBody'] as String? ?? '',
    );
  }
}

class SocialLinksModel extends SocialLinksEntity {
  const SocialLinksModel({
    super.facebook,
    super.instagram,
    super.twitter,
    super.tiktok,
    super.youtube,
    super.linkedin,
  });

  factory SocialLinksModel.fromJson(Map<String, dynamic> json) {
    return SocialLinksModel(
      facebook: json['facebook'] as String?,
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      tiktok: json['tiktok'] as String?,
      youtube: json['youtube'] as String?,
      linkedin: json['linkedin'] as String?,
    );
  }
}

class LegalSectionModel extends LegalSectionEntity {
  const LegalSectionModel({required super.heading, required super.body});

  factory LegalSectionModel.fromJson(Map<String, dynamic> json) {
    return LegalSectionModel(
      heading: json['heading'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

class LegalPageModel extends LegalPageEntity {
  const LegalPageModel({required super.title, required super.sections});

  factory LegalPageModel.fromJson(Map<String, dynamic> json) {
    return LegalPageModel(
      title: json['title'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => LegalSectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// Every language a localized content key can come back with — matches
// albmap-backend's content.service.js SUPPORTED_LOCALES. Iterated rather
// than hardcoded per-field so a locale that's genuinely missing (an old
// row from before this shipped, not yet re-saved by an admin) is just
// absent from the map instead of throwing.
const _kContentLocales = ['en', 'de', 'sq'];

/// Picks out the locale sub-objects from one localized content key's
/// backend payload (`{ en: {...}, de: {...}, sq: {...}, updatedAt }`) and
/// parses each with [fromJson], skipping `updatedAt` and any locale
/// that's missing/malformed rather than crashing over one bad language.
Map<String, T>? _parseLocalized<T>(
  dynamic raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! Map<String, dynamic>) return null;
  final result = <String, T>{};
  for (final locale in _kContentLocales) {
    final localeJson = raw[locale];
    if (localeJson is Map<String, dynamic>) {
      result[locale] = fromJson(localeJson);
    }
  }
  return result.isEmpty ? null : result;
}

class SiteContentModel extends SiteContentEntity {
  const SiteContentModel({
    super.aboutUs,
    super.socialLinks,
    super.privacyPolicy,
    super.termsConditions,
  });

  factory SiteContentModel.fromJson(Map<String, dynamic> json) {
    return SiteContentModel(
      aboutUs: _parseLocalized(json['aboutUs'], AboutContentModel.fromJson),
      socialLinks: json['socialLinks'] != null
          ? SocialLinksModel.fromJson(json['socialLinks'] as Map<String, dynamic>)
          : null,
      privacyPolicy: _parseLocalized(json['privacyPolicy'], LegalPageModel.fromJson),
      termsConditions: _parseLocalized(json['termsConditions'], LegalPageModel.fromJson),
    );
  }
}
