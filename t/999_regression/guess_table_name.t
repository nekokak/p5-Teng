use t::Utils;
use Mock::Basic;
use Test::More;

subtest 'do _guess_table_name' => sub {
    is +Mock::Basic->_guess_table_name(q{SELECT * FROM hoo, bar  WHERE name = 'nekokak'}), 'hoo';

    is +Mock::Basic->_guess_table_name(q{
        SELECT * FROM hoo, bar  WHERE name = 'nekokak'
    }), 'hoo';
    is +Mock::Basic->_guess_table_name(q{SELECT mail_from
        FROM hoo, bar  WHERE name = 'nekokak'}), 'hoo';
    is +Mock::Basic->_guess_table_name(q{SELECT mail_from
        FROM
        hoo, bar  WHERE name = 'nekokak'}), 'hoo';
    is +Mock::Basic->_guess_table_name(q{SELECT mail_from
        FROM hoo, bar  WHERE mail_from is null}), 'hoo';

    done_testing;
};

done_testing;

