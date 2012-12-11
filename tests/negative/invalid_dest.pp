#
# This tests catching invalid destinations for the 'tell' type.
# It should fail to apply. If the apply fails, the test should succeed.
#
tell { 'invalid_dest':
    dest => '****';
}
