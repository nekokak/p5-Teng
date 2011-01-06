package DBIx::Skinny::DBD::SQLite;
use strict;
use warnings;
use base 'DBIx::Skinny::DBD::Base';

sub bind_param_attributes {
    my($self, $data_type) = @_;

    if ($data_type) {
        if ($data_type =~ /blob/i || $data_type =~ /bin/i || $data_type =~ /\Abigint\Z/i) {
            return DBI::SQL_BLOB;
        }
    }
    return;
}

1;

