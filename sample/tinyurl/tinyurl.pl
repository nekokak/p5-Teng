#! /usr/local/bin/perl
use strict;
use warnings;
use lib '.';
use Sample;
use Data::Dumper;

Sample->setup_db;

sub class_method {
    my $row = Sample->insert('tinyurl',{
        id  => 1,
        url => 'http://nekokak.org/',
    });
    print $row->get_column('url'), ':', $row->url, "\n";

    Sample->bulk_insert('tinyurl',[
        {
            id  => 2,
            url => 'http://nekokak.org/blog.cgi',
        },
        {
            id  => 3,
            url => 'http://search.cpan.org/dist/DBIx-Skinny/',
        },
    ]);

    print "---------------------------------\n";
    my $itr = Sample->search('tinyurl', {});
    while (my $row = $itr->next) {
        print $row->get_column('url'), ':', $row->url, "\n";
    }
    print "---------------------------------\n";

    $row = Sample->single('tinyurl',{id => 1});
    print $row->get_column('url'), ':', $row->url, "\n";
    $row->set({url => 'http://d.hatena.ne.jp/nekokak/'});
    print $row->get_column('url'), ':', $row->url, "\n";
    $row->update;
    print "---------------------------------\n";

    $row = Sample->single('tinyurl',{id => 1});
    print $row->get_column('url'), ':', $row->url, "\n";
    my $del_count = $row->delete;
    print $del_count, "\n";
    print "---------------------------------\n";

    $row = Sample->single('tinyurl',{id => 1});
    print Dumper $row;
    print "---------------------------------\n";

    my $count = Sample->count('tinyurl' => 'id');
    print $count, "\n";
    Sample->delete('tinyurl');
    $count = Sample->count('tinyurl' => 'id');
    print $count, "\n";
}

sub instance_method {
    my $model = Sample->new;
    my $row = $model->insert('tinyurl',{
        id  => 1,
        url => 'http://nekokak.org/',
    });

    print $row->get_column('url'), ':', $row->url, "\n";

    $model->bulk_insert('tinyurl',[
        {
            id  => 2,
            url => 'http://nekokak.org/blog.cgi',
        },
        {
            id  => 3,
            url => 'http://search.cpan.org/dist/DBIx-Skinny/',
        },
    ]);

    print "---------------------------------\n";
    my $itr = $model->search('tinyurl', {});
    while (my $row = $itr->next) {
        print $row->get_column('url'), ':', $row->url, "\n";
    }
    print "---------------------------------\n";

    $row = $model->single('tinyurl',{id => 1});
    print $row->get_column('url'), ':', $row->url, "\n";
    $row->set({url => 'http://d.hatena.ne.jp/nekokak/'});
    print $row->get_column('url'), ':', $row->url, "\n";
    $row->update;
    print "---------------------------------\n";

    $row = $model->single('tinyurl',{id => 1});
    print $row->get_column('url'), ':', $row->url, "\n";
    my $del_count = $row->delete;
    print $del_count, "\n";
    print "---------------------------------\n";

    $row = $model->single('tinyurl',{id => 1});
    print Dumper $row;
    print "---------------------------------\n";

    my $count = $model->count('tinyurl' => 'id');
    print $count, "\n";
    $model->delete('tinyurl');
    $count = $model->count('tinyurl' => 'id');
    print $count, "\n";
}

class_method();
print "=================================\n";
instance_method();


