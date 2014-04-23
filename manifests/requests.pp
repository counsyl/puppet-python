# == Class: python::requests
#
# Installs requests, the popular Python HTTP library.
#
# === Parameters
#
# [*package*]
#  The package name to install, defaults to 'requests'.
#
# [*version*]
#  The package version to install (via package ensure parameter), defaults
#  to 'installed'.
#
# [*provider*]
#  Package provider to use.  Defaults to 'pip'.
#
class python::requests(
  $package  = 'requests',
  $version  = 'installed',
  $provider = 'pip',
) {
  package { $package:
    ensure   => $version,
    provider => $provider,
    require  => Class['python'],
  }
}
