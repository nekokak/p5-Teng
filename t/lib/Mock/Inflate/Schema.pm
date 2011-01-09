package Mock::Inflate::Schema;
use strict;
use warnings;
use DBIx::Skin::Schema::Declare;
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

#    inflate_rule qr/^name$/,
#        inflate => sub {
#            my ($table, $col, $col_value) = @_;
#            return Mock::Inflate::Name->new(name => $value);
#        },
#        delfate => sub {
#            my ($table, $col, $col_value) = @_;
#            return ref $value ? $value->name : $value . '_deflate';
#        }
#    ;
};

1;

