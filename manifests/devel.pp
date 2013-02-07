# == Class: python::devel
#
# Installs the Python development headers and compiler -- makes it possible
# to compile modules with C extensions.
#
# === Parameters
#
# [*package*]
#  The name of the Python development header package, defaults to what's
#  used on the platform (if any).
#
class python::devel(
  $package = $python::params::devel,
) inherits python::params {
  if $package {
    if $::operatingsystem == Solaris {
      include sys::solaris::sunstudio
      $python_compiler = 'sys::solaris::sunstudio'
    } else {
      include sys::gcc
      $python_compiler = 'sys::gcc'
    }

    package { $package:
      ensure  => installed,
      alias   => 'python-devel',
      require => Class[$python_compiler],
    }
  }
}
