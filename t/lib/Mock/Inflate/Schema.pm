package Mock::Inflate::Schema;
use strict;
use warnings;
use DBIx::Skin::Schema;
use Mock::Inflate::Name;

table {
    name 'mock_inflate';
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

