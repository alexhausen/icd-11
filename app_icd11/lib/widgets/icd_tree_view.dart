import 'package:app_icd11/model/condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

class NodeData {
  NodeData({required this.icon, this.prefix = '', required this.title});
  final String title;
  final Icon icon;
  final String prefix;
  final List<NodeData> children = [];
}

class IcdTreeNode extends StatelessWidget {
  const IcdTreeNode({
    super.key,
    required this.title,
    required this.icon,
    required this.prefix,
  });

  final String title;
  final Icon icon;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        if (prefix.isNotEmpty) SizedBox(width: 10) else Container(),
        Text(prefix),
        SizedBox(width: 5),
        Expanded(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class IcdTreeView extends StatefulWidget {
  const IcdTreeView(this.condition, {super.key});

  final Condition? condition;

  @override
  State<IcdTreeView> createState() => _IcdTreeViewState();
}

class _IcdTreeViewState extends State<IcdTreeView> {
  late final TreeController<NodeData> controller;

  @override
  void initState() {
    super.initState();
    controller = TreeController<NodeData>(
      roots: makeTree(super.widget.condition),
      childrenProvider: (NodeData node) => node.children,
      defaultExpansionState: true,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.roots = makeTree(super.widget.condition);
    return AnimatedTreeView<NodeData>(
      treeController: controller,
      duration: Duration(milliseconds: 300),
      nodeBuilder: (BuildContext context, TreeEntry<NodeData> entry) {
        return TreeIndentation(
          entry: entry,
          child: Row(
            children: [
              if (entry.hasChildren)
                ExpandIcon(
                  key: GlobalObjectKey(entry.node),
                  onPressed: (_) => controller.toggleExpansion(entry.node),
                )
              else
                const SizedBox(
                  height: 40,
                  width: 8,
                ),
              Flexible(
                child: IcdTreeNode(
                  title: entry.node.title,
                  prefix: entry.node.prefix,
                  icon: entry.node.icon,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<NodeData> makeTree(Condition? condition) {
    if (condition == null) {
      return [];
    }
    // stack conditions and then blocks to unstack
    // them from root (chapter) to the condition passed
    final root = NodeData(
      icon: Icon(Icons.folder),
      prefix: condition.chapter.number,
      title: condition.chapter.title,
    );
    List<NodeData> stack = [];
    Block? block = condition.block;
    while (condition != null) {
      stack.add(NodeData(
        icon: Icon(Icons.health_and_safety),
        prefix: condition.code,
        title: condition.title,
      ));
      block = condition.block;
      condition = condition.parentCondition;
    }
    while (block != null) {
      stack.add(NodeData(
        icon: Icon(Icons.folder_outlined),
        title: block.title,
      ));
      block = block.parentBlock;
    }
    NodeData node = root;
    while (stack.isNotEmpty) {
      node.children.add(stack.last);
      node = stack.last;
      stack.removeLast();
    }
    return [root];
  }
}
