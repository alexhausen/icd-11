import 'package:app_icd11/data/icd_repository.dart';
import 'package:app_icd11/model/basic_condition.dart';
import 'package:flutter/material.dart';

class IcdListView extends StatefulWidget {
  const IcdListView(
    this.searchQuery,
    this.repository, {
    super.key,
    required this.onSelectedConditionChanged,
    required this.selectedIndex,
  });

  final void Function(BasicCondition, int?) onSelectedConditionChanged;
  final String searchQuery;
  final IcdRepository repository;
  final int? selectedIndex;

  @override
  State<IcdListView> createState() => _IcdListViewState();
}

class _IcdListViewState extends State<IcdListView> {
  List<BasicCondition> conditions = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    conditions =
        super.widget.repository.listConditions(super.widget.searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    conditions =
        super.widget.repository.listConditions(super.widget.searchQuery);
    return Scrollbar(
      controller: _scrollController,
      child: ListView.builder(
        itemCount: 500, //conditions.length,
        itemBuilder: (ctx, index) {
          if (index >= conditions.length) return null;
          return ListTile(
            leading: Text(conditions[index].code),
            title: Text(conditions[index].title),
            textColor: super.widget.selectedIndex == index
                ? Theme.of(context).colorScheme.onPrimary
                : null,
            tileColor: super.widget.selectedIndex == index
                ? Theme.of(context).colorScheme.primary
                : null,
            onTap: () {
              super.widget.onSelectedConditionChanged(conditions[index], index);
            },
          );
        },
        controller: _scrollController,
        scrollDirection: Axis.vertical,
      ),
    );
  }
}
