import 'dart:ui';

import 'package:app_icd11/data/icd_repository.dart';
import 'package:app_icd11/model/basic_condition.dart';
import 'package:app_icd11/model/condition.dart';
import 'package:app_icd11/widgets/icd_detail.dart';
import 'package:app_icd11/widgets/icd_list_view.dart';
import 'package:app_icd11/widgets/icd_search_bar.dart';
import 'package:app_icd11/widgets/icd_tree_view.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title, required this.repository});

  final String title;

  final IcdRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final AppLifecycleListener listener;

  String searchQuery = '';
  BasicCondition? selectedBasicCondition;
  int? selectedIndex;

  _buildPage() {
    Condition? condition;
    if (selectedBasicCondition != null) {
      try {
        condition =
            super.widget.repository.getCondition(selectedBasicCondition!.id);
      } on Exception catch (e) {
        _showSnackBar(context, e.toString());
      }
    }
    return Column(
      children: [
        IcdSearchBar(onSearchQueryChanged: refreshSearchQuery),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: IcdListView(
                  searchQuery,
                  super.widget.repository,
                  onSelectedConditionChanged: refreshSelectedCondition,
                  selectedIndex: selectedIndex,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(child: IcdDetail(condition)),
                            Expanded(child: IcdTreeView(condition)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  refreshSearchQuery(String newsearchQuery) {
    setState(() {
      searchQuery = newsearchQuery.trim();
      selectedBasicCondition = null;
      selectedIndex = null;
    });
  }

  refreshSelectedCondition(
    BasicCondition newSelectedBasicCondition,
    int? newSelectedIndex,
  ) {
    setState(() {
      selectedBasicCondition = newSelectedBasicCondition;
      selectedIndex = newSelectedIndex;
    });
  }

  @override
  void initState() {
    super.initState();
    listener = AppLifecycleListener(
      onExitRequested: () => Future(() {
        super.widget.repository.dispose();
        return AppExitResponse.exit;
      }),
    );
  }

  @override
  void dispose() {
    listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _buildPage(),
    );
  }

  void _showSnackBar(BuildContext context, String content) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $content')));
  }
}
