package DBIx::Skinny::DBD::mysql;
use strict;
use warnings;
use base 'DBIx::Skinny::DBD::Base';

sub sql_for_unixtime { "UNIX_TIMESTAMP()" }

sub bulk_insert {
    my ($skinny, $table, $args) = @_;

    return unless @$args;

    my (@cols, @bind);
    for my $arg (@{$args}) {
        # deflate
        for my $col (keys %{$arg}) {
            $arg->{$col} = $skinny->schema->call_deflate($col, $arg->{$col});
        }

        if (scalar(@cols)==0) {
            for my $col (keys %{$arg}) {
                push @cols, $col;
            }
        }

        for my $col (keys %{$arg}) {
            push @bind, $skinny->schema->utf8_off($col, $arg->{$col});
        }
    }

    my $sql = "INSERT INTO $table\n";
    $sql .= '(' . join(', ', @cols) . ')' . "\nVALUES ";

    my $values = '(' . join(', ', ('?') x @cols) . ')' . "\n";
    $sql .= join(',', ($values) x (scalar(@bind) / scalar(@cols)));

    $skinny->_execute($sql, \@bind);

    return 1;
}

1;

