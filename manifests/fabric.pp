# == Class: python::fabric
#
# Installs Fabric, the Python command-line tool for SSH interaction.
#
# === Parameters
#
# [*package*]
#  The package name to install, defaults to 'Fabric'.
#
# [*version*]
#  The package version to install (via package ensure parameter).
#  Defaults to 'installed'.
#
# [*provider*]
#  Package provider to use.  Defaults to 'pip'.
#
class python::fabric(
  $package  = 'Fabric',
  $version  = 'installed',
  $provider = 'pip',
) {
  package { $package:
    ensure   => $version,
    alias    => 'fabric',
    provider => $provider,
    require  => Class['python'],
  }
}
