package Teng::Plugin::Pager::Any;

use strict;
use warnings;
use Class::Load ();

our @EXPORT = qw/search_with_pager pager_class/;
my %pager_class;

sub init {
    my ($pkg, $class, $opt) = @_;
    if (my @classes = @{$opt->{pager_classes} || [qw/Pager Count MySQLFoundRows/] }) {
        $class->pager_class($classes[0]);
        foreach my $class (@classes) {
            if ($class =~s{^\+}{}) {
                Class::Load::load_class($class);
            } elsif (not $class or $class eq 'Pager') {
                Class::Load::load_class('Teng::Plugin::Pager');
            } else {
                Class::Load::load_class('Teng::Plugin::Pager::' . $class);
            }
        }
    }
}

sub search_with_pager {
    my ($self, $table_name, $where, $opt) = @_;

    my $full_pager_class = 'Teng::Plugin::Pager';
    if (my $pager_class = delete $opt->{pager_class} || $self->pager_class) {
        if ($pager_class =~ s{^\+}{}) {
            $full_pager_class = $pager_class;
        } elsif ($pager_class ne 'Pager') {
            Carp::croak("Don't use 'Any' as pager_class.") if $pager_class eq 'Any';

            $full_pager_class .= '::' . $pager_class;
        }
    }
    my $pager_method = $full_pager_class . '::search_with_pager';

    $self->$pager_method($table_name, $where, $opt);
}

sub pager_class {
    my $class = ref($_[0]) ? ref($_[0]) : $_[0];
    $pager_class{$class} = $_[1] if @_ > 1;
    $pager_class{$class} || '';
}

1;
__END__

=for test_synopsis

my ($dbh, $c);

=head1 NAME

Teng::Plugin::Pager::Any - enable to choose Pager class for search_with_pager

=head1 SYNOPSIS

    package MyApp::DB;
    use parent qw/Teng/;
    __PACKAGE__->load_plugin('Pager::Any');

    package main;
    my $db = MyApp::DB->new(dbh => $dbh);
    my $page = $c->req->param('page') || 1;
    my ($rows, $pager) = $db->search_with_pager('user' => {type => 3}, {page => $page, rows => 5, pager_class => 'Count'});

When you want to specify Pager classes:

    __PACKAGE__->load_plugin('Pager::Any', {pager_classes => ['Pager', 'Count', '+YourClass::Pager']});

=head1 DESCRIPTION

This is a helper to use pagination class.

=head1 load_plugin OPTION

=over 4

=item pager_classes

    __PACKAGE__->load_plugin('Pager::Any', {pager_classes => ['Pager', 'Count']});

This option is to choose pager classes and set first passed class as a defualt pager class.
If you don't pass this option, automatically load Pager, Pager::Count and Pager::MySQLFoundRows.

If you want to load your own pager class, add C<+> to the class name:

    __PACKAGE__->load_plugin('Pager::Any', {pager_classes => ['Pager', 'Count', '+YourClass::Pager']});

=back

=head1 METHODS

=over 4

=item my (\@rows, $pager) = $db->search_with_pager($table_name, \%where, \%opts)

Select from database with pagination.

The arguments are mostly same as C<$db->search()>. But three additional options are available.

=over 4

=item $opts->{page}

Current page number.

=item $opts->{rows}

The number of entries per page.

=item $opts->{pager_class}

Pager class you want to use. default is Teng::Plugin::Pager or first class in pager_classes load_plugin option.

=back

=item $db->pager_class($pager_class);

set default pager class.

=back
