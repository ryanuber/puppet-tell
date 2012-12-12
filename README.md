puppet-tell
===========

Tell external parties about changes to resources.

Sometimes it's quite handy to be able to know when things on
your systems change, in real-time. A good example is upgrading
your Linux system kernel. Typically you don't want puppet to
blindly reboot your machine to get the new kernel running, but
you do want to know that the system has a kernel update
installed, and waiting to be rebooted to.

Depending on your implementation and how your organization works,
you will have different requirements on how to handle these
types of events. If you are managing some test systems, or some
development systems, or just a local sandbox of machines, maybe
you want them to automatically restart themselves. In contrast,
maybe you are managing production systems, and you want just a
notification of your resource change event.

How it works
------------

This module currently provides two ways of externalizing puppet
resource changes:

* By email
* Using a web hook (way more interesting)

It will expose any resource change by sending the resource data
to the external party. The resource data is simply the pson data
directly from the changed resource, encoded in a format specified
by the user. This is collected by looking it up in the
relationship graph from the running catalog.

This module follows almost the same logic as the 'exec' resource
type utilizing 'refreshonly'. It is implemented slightly different,
where 'false' is the default value (since this module isn't very
useful if you are just triggering it from Class[main] all the time).
You can still specify refreshonly => false, even though there
probably isn't a valid use case for it, at least not yet...

Web hooks
---------

While using web hooks, the default behavior is to simply make a GET
request to the URL you specify in the 'dest' parameter with no
request parameters. If you specify one of 'get' or 'post', a
respective query will be sent to the url specified by 'dest', and
additionally, the resource that triggered the tell resource will be
encoded and sent by the parameter name specified. See below for a
better explanation.

Example
-------

In this example, the vim-enhanced package changes to 'latest'
from 'absent'. The example results would be POST'ed to a web service
via HTTP if you are using a web hook, or an email would have been
sent through the default system relay if you are 'telling' an email
address about the resource change.

Puppet DSL:

    Package {
        notify => [
            Tell['package_updated_email'],
            Tell['package_updated_webhook']
        ]
    }

    package { "vim-enhanced": ensure => "latest" }

    tell {
        'package_updated_email':
            dest => 'myself@mydomain.com';

        'package_updated_webhook':
            dest => 'http://rest.example.com/v1/package-update-notifications',
            post => 'packagedata';
    }

When you run it, you will see something like this:

    /Stage[main]//Package[vim-enhanced]/ensure: created
    /Stage[main]//Tell[package_updated_webhook]: Triggered 'refresh' from 1 events
    /Stage[main]//Tell[package_updated_email]/returns: Successfully told myself@mydomain.com
    /Stage[main]//Tell[package_updated_email]: Triggered 'refresh' from 1 events
    Finished catalog run in 8.26 seconds

Results in the default YAML format:

    ---
      - exported: false
        title: vim-enhanced
        parameters:
          !ruby/sym configfiles: !ruby/sym keep
          !ruby/sym ensure: "7.2.411-1.8.el6"
          !ruby/sym provider: !ruby/sym yum
          !ruby/sym loglevel: !ruby/sym notice
          !ruby/sym notify:
            - Tell[package_updated]
        type: Package
        tags:
          - package
          - vim-enhanced
          - class
      - exported: false
        title: Main
        parameters:
          !ruby/sym name: admissible_Class[Main]
          !ruby/sym loglevel: !ruby/sym notice
        type: Admissible_class
        tags:
          - admissible_class
          - main

Results in JSON format (requires 'json' rubygem)

    [
      {
        "title": "vim-enhanced",
        "type": "Package",
        "parameters": {
          "ensure": "7.2.411-1.8.el6",
          "configfiles": "keep",
          "provider": "yum",
          "loglevel": "notice",
          "notify": [
            "Tell[package_updated]"
          ]
        },
        "exported": false,
        "tags": [
          "package",
          "vim-enhanced",
          "class"
        ]
      },
      {
        "title": "Main",
        "type": "Admissible_class",
        "parameters": {
          "name": "admissible_Class[Main]",
          "loglevel": "notice"
        },
        "exported": false,
        "tags": [
          "admissible_class",
          "main"
        ]
      }
    ]

In the near future
------------------

* Further extending webhooks support to support remaining HTTP methods and HTTPS
* SNMP support?
