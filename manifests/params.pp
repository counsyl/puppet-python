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
      $interpreter   = "/usr/local/bin/python${version}"
      $site_packages = "/usr/local/lib/python${version}/site-packages"
    }
    solaris: {
      include sys::solaris
      $ensure        = 'installed'
      $version       = '2.6'
      $package       = 'runtime/python-26'
      $provider      = 'pkg'
      $setuptools    = 'library/python-2/setuptools-26'
      $interpreter   = '/usr/bin/python'
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
      $interpreter   = '/usr/bin/python'

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
      $interpreter   = '/usr/bin/python'
      $site_packages = "/usr/lib/python${version}/site-packages"
    }
    windows: {
      $ensure        = 'installed'
      $version       = '2.7'
      $full_version  = '2.7.7'
      # Other parameters, like $package, $interpreter, and $site_packages
      # are set by `python::windows`.
    }
    default: {
      fail("Do not know how to install/configure Python on ${::osfamily}.\n")
    }
  }

  # Parameters for when using ez_setup.py.
  $ez_version = '4.0.1'
  $ez_base_url = 'https://pypi.python.org/packages/source/s/setuptools/'
  if $::osfamily != 'windows' {
    include sys
    $ez_setup_owner = 'root'
    $ez_setup_group = $sys::root_group
    $ez_setup_mode = '0644'
  }
}
