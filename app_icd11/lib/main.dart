import 'package:app_icd11/data/icd_repository.dart';
import 'package:app_icd11/pages/home.dart';
import 'package:flutter/material.dart';

void main() {
  final repository = IcdRepository();
  runApp(AppIcd11(repository: repository));
}

class AppIcd11 extends StatelessWidget {
  const AppIcd11({super.key, required this.repository});

  final IcdRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ICD-11',
      theme: ThemeData(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: HomePage(
        title: 'ICD-11 for Mortality and Morbidity Statistics',
        repository: repository,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
