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
    package { $package:
      ensure   => $ensure,
      alias    => 'pip',
      provider => $provider,
      source   => $source,
      require  => Package['setuptools'],
    }

    # RedHat needs EPEL for pip package.
    if $::operatingsystem == 'RedHat' {
      include sys::redhat::epel
      Class['sys::redhat::epel'] -> Package['pip']
    }

    # OpenBSD link.
    if $::operatingsystem == 'OpenBSD' {
      case $ensure {
        'installed', 'present': {
          file { '/usr/local/bin/pip':
            ensure  => link,
            target  => "/usr/local/bin/pip-${version}",
            owner   => 'root',
            group   => 'wheel',
            require => Package['pip'],
          }
        }
        'uninstalled', 'absent': {
          file { '/usr/local/bin/pip':
            ensure => absent,
          }
        }
      }
    }
  } elsif $ensure in ['installed', 'present'] {
    # Use setuptools to bootstrap pip if we aren't using a package.
    exec { 'easy_install pip':
      path    => ['/usr/local/bin', '/usr/bin', '/bin'],
      unless  => 'which pip',
      require => Package['setuptools'],
    }
  }
}
