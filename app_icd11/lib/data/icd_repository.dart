import 'package:app_icd11/model/basic_condition.dart';
import 'package:app_icd11/model/condition.dart';
import 'package:sqlite3/sqlite3.dart';

class IcdRepository {
  final _db = sqlite3.open("icd-en.db");

  IcdRepository() {
    // print('Using sqlite3 ${sqlite3.version}');
  }

  dispose() {
    _db.dispose();
  }

  List<BasicCondition> listConditions(String filter) {
    String query;
    List<String> params = [];
    if (filter.isEmpty) {
      query = '''
        SELECT condition_id, code, title
        FROM condition
        ORDER BY code
        ''';
    } else {
      query = '''
        SELECT condition_id, code, title 
        FROM condition
        WHERE code LIKE ? OR title LIKE ? ORDER BY code
        ''';
      params = ['$filter%', '%$filter%'];
    }
    final resultSet = _db.select(query, params);
    return resultSet
        .map(
          (final row) => BasicCondition(
            id: row['condition_id'],
            code: row['code'],
            title: row['title'],
          ),
        )
        .toList();
  }

  Condition? _getCondition(int? id) {
    if (id == null) return null;
    if (id <= 0) throw ArgumentError.value(id, "Zero or negative ID");
    final conditionQuery = '''
      SELECT
        condition_id,
        parent_condition_id,
        condition.code,
        condition.title as condition_title,
        condition.url,
        condition.is_residual,
        condition.chapter_id,
        chapter.chapter_no,
        chapter.title as chapter_title,
        condition.block_id,
        block.title as block_title,
        block.parent_block_id
      FROM condition
      JOIN chapter on condition.chapter_id = chapter.chapter_id
      LEFT JOIN block on condition.block_id = block.block_id
      WHERE condition_id = ?
      ''';
    final resultSet = _db.select(conditionQuery, [id]);
    if (resultSet.length != 1) {
      throw Exception('Unexpected rows for ID: $id (${resultSet.length})');
    }
    final row = resultSet.first;
    final condition = Condition(
      id: row['condition_id'],
      code: row['code'],
      title: row['condition_title'],
      url: row['url'],
      isResidual: row['is_residual'] == 1,
      chapter: Chapter(number: row['chapter_no'], title: row['chapter_title']),
    );
    condition.parentCondition = _getCondition(row['parent_condition_id']);
    int? blockId = row['block_id'];
    if (condition.parentCondition == null && blockId != null) {
      var block = Block(title: row['block_title']);
      condition.block = block;
      final blockQuery = '''
        SELECT title, parent_block_id
        FROM block
        WHERE block_id = ?
        ''';
      blockId = row['parent_block_id'];
      while (blockId != null) {
        final blockResult = _db.select(blockQuery, [blockId]);
        if (blockResult.length != 1) {
          throw Exception(
              'Unexpected blocks for ID: $id (${blockResult.length})');
        }
        final blockRow = blockResult.first;
        block.parentBlock = Block(title: blockRow['title']);
        block = block.parentBlock!;
        blockId = blockRow['parent_block_id'];
      }
    }
    return condition;
  }

  Condition getCondition(int id) {
    final Condition? condition = _getCondition(id);
    if (condition == null) throw Exception('Null condition for ID $id');
    return condition;
  }
}
