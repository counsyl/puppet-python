# == Class: python
#
# Platform-dependent parameters for Python.
#
class python::params {
  case $::osfamily {
    openbsd: {
      include openbsd::pkg
      if versioncmp($::kernelmajversion, '5.0') >= 0 {
        $version = '2.7'
      } else {
        $version = '2.6'
      }
      $ensure     = $openbsd::pkg::python
      $source     = $openbsd::pkg::source
      $package    = 'python'
      $setuptools = 'py-setuptools'
    }
    solaris: {
      include sys::solaris
      $package    = 'runtime/python-26'
      $provider   = 'pkg'
      $setuptools = 'library/python-2/setuptools-26'
    }
    debian: {
      $package    = 'python'
      $setuptools = 'python-setuptools'
      $devel      = 'python-dev'
    }
    redhat: {
      $package    = 'python'
      $setuptools = 'python-setuptools'
      $devel      = 'python-devel'
    }
    default: {
      fail("Do not know how to install/configure Python on ${::osfamily}.\n")
    }
  }

  # On OpenBSD, have to have `ensure` set so the correct
  # Python version is installed.
  if $::osfamily != OpenBSD {
    $ensure = 'installed'
  }
}
