# == Class: python
#
# Installs the Python language runtime.  Defaults to the most stable version
# for the platform, preferring version 2 (no 3 support at this time).
#
# === Parameters
#
# [*ensure*]
#  The ensure value for the Python package, uses the default for the platform
#  (typically this is just 'installed' unless running on OpenBSD).
#
# [*package*]
#  The name of the Python package to install, uses platform default.
#
# [*provider*]
#  The provider for the Python package, uses platform default.
#
# [*source*]
#  The source for the Python package, uses platform default.
#
class python (
  $ensure  = $python::params::ensure,
  $package = $python::params::package,
  $provide = $python::params::provider,
  $source  = $python::params::source,
) inherits python::params {

  # Package for Python.
  package { $package:
    ensure   => $ensure,
    alias    => 'python',
    provider => $provider,
    source   => $source,
  }

  # Include setuptools and pip for packaging.  Ensure relationships are
  # setup between the Python package and the setuptools/pip classes.
  include python::setuptools
  include python::pip
  Package['python'] -> Class['python::setuptools'] -> Class['python::pip']

  # OpenBSD needs some extra links to complete the experience.
  if $::operatingsystem == 'OpenBSD' {
    case $ensure {
      'uninstalled', 'absent': {
        file { ['/usr/local/bin/python', '/usr/local/bin/python-config',
                '/usr/local/bin/pydoc']:
          ensure => absent,
        }
      }
      default: {
        file { '/usr/local/bin/python':
          ensure  => link,
          target  => "/usr/local/bin/python${version}",
          owner   => 'root',
          group   => 'wheel',
          require => Package['python'],
        }

        file { '/usr/local/bin/python-config':
          ensure  => link,
          target  => "/usr/local/bin/python${version}-config",
          owner   => 'root',
          group   => 'wheel',
          require => Package['python'],
        }

        file { '/usr/local/bin/pydoc':
          ensure  => link,
          target  => "/usr/local/bin/pydoc${version}",
          owner   => 'root',
          group   => 'wheel',
          require => Package['python'],
        }
      }
    }
  }

  # Ensure this class comes before any package resources with a `pip` or `pipx`
  # provider, as well as any `venv` resources.
  Class['python'] -> Package<| provider == pip |>
  Class['python'] -> Package<| provider == pipx |>
  Class['python'] -> Venv<| |>
}
