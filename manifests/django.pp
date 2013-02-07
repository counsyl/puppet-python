# == Class: python::django
#
# Installs Django, the popular Python web framework.
#
# === Parameters
#
# [*package*]
#  The package name to install, defaults to 'Django'.
#
# [*version*]
#  The package version to install (via package ensure parameter).
#  Defaults to 'installed'.
#
# [*provider*]
#  Package provider to use.  Defaults to 'pip'.
#
class python::django(
  $package  = 'Django',
  $version  = 'installed',
  $provider = 'pip',
) {
  package { $package:
    ensure   => $version,
    alias    => 'django',
    provider => $provider,
    require  => Class['python'],
  }
}
