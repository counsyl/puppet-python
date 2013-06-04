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
# [*setuptools_ensure*]
#  The ensure value for the setuptools package, 'installed' by default.
#
# [*setuptools_package*]
#  The name of the setuptools package to install, uses platform default.
#
# [*pip_ensure*]
#  The ensure value for the pip package, 'installed' by default.
#
# [*pip_package*]
#  The name of the pip package to install, uses platform default.
#
# [*provider*]
#  The provider for the python/setuptools/pip packages, uses platform default.
#
# [*source*]
#  The source for the python/setuptools/pip packages, uses platform default.
#
class python (
  $ensure             = $python::params::ensure,
  $package            = $python::params::package,
  $setuptools_ensure  = 'installed',
  $setuptools_package = $python::params::setuptools,
  $pip_ensure         = 'installed',
  $pip_package        = $python::params::pip,
  $provider           = $python::params::provider,
  $source             = $python::params::source,
) inherits python::params {

  # Package for Python.
  package { $package:
    ensure   => $ensure,
    alias    => 'python',
    provider => $provider,
    source   => $source,
  }

  # Package for setuptools.
  package { $setuptools_package:
    ensure   => $setuptools_ensure,
    alias    => 'setuptools',
    provider => $provider,
    source   => $source,
    require  => Package[$package],
  }

  # Install the pip package if it exists, bootstrap with `easy_install`
  # otherwise.
  if $pip_package {
    package { $pip_package:
      ensure   => $pip_ensure,
      alias    => 'pip',
      provider => $provider,
      source   => $source,
      require  => Package[$setuptools_package],
    }

    # RedHat needs EPEL for pip package.
    if $::operatingsystem == 'RedHat' {
      include sys::redhat::epel
      Class['sys::redhat::epel'] -> Package[$pip_package]
    }
  } elsif $pip_ensure == 'installed' {
    exec { 'easy_install pip':
      path    => ['/usr/local/bin', '/usr/bin', '/bin'],
      unless  => 'which pip',
      require => Package[$setuptools_package],
    }
  }

  # OpenBSD needs some extra files to complete the experience.
  if $::operatingsystem == 'OpenBSD' {
    include python::openbsd
  }

  # This class must come before any package resources that specify specify `pip`
  # for its provider.
  Class['python'] -> Package<| provider == pip |>
}
