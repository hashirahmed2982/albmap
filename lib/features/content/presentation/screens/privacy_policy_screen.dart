import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'legal_page_view.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageView(
      title: 'privacyPolicy.title'.tr(),
      icon: Icons.privacy_tip_outlined,
      selector: (content) => content.privacyPolicy,
    );
  }
}
