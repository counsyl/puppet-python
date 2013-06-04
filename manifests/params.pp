# == Class: python
#
# Platform-dependent parameters for Python.
#
class python::params {
  case $::osfamily {
    openbsd: {
      include sys::openbsd::pkg
      $version       = '2.7'
      $ensure        = $sys::openbsd::pkg::python
      $source        = $sys::openbsd::pkg::source
      $package       = 'python'
      $setuptools    = 'py-setuptools'
      $pip           = 'py-pip'
      $virtualenv    = 'py-virtualenv'
      $site_packages = "/usr/local/lib/python${version}/site-packages"
    }
    solaris: {
      include sys::solaris
      $ensure        = 'installed'
      $version       = '2.6'
      $package       = 'runtime/python-26'
      $provider      = 'pkg'
      $setuptools    = 'library/python-2/setuptools-26'
      $site_packages = "/usr/lib/python${version}/site-packages"
    }
    debian: {
      if $::operatingsystem == 'Ubuntu' {
        $lsb_compare = '10'
      } else {
        $lsb_compare = '6'
      }

      if versioncmp($::lsbmajdistrelease, $lsb_compare) > 0 {
        $version = '2.7'
      } else {
        $version = '2.6'
      }

      $ensure        = 'installed'
      $package       = 'python'
      $setuptools    = 'python-setuptools'
      $devel         = 'python-dev'
      $pip           = 'python-pip'
      $virtualenv    = 'python-virtualenv'

      # Ubuntu is special -- `site-packages` is renamed to `dist-packages`;
      # and apt's packages install in /usr/lib whereas pip packages go
      # into /usr/local/lib.
      $dist_packages = "/usr/lib/python${version}/dist-packages"
      $site_packages = "/usr/local/lib/python${version}/dist-packages"
    }
    redhat: {
      $ensure        = 'installed'
      $version       = '2.6'
      $package       = 'python'
      $setuptools    = 'python-setuptools'
      $devel         = 'python-devel'
      $pip           = 'python-pip'
      $virtualenv    = 'python-virtualenv'
      $site_packages = "/usr/lib/python${version}/site-packages"
    }
    default: {
      fail("Do not know how to install/configure Python on ${::osfamily}.\n")
    }
  }
}
