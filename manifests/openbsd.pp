# == Class: python::openbsd
#
# Creates symbolic links for a better experience on OpenBSD.
#
class python::openbsd(
  $ensure,
) inherits python::params {
  case $ensure {
    'uninstalled', 'absent': {
      file { ['/usr/local/bin/python', '/usr/local/bin/python-config',
              '/usr/local/bin/pydoc', '/usr/local/bin/easy_install',
              '/usr/local/bin/pip']:
                ensure => absent,
      }
    }
    default: {
      file { '/usr/local/bin/python':
        ensure  => link,
        target  => $interpreter,
        owner   => 'root',
        group   => 'wheel',
        require => Package[$package],
      }

      file { '/usr/local/bin/python-config':
        ensure  => link,
        target  => "/usr/local/bin/python${version}-config",
        owner   => 'root',
        group   => 'wheel',
        require => Package[$package],
      }

      file { '/usr/local/bin/pydoc':
        ensure  => link,
        target  => "/usr/local/bin/pydoc${version}",
        owner   => 'root',
        group   => 'wheel',
        require => Package[$package],
      }

      file { '/usr/local/bin/easy_install':
        ensure  => link,
        target  => "/usr/local/bin/easy_install-${version}",
        owner   => 'root',
        group   => 'wheel',
        require => Package[$setuptools],
      }

      file { '/usr/local/bin/pip':
        ensure  => link,
        target  => "/usr/local/bin/pip-${version}",
        owner   => 'root',
        group   => 'wheel',
        require => Package[$pip],
      }
    }
  }
}
