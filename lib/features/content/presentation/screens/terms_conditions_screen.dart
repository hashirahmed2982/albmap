import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'legal_page_view.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LegalPageView(
      title: 'termsConditions.title'.tr(),
      icon: Icons.description_outlined,
      selector: (content) => content.termsConditions,
    );
  }
}
