# == Class: python::openbsd
#
# Creates symbolic links for a better experience on OpenBSD.
#
class python::openbsd(
  $ez_setup,
) inherits python::params {
  file { '/usr/local/bin/python':
    ensure  => link,
    target  => $interpreter,
    owner   => 'root',
    group   => 'wheel',
  }

  file { '/usr/local/bin/python-config':
    ensure  => link,
    target  => "/usr/local/bin/python${version}-config",
    owner   => 'root',
    group   => 'wheel',
  }

  file { '/usr/local/bin/pydoc':
    ensure  => link,
    target  => "/usr/local/bin/pydoc${version}",
    owner   => 'root',
    group   => 'wheel',
  }

  if ! $ez_setup {
    file { '/usr/local/bin/easy_install':
      ensure  => link,
      target  => "/usr/local/bin/easy_install-${version}",
      owner   => 'root',
      group   => 'wheel',
    }

    file { '/usr/local/bin/pip':
      ensure  => link,
      target  => "/usr/local/bin/pip-${version}",
      owner   => 'root',
      group   => 'wheel',
    }
  }
}
