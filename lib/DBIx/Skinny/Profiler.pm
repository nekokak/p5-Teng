package DBIx::Skinny::Profiler;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {
        _query_log => [],
    }, $class;
}

sub reset {
    my $self = shift;
    $self->{_query_log} = [];
}

sub _normalize {
    shift;
    my $sql = shift;
    $sql =~ s/^\s*//;
    $sql =~ s/\s*$//;
    $sql =~ s/[\r\n]/ /g;
    $sql =~ s/\s+/ /g;
    return $sql;
}

sub record_query {
    my ($self, $sql, $bind) = @_;

    my $log = $self->_normalize($sql);
    if (ref $bind eq 'ARRAY') {
        my @binds;
        push @binds, defined $_ ? $_ : 'undef' for @$bind;
        $log .= ' :binds ' . join ', ', @binds;
    }

    push @{ $self->{_query_log} }, $log;
}

sub query_log { $_[0]->{_query_log} }

1;

__END__
=head1 NAME

DBIx::Skinny::Profiler - support query profile.

=head1 SYNOPSIS

in your script:

    use Your::Model;
    use Data::Dumper;
    
    my $row = Your::Model->insert('user',
        {
            id   => 1,
        }
    );
    $row->update({name => 'nekokak'});
    
    $row = Your::Model->search_by_sql(q{SELECT id, name FROM user WHERE id = ?}, [ 1 ]);
    $row->delete('user')
    
    # get queries
    warn Dumper Your::Model->profiler->query_log;
    # The following are displayed. 
    #
    #  INSERT INTO user (id) VALUES (?) :binds 1
    #  UPDATE user set name = ? WHERE = id = ? :binds nekokak 1
    #  SELECT id, name FROM user WHERE id = ? :binds 1
    #  DELETE user WHERE id = ? :binds 1

execute script:

    $ SKINNY_PROFILE=1 perl ./sample.pl

=head1 METHODS

=over

=item $profiler->query_log()

get all execute SQLs.

=item $profile->reset()

Recorded query information is reset.

=cut

