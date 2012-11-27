package Mock::Inflate::Schema;
use strict;
use warnings;
use Teng::Schema::Declare;
use Mock::Inflate::Name;

table {
    name 'mock_inflate';
    pk qw/ id bar /;
    columns qw/ id name foo bar /;
    inflate 'name' => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate 'name' => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
    inflate qr/.+oo/ => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate qr/.+oo/ => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
    inflate 'bar' => sub {
        my ($col_value) = @_;
        return Mock::Inflate::Name->new(name => $col_value);
    };
    deflate 'bar' => sub {
        my ($col_value) = @_;
        return ref $col_value ? $col_value->name : $col_value . '_deflate';
    };
};

1;

