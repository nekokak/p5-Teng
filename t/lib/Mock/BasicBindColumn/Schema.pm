package Mock::BasicBindColumn::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;

table {
    name 'mock_basic_bind_column';
    pk 'id';

    my @columns = (
        'id',
        {
            name => 'uid',
            type => 'bigint',
        },
        'name',
        {
            name => 'body',
            type => 'blob',
        },
        {
            name => 'raw',
            type => 'bin',
        },
    );
    columns @columns;
};

1;

