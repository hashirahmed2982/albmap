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

class SiteContentModel extends SiteContentEntity {
  const SiteContentModel({
    super.aboutUs,
    super.socialLinks,
    super.privacyPolicy,
    super.termsConditions,
  });

  factory SiteContentModel.fromJson(Map<String, dynamic> json) {
    return SiteContentModel(
      aboutUs: json['aboutUs'] != null
          ? AboutContentModel.fromJson(json['aboutUs'] as Map<String, dynamic>)
          : null,
      socialLinks: json['socialLinks'] != null
          ? SocialLinksModel.fromJson(json['socialLinks'] as Map<String, dynamic>)
          : null,
      privacyPolicy: json['privacyPolicy'] != null
          ? LegalPageModel.fromJson(json['privacyPolicy'] as Map<String, dynamic>)
          : null,
      termsConditions: json['termsConditions'] != null
          ? LegalPageModel.fromJson(json['termsConditions'] as Map<String, dynamic>)
          : null,
    );
  }
}
