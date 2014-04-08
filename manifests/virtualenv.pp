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
  if $package {
    package { $package:
      ensure   => $ensure,
      provider => $provider,
      require  => Class['python'],
    }
  } elsif $ensure in ['installed', 'present'] {
    package { 'virtualenv':
      ensure   => $ensure,
      provider => 'pip',
      require  => Class['python'],
    }
  }

  # Ensure this class is a requirement for the venv/venv_package types.
  Class['python::virtualenv'] -> Venv<| |>
  Class['python::virtualenv'] -> Venv_package<| |>
}
