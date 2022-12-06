import 'package:flutter/material.dart';

import 'package:coopaz_app/logger.dart';

class CashRegisterScreen extends StatelessWidget {
  const CashRegisterScreen({super.key});

  final String title = 'Caisse';

  @override
  Widget build(BuildContext context) {
    log('build screen $title');

    return Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: const Center(child: Text('Caisse')));
  }
}
