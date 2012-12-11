#
# This tests the refreshonly feature when set to true. It should
# result in nothing being executed, since nothing refreshes it.
#
tell { 'refreshonly_norefresh':
    dest => 'nobody@example.com',
    refreshonly => true;
}
