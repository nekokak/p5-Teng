package Mock::Inflate::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;
use Mock::Inflate::Name;

table {
    name 'mock_inflate';
    pk 'id';
    columns qw/ id name /;
    inflate 'name' => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate 'name' => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
};

1;

