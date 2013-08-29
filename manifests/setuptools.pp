# == Class: python:setuptools
#
# Installs setuptools, which can download, build, install, upgrade, and
# uninstall Python packages.
#
# === Parameters
#
# [*ensure*]
#  The ensure value for the setuptools package, 'installed' by default.
#
# [*package*]
#  The name of the setuptools package to install, uses platform default.
#
# [*provider*]
#  The provider for the setuptools package, uses platform default.
#
# [*source*]
#  The source for the setuptools package, uses platform default.
#
class python::setuptools(
  $ensure = 'installed',
  $package  = $python::params::setuptools,
  $provider = $python::params::provider,
  $source   = $python::params::source,
) inherits python::params {

  package { $package:
    ensure   => $ensure,
    alias    => 'setuptools',
    provider => $provider,
    source   => $source,
  }

  if $::operatingsystem == 'OpenBSD' {
    case $ensure {
      'installed', 'present': {
        file { '/usr/local/bin/easy_install':
          ensure  => link,
          target  => "/usr/local/bin/easy_install-${version}",
          owner   => 'root',
          group   => 'wheel',
          require => Package['setuptools'],
        }
      }
      'uninstalled', 'absent': {
        file { '/usr/local/bin/easy_install':
          ensure => absent,
        }
      }
    }
  }
}
