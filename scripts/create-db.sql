PRAGMA foreign_keys = OFF;

drop table if exists condition;
drop table if exists block;
drop table if exists chapter;

PRAGMA foreign_keys = ON;

create table chapter(
  chapter_id integer not null,
  title text not null unique,
  chapter_no text not null unique,

  primary key(chapter_id) 
);

create table block(
  block_id integer not null,
  chapter_id integer not null,
  title text not null,
  parent_block_id integer,

  primary key (block_id),
  foreign key (chapter_id)
    references chapter (chapter_id)
    on delete cascade,
   foreign key (parent_block_id)
     references block(block_id)
     on delete set null
);

create table condition(
  condition_id integer not null,
  chapter_id integer not null,
  block_id integer,
  parent_condition_id integer,
  code text not null unique,
  title text not null,
  is_residual boolean not null,
  url text not null,

  primary key (condition_id),
  foreign key (chapter_id)
    references chapter(chapter_id)
    on delete cascade,
  foreign key (block_id)
    references block(block_id)
    on delete cascade,
  foreign key (parent_condition_id)
    references condition(condition_id)
    on delete set null
);
