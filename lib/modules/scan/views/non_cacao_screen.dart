import 'package:flutter/material.dart';

import 'scan_unsuccessful_screen.dart';

class NonCacaoScreen extends StatelessWidget {
  const NonCacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScanUnsuccessfulScreen(
      title: 'Not a Cacao Pod',
      message: 'Please scan a cacao pod only and try again.',
    );
  }
}
