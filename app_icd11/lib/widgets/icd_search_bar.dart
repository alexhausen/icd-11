import 'package:flutter/material.dart';

class IcdSearchBar extends StatefulWidget {
  final void Function(String) onSearchQueryChanged;

  const IcdSearchBar({super.key, required this.onSearchQueryChanged});

  @override
  State<IcdSearchBar> createState() => _IcdSearchBarState();
}

class _IcdSearchBarState extends State<IcdSearchBar> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final clearButton = IconButton(
      onPressed: () {
        controller.clear();
        setState(() => super.widget.onSearchQueryChanged(''));
      },
      icon: Icon(Icons.clear),
    );
    return TextField(
      controller: controller,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Enter code or description',
        prefixIcon: Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty ? clearButton : null,
      ),
      onChanged: (searchQuery) {
        setState(() => super.widget.onSearchQueryChanged(searchQuery));
      },
    );
  }
}
