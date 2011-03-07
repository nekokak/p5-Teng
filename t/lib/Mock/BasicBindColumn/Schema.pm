package Mock::BasicBindColumn::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;
use DBI qw/:sql_types/;

table {
    name 'mock_basic_bind_column';
    pk 'id';

    my @columns = (
        'id',
        {
            name => 'uid',
            type => SQL_BIGINT,
        },
        'name',
        {
            name => 'body',
            type => SQL_BLOB,
        },
        {
            name => 'raw',
            type => SQL_BLOB,
        },
    );
    columns @columns;
};

1;

