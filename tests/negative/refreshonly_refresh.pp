#
# This tests the refreshonly feature when set to true. It should
# result in the Tell['refreshonly_refresh'] resource being triggered.
#
exec { '/bin/true':
    notify => Tell['refreshonly_refresh'],
    refreshonly => false;
}

tell { 'refreshonly_refresh':
    dest => 'nobody@example.com',
    refreshonly => true;
}
