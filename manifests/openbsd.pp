# == Class: python::openbsd
#
# Provides extra configuration for Python necessary on OpenBSD.
#
class python::openbsd {
  # OpenBSD leaves out nice things like symbolic links.
  file { '/usr/local/bin/python':
    ensure  => link,
    target  => "/usr/local/bin/python${python::params::version}",
    owner   => 'root',
    group   => 'wheel',
    require => Package['python'],
  }

  file { '/usr/local/bin/python-config':
    ensure  => link,
    target  => "/usr/local/bin/python${python::params::version}-config",
    owner   => 'root',
    group   => 'wheel',
    require => Package['python'],
  }

  file { '/usr/local/bin/pydoc':
    ensure  => link,
    target  => "/usr/local/bin/pydoc${python::params::version}",
    owner   => 'root',
    group   => 'wheel',
    require => Package['python'],
  }

  file { '/usr/local/bin/easy_install':
    ensure  => link,
    target  => "/usr/local/bin/easy_install-${python::params::version}",
    owner   => 'root',
    group   => 'wheel',
    require => Package['setuptools'],
    before  => Exec['easy_install pip'],
  }
}
