# == Class: python::virtualenv
#
# Installs the virtualenv package for Python.
#
class python::virtualenv(
  $package  = 'virtualenv',
  $version  = 'installed',
  $provider = 'pip',
){
  package { $package:
    ensure   => $version,
    provider => $provider,
    require  => Class['python'],
  }
}
