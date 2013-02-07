# == Class: python::ipython
#
# Installs the IPython shell.
#
# === Parameters
#
# [*package*]
#  The package name to install, defaults to 'ipython'.
#
# [*version*]
#  The package version to install, defaults to 'installed'.
#
# [*provider*]
#  Package provider to use, defaults to 'pip'.
#
class python::ipython(
  $package  = 'ipython',
  $version  = 'installed',
  $provider = 'pip',
) {
  package { $package:
    ensure   => $version,
    provider => $provider,
    require  => Class['python'],
  }
}
