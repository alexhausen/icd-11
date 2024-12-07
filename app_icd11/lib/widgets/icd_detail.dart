import 'package:app_icd11/model/condition.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

class IcdDetail extends StatelessWidget {
  const IcdDetail(this.condition, {super.key});

  final Condition? condition;

  Widget _buildDetail(Condition condition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
            'Chapter: ${condition.chapter.number}: ${condition.chapter.title}'),
        if (condition.block != null) Text('Block: ${condition.block?.title}'),
        if (condition.parentCondition != null)
          Text(
              'Parent: ${condition.parentCondition?.code}: ${condition.parentCondition?.title}'),
        Text('${condition.code}: ${condition.title}'),
        Link(
          uri: Uri.parse(condition.url),
          builder: (context, followLink) => RichText(
            text: TextSpan(
              text: "World Health Organization official link",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = followLink,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (condition == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Search and select one condition from the list'),
        ],
      );
    }
    return _buildDetail(condition!);
  }
}
