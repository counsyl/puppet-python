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
# [*setuptools*]
#  The name of the setuptools package to install, uses platform default.
#
# [*provider*]
#  The provider for the python/setuptools packages, uses platform default.
#
# [*source*]
#  The source for the python/setuptools packages, uses platform default.
#
class python (
  $ensure     = $python::params::ensure,
  $package    = $python::params::package,
  $setuptools = $python::params::setuptools,
  $provider   = $python::params::provider,
  $source     = $python::params::source,
) inherits python::params {

  package { $package:
    ensure   => $ensure,
    alias    => 'python',
    provider => $provider,
    source   => $source,
  }

  package { $setuptools:
    ensure   => installed,
    alias    => 'setuptools',
    provider => $provider,
    source   => $source,
    require  => Package['python'],
  }

  # Use setuptools to bootstrap pip.
  exec { 'easy_install pip':
    path    => ['/usr/local/bin', '/usr/bin', '/bin'],
    unless  => 'which pip',
    require => Package['setuptools'],
  }

  # Use pip to install virtualenv.
  package { 'virtualenv':
    ensure   => installed,
    provider => 'pip',
    require  => Exec['easy_install pip'],
  }

  # OpenBSD needs some extra files to complete the experience.
  if $::operatingsystem == OpenBSD {
    include python::openbsd
  }

  # All `pip` packages require `pip` to be installed.
  Class['python'] -> Package<| provider == pip |>
}
