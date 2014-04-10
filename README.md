python
======

This Puppet module installs the Python language runtime, and provides classes
for common Python packages and tools.  In addition, an improved pip package
provider ([`pipx`](#pipx)) is included as well as custom types for Python
virtual environments ([`venv`](#venv)) and packages inside virtual environments
([`venv_package`](#venv_package)).


By default, including the `python` class installs Python, setuptools, and pip;
the `python::virtualenv` class installs virtualenv.  Thus, to have Python, pip,
and virtualenv installed on your system simply place the following in your
Puppet manifest:

```puppet
include python
include python::virtualenv
```

`pipx`
------

The `pipx` package provider is an enhanced version of Puppet's own
[`pip`](http://docs.puppetlabs.com/references/latest/type.html#package-provider-pip)
provider.  It includes such enhancements as:

* Implements the [`install_options`](http://docs.puppetlabs.com/references/latest/type.html#package-attribute-install-options) feature
* Improvements for installing packages from version control
* Uses HTTPS to query PyPI when setting [`ensure`](http://docs.puppetlabs.com/references/latest/type.html#package-attribute-ensure) to 'latest'

For example, assuming you had an internal PyPI mirror at
`https://pypi.mycorp.com`, you could install the `requests` package system-wide
from your mirror using the following:

```puppet
package { 'requests':
  ensure          => installed,
  provider        => 'pipx',
  install_options => [
    { '--index-url' => 'https://pypi.mycorp.com' },
  ],
}
```

`venv`
------

The `venv` type enables the management of Python virtual environments with Puppet.

`venv_package`
--------------

This type installs packages in a Python virtual environment.

Windows
-------

Windows support requires the [`counsyl-windows`](https://github.com/counsyl/puppet-windows)
module.  Because `%Path%` updates aren't reflected in Puppet's current session, you
will see errors about not being able to find the `pip` and/or `virtualenv` commands --
running Puppet again should make these errors go away on a fresh system.  In addition,
due to the nature of Windows platforms, customizations should be done on 
the `python::windows` class before including `python`.  For example, to force
the use the 32-bit version of Python 2.6.6 you would:

```puppet
class { 'python::windows':
  arch    => 'i386',
  version => '2.6.6',
}
include python
```

License
-------

Apache License, Version 2.0

Contact
-------

Justin Bronn <justin@counsyl.com>

Support
-------

Please log tickets and issues at https://github.com/counsyl/puppet-python
