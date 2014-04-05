# == Class: python::pip
#
# Installs pip, the tool for installing and managing Python packages.
#
# === Parameters
#
# [*ensure*]
#  The ensure value for the pip package, 'installed' by default.
#
# [*package*]
#  The name of the pip package to install, uses platform default.
#
# [*provider*]
#  The provider for the pip package, uses platform default.
#
# [*source*]
#  The source for the pip package, uses platform default.
#
class python::pip(
  $ensure   = 'installed',
  $package  = $python::params::pip,
  $provider = $python::params::provider,
  $source   = $python::params::source,
) inherits python::params {
  if $package {
    # RedHat needs EPEL for pip package.
    if $::operatingsystem == 'RedHat' {
      include sys::redhat::epel
      Class['sys::redhat::epel'] -> Package[$package]
    }

    package { $package:
      ensure   => $ensure,
      provider => $provider,
      source   => $source,
      require  => Package[$setuptools],
    }
  } elsif $ensure in ['installed', 'present'] {
    # Use setuptools to bootstrap pip if we aren't using a package.
    exec { "easy_install pip":
      path    => ['/usr/local/bin', '/usr/bin', '/bin'],
      unless  => 'which pip',
      require => Package[$package],
    }
  }
}
