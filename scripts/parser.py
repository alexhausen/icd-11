import csv
import re
import sys

from pathlib import Path

def get_global_depth(s: str):
    return re.match(r"^(- )*.*?", s).end() / 2

class Condition:
    condition_id = 1
    def __init__(self, row):
        self.condition_id = Condition.condition_id
        Condition.condition_id += 1
        self.parent: Condition = None
        self.block: Block = None
        self.chapter: Chapter = None
        self.global_depth = get_global_depth(row["Title"])
        self.title = row["Title"].lstrip("- ").rstrip().replace("'", "’")
        self.code = row["Code"]
        self.is_residual = row["IsResidual"] # other specified or unspecified categories
        self.depth = int(row["DepthInKind"])
        self.url = re.match(
            r'^=hyperlink\("(.*)",.*\)',
            row["BrowserLink"]
        ).group(1)

    def __str__(self) -> str:
        parent_code = self.parent.code if self.parent else "-"
        block_title = f"{self.block.title}" if self.block else "-"
        return f"{self.chapter.chapter_no} ({block_title}) ({parent_code}) {self.code}: {self.title}"


class Block:
    block_id = 1
    def __init__(self, row):
        self.block_id = Block.block_id
        Block.block_id += 1
        self.parent: Block = None
        self.global_depth = get_global_depth(row["Title"])
        self.title = row["Title"].lstrip("- ").rstrip().replace("'", "’")
        self.depth = int(row["DepthInKind"])

    def __str__(self) -> str:
        return f"{self.counter}:{self.title}"


class Chapter:
    chapter_id = 1
    def __init__(self, row):
        self.chapter_id = Chapter.chapter_id
        Chapter.chapter_id += 1
        self.blocks: list[Block] = []
        self.conditions: dict[str, Condition] = {}
        self.title = row["Title"].lstrip("- ").rstrip().replace("'", "’")
        self.chapter_no = row["ChapterNo"]
        self.condition_stack = []
        self.last_condition: Condition = None
        self.block_stack = []
        self.last_block: Block = None

    def add_block(self, block: Block):
        self.blocks.append(block)
        self.last_condition: Condition = None
        self.condition_stack = []
        depth = block.depth - 1
        if depth > len(self.block_stack):
            self.block_stack.append(self.last_block)
        else:
            while depth < len(self.condition_stack):
                self.condition_stack.pop()
        if len(self.block_stack) > 0:
            block.parent = self.block_stack[-1]
        self.last_block = block

    def add_condition(self, condition: Condition):
        self.conditions[condition.code] = condition
        condition.chapter = self
        depth = condition.depth - 1
        if depth > len(self.condition_stack):
            self.condition_stack.append(self.last_condition)
        else:
            while depth < len(self.condition_stack):
                self.condition_stack.pop()
        if len(self.condition_stack) > 0:
            condition.parent = self.condition_stack[-1]
        self.last_condition = condition
        # keep poping untilt the condition is inside a block
        while self.last_block and self.last_block.global_depth >= condition.global_depth:
            if len(self.block_stack) > 0:
                self.last_block = self.block_stack.pop()
            else:
                self.last_block = None
        condition.block = self.last_block


class Icd:
    def __init__(self):
        self.chapters: dict[str, Chapter] = {}

    def add_chapter(self, chapter: Chapter):
        self.current_chapter_no: str = chapter.chapter_no
        self.chapters[chapter.chapter_no] = chapter

    def add_block(self, block: Block):
        self.chapters[self.current_chapter_no].add_block(block)

    def add_condition(self, condition: Condition):
        self.chapters[self.current_chapter_no].add_condition(condition)

    def parse_tsv(self, tsv_filename) -> tuple[int, int, int, int]:
        chapter_counter = 0
        block_counter = 0
        condition_counter = 0
        line_no = 0
        with open(tsv_filename, newline="") as tsv_file:
            tsv_reader = csv.DictReader(tsv_file, delimiter="\t")
            for row in tsv_reader:
                line_no += 1
                if row["ClassKind"] == "chapter":
                    chapter_counter += 1
                    chapter = Chapter(row)
                    self.add_chapter(chapter)
                elif row["ClassKind"] == "block":
                    block_counter += 1
                    block = Block(row)
                    self.add_block(block)
                elif row["ClassKind"] == "category":
                    condition_counter += 1
                    condition = Condition(row)
                    self.add_condition(condition)
        return (chapter_counter, block_counter, condition_counter, line_no)
    
    def to_sql(self, tsv_filename):
        sql_filename = Path(tsv_filename).with_suffix('.sql')
        with open(sql_filename, mode="w") as sql_file:
            # chapters
            sql_chapters = "insert into chapter (chapter_id, title, chapter_no) values "
            chapter_values = []
            for chapter in self.chapters.values():
                chapter_values.append(f"({chapter.chapter_id}, '{chapter.title}', '{chapter.chapter_no}')\n")
            sql_chapters += ", ".join(chapter_values) + ";\n"
            sql_file.write(sql_chapters)
            # blocks
            sql_blocks = "insert into block (block_id, chapter_id, title, parent_block_id) values "
            block_values = []
            for chapter in self.chapters.values():
                for block in chapter.blocks:
                    parent_block_id = f"{block.parent.block_id}" if block.parent else "NULL"
                    block_values.append(f"({block.block_id}, {chapter.chapter_id}, '{block.title}', {parent_block_id})\n")
            sql_blocks += ", ".join(block_values) + ";\n"
            sql_file.write(sql_blocks)
            # conditions
            sql_conditions = "insert into condition (condition_id, chapter_id, block_id, parent_condition_id, code, title, is_residual, url) values "
            condition_values = []
            for chapter in self.chapters.values():
                for condition in chapter.conditions.values():
                    block_id = condition.block.block_id if condition.block else "NULL"
                    parent_condition_id = condition.parent.condition_id if condition.parent else "NULL"
                    condition_values.append(f"({condition.condition_id}, {condition.chapter.chapter_id}, {block_id}, {parent_condition_id}, "
                                            f"'{condition.code}', '{condition.title}', {condition.is_residual}, '{condition.url}')\n")
            sql_conditions += ", ".join(condition_values) + ";\n"
            sql_file.write(sql_conditions)


    def __str__(self) -> str:
        r = ""
        for chapter in self.chapters.values():
            for condition in chapter.conditions.values():
                r += condition.__str__() + "\n"
        return r


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <icd-11.tsv>")
        sys.exit(1)

    icd = Icd()
    chapter_counter, block_counter, condition_counter, line_no = icd.parse_tsv(sys.argv[1])
    icd.to_sql(sys.argv[1])

    # print(icd)
    print(f"Lines: {line_no}\nChapters: {chapter_counter}\nBlocks: "
          f"{block_counter}\nConditions: {condition_counter}")
