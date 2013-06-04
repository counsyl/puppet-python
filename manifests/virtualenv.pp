# == Class: python::virtualenv
#
# Installs the virtualenv package for Python.
#
# === Parameters
#
# [*ensure*]
#  The ensure value for the virtualenv package resource, defaults to
#  'installed'.
#
# [*package*]
#  The virtualenv package to install, default is platform dependent
#  (e.g., 'python-virtualenv' on Debian and RedHat).
#
# [*provider*]
#  The provider to use for the virtualenv package resource, default
#  is platform dependent.
#
class python::virtualenv(
  $ensure   = 'installed',
  $package  = $python::params::virtualenv,
  $provider = $python::params::provider,
) inherits python::params {
  package { $package:
    ensure   => $ensure,
    alias    => 'virtualenv',
    provider => $provider,
    require  => Class['python'],
  }
}
