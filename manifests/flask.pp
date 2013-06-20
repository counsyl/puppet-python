# == Class: python::flask
#
# Installs Flask, a Python web framework.
#
# === Parameters
#
# [*package*]
#  The package name to install, defaults to 'Flask'.
#
# [*version*]
#  The package version to install (via package ensure parameter).
#  Defaults to 'installed'.
#
# [*provider*]
#  Package provider to use.  Defaults to 'pip'.
#
class python::flask(
  $package  = 'Flask',
  $version  = 'installed',
  $provider = 'pip',
) {
  package { $package:
    ensure   => $version,
    alias    => 'flask',
    provider => $provider,
    require  => Class['python'],
  }
}
