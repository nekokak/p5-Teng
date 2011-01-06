package Mock::BasicBindColumn::Schema;
use DBIx::Skinny::Schema;

install_table mock_basic_bind_column => schema {
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

