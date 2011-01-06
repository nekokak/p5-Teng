package DBIx::Skinny::Schema;
use strict;
use warnings;
use DBIx::Skinny::Util;

BEGIN {
    *utf8_on  = DBIx::Skinny::Util::utf8_on;
    *utf8_off = DBIx::Skinny::Util::utf8_off;
}

sub import {
    my $caller = caller;

    my @functions = qw/
        install_table
          schema pk columns schema_info column_type row_class
        install_inflate_rule
          inflate deflate call_inflate call_deflate
          callback _do_inflate
        install_common_trigger trigger call_trigger
        install_utf8_columns
          is_utf8_column utf8_on utf8_off
    /;
    no strict 'refs';
    for my $func (@functions) {
        *{"$caller\::$func"} = \&$func;
    }

    my $_schema_info = {};
    *{"$caller\::schema_info"} = sub { $_schema_info };
    my $_schema_inflate_rule = {};
    *{"$caller\::inflate_rules"} = sub { $_schema_inflate_rule };
    my $_schema_common_triggers = {};
    *{"$caller\::common_triggers"} = sub { $_schema_common_triggers };
    my $_utf8_columns = {};
    *{"$caller\::utf8_columns"} = sub { $_utf8_columns };

    strict->import;
    warnings->import;
}

sub install_table ($$) {
    my ($table, $install_code) = @_;

    my $class = caller;
    $class->schema_info->{_installing_table} = $table;
        $install_code->();
    $class->schema_info->{$table}->{row_class} ||= DBIx::Skinny::Util::mk_row_class($class, $table);

    delete $class->schema_info->{_installing_table};
}

sub schema (&) { shift }

sub pk {
    my @columns = @_;

    my $class = caller;
    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{pk} = (@columns == 1 ? $columns[0] : \@columns);
}

sub row_class ($) {
    my $row_class = shift;

    DBIx::Skinny::Util::load_class($row_class) or die "$row_class not found or compile error.";
    my $class = caller;
    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{row_class} = $row_class;
}

sub columns (@) {
    my @columns = @_;

    my (@_columns, %_column_types);
    for my $item (@columns) {
        if (not ref $item) {
            push @_columns, $item;
        } elsif (ref $item eq 'HASH') {
            push @_columns, $item->{name};
            $_column_types{$item->{name}} = $item->{type};
        } else {
            die "columns must be 'SCALAR' or 'HASHREF'";    
        }
    }

    my $class = caller;
    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{columns} = \@_columns;

    $class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{column_types} = \%_column_types;
}

sub column_type {
    my ($class, $table, $column) = @_;
    exists $class->schema_info->{$table}->{column_types}->{$column} ? $class->schema_info->{$table}->{column_types}->{$column}
                                                                    : undef;
}

sub trigger ($$) {
    my ($trigger_name, $code) = @_;

    my $class = caller;
    push @{$class->schema_info->{
        $class->schema_info->{_installing_table}
    }->{trigger}->{$trigger_name}}, $code;
}

sub call_trigger {
    my ($class, $skinny, $table, $trigger_name, $args) = @_;

    my $common_triggers = $class->common_triggers->{$trigger_name};
    for my $code (@$common_triggers) {
        $code->($skinny, $args, $table);
    }

    my $triggers = $class->schema_info->{$table}->{trigger}->{$trigger_name};
    for my $code (@$triggers) {
        $code->($skinny, $args, $table);
    }
}

sub install_inflate_rule ($$) {
    my ($rule, $install_inflate_code) = @_;

    my $class = caller;
    $class->inflate_rules->{_installing_rule} = $rule;
        $install_inflate_code->();
    delete $class->inflate_rules->{_installing_rule};
}

sub inflate (&) {
    my $code = shift;    

    my $class = caller;
    $class->inflate_rules->{
        $class->inflate_rules->{_installing_rule}
    }->{inflate} = $code;
}

sub deflate (&) {
    my $code = shift;

    my $class = caller;
    $class->inflate_rules->{
        $class->inflate_rules->{_installing_rule}
    }->{deflate} = $code;
}

sub call_inflate {
    my $class = shift;

    return $class->_do_inflate('inflate', @_);
}

sub call_deflate {
    my $class = shift;

    return $_[1] if ref $_[1] eq 'SCALAR'; # to ignore \"foo + 1"
    return $class->_do_inflate('deflate', @_);
}

sub _do_inflate {
    my ($class, $key, $col, $data) = @_;

    my $inflate_rules = $class->inflate_rules;
    for my $rule (keys %{$inflate_rules}) {
        if ($col =~ /$rule/ and my $code = $inflate_rules->{$rule}->{$key}) {
            $data = $code->($data);
        }
    }
    return $data;
}

sub callback (&) { shift }

sub install_common_trigger ($$) {
    my ($trigger_name, $code) = @_;

    my $class = caller;
    push @{$class->common_triggers->{$trigger_name}}, $code;
}

sub install_utf8_columns (@) {
    my @columns = @_;

    my $class = caller;
    for my $col (@columns) {
        $class->utf8_columns->{$col} = 1;
    }
}

sub is_utf8_column {
    my ($class, $col) = @_;
    return $class->utf8_columns->{$col} ? 1 : 0;
}

1;

__END__

=head1 NAME

DBIx::Skinny::Schema - Schema DSL for DBIx::Skinny

=head1 SYNOPSIS

    package Your::Model;
    use DBIx::Skinny connect_info => +{
        dsn => 'dbi:SQLite:',
        username => '',
        password => '',
    };
    1;
    
    package Your::Model::Schema:
    use DBIx::Skinny::Schema;
    
    install_utf8_columns qw/name/; # for utf8 columns
    
    # set user table schema settings
    install_table user => schema {
        pk 'id';
        columns qw/id name created_at/;

        trigger pre_insert => callback {
            # hook
        };

        trigger pre_update => callback {
            # hook
        };

        row_class 'Your::Model::Row::User';
    };

    install_inflate_rule '^name$' => callback {
        inflate {
            my $value = shift;
            # inflate hook
        };
        deflate {
            my $value = shift;
            # deflate hook
        };
    };
    
    1;


