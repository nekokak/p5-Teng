package t::Utils;
use strict;
use warnings;
use utf8;
use Test::More;

sub import {
    strict->import;
    warnings->import;
    utf8->import;
}

sub prepare_db {
    my ( $schema_class, $dbh ) = @_;

    if ( ! $schema_class->isa( 'TengTest' ) ) {
        die "Don't know how to setup $schema_class";
    }
    $schema_class->prepare_db( $dbh );
}

sub setup_dbh {
    shift;
    my $file = shift || ':memory:';
    DBI->connect('dbi:SQLite:'.$file,'','',{RaiseError => 1, PrintError => 0, AutoCommit => 1});
}

1;

