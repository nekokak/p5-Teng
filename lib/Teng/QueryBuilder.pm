package Teng::QueryBuilder;
use strict;
use warnings;
use utf8;
use parent qw/SQL::Maker/;

__PACKAGE__->load_plugin('InsertMulti');

1;

