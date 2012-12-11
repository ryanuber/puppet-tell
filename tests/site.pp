#
# A few basic test cases following guidelines at
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
# I suppose negative testing does not belong here since all
# of these tests should succeed. Look to the 'negative'
# directory for negative tests.
#
tell {

    # Mail
    'test1':
        dest => 'nobody@example.com';

    'test2':
        dest => 'nobody@example.com',
        message => 'This is a test message.';

    'test3':
        dest => 'nobody@example.com',
        message => 'This is a test message.',
        from => 'someoneelse@example.com';

    'test4':
        dest => 'nobody@example.com',
        message => 'This is a test message.',
        from => 'someoneelse@example.com',
        subject => 'Test subject';

    'test5':
        dest => 'nobody@example.com',
        message => 'This is a test message.',
        from => 'someoneelse@example.com',
        subject => 'Test subject',
        refreshonly => true;

    'test6':
        dest => 'nobody@example.com',
        message => 'This is a test message.',
        from => 'someoneelse@example.com',
        subject => 'Test subject',
        refreshonly => false;

    # Webhooks
    'test7':
        dest => 'http://localhost';

    'test8':
        dest => 'http://localhost/';

    'test9':
        dest => 'http://localhost:8080/';

    'test10':
        dest => 'http://localhost?update=yes';

    'test11':
        dest => 'http://localhost',
        get => 'update',
        message => 'yes';

    'test12':
        dest => 'http://localhost',
        post => 'update',
        message => 'This is a test message.';

}
