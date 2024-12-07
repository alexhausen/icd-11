class Condition {
  Condition({
    required this.id,
    required this.code,
    required this.title,
    required this.url,
    required this.isResidual,
    required this.chapter,
  });

  int id;
  String code;
  String title;
  bool isResidual;
  String url;
  Condition? parentCondition;
  Block? block;
  Chapter chapter;
}

class Chapter {
  Chapter({required this.number, required this.title});

  String number;
  String title;
}

class Block {
  Block({required this.title});

  String title;
  Block? parentBlock;
}
