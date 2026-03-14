import 'package:flutter/material.dart';

import '../shared/design_system.dart';
import 'router.dart';

class IronRepApp extends StatelessWidget {
  const IronRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IronRep',
      theme: IronRepTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
