package DBIx::Skinny::SQL::Oracle;
use strict;
use warnings;
use base qw(DBIx::Skinny::SQL);

## Oracle doesn't have the LIMIT clause.
sub as_limit {
    return '';
}

## Override as_sql to emulate the LIMIT clause.
sub as_sql {
    my $stmt   = shift;
    my $limit  = $stmt->limit;
    my $offset = $stmt->offset;

    if (defined $limit && defined $offset) {
        $stmt->select( @{ $stmt->select }, "ROW_NUMBER() OVER (ORDER BY 1) R" );
    }

    my $sql = $stmt->SUPER::as_sql(@_);

    if (defined $limit) {
        $sql = "SELECT * FROM ( $sql ) WHERE ";
        if (defined $offset) {
            $sql = $sql . " R BETWEEN $offset + 1 AND $limit + $offset";
        } else {
            $sql = $sql . " rownum <= $limit";
        }
    }
    return $sql;
}

'base code from Data::ObjectDriver::SQL::Oracle';
