package Mock::Inflate::Schema;
use DBIx::Skinny::Schema;
use Mock::Inflate::Name;

install_table mock_inflate => schema {
    pk 'id';
    columns qw/
        id
        name
    /;
};

install_inflate_rule '^name$' => callback {
    inflate {
        my $value = shift;
        return Mock::Inflate::Name->new(name => $value);
    };
    deflate {
        my $value = shift;
        return ref $value ? $value->name : $value.'_deflate';
    };
};

1;

