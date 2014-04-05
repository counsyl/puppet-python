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
  $ensure       = 'installed',
  $package      = $python::params::pip,
  $provider     = $python::params::provider,
  $source       = $python::params::source,
) inherits python::params {
  if $package {
    if $::osfamily == 'RedHat' {
      # RedHat needs EPEL for pip package.
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
    if $::osfamily == 'windows' {
      $pip_script = "${python::scripts}\\pip.exe"
    } else {
      $pip_script = "${python::scripts}/pip"
    }

    exec { 'pip-install':
      command => "${python::setuptools::easy_install} pip",
      creates => $pip_script,
    }
  }
}
