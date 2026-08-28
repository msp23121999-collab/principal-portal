import 'package:flutter/material.dart';

import 'app.dart';

/// Compatibility entrypoint for the ERP router.
///
/// The principal portal now lives under core/ and features/. This adapter
/// keeps the existing /principal route contract stable.
class PrincipalPortalPage extends StatelessWidget {
  const PrincipalPortalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PrincipalPortalApp();
  }
}
