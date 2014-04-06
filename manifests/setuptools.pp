# == Class: python:setuptools
#
# Installs setuptools, which can download, build, install, upgrade, and
# uninstall Python packages.
#
# === Parameters
#
# [*ensure*]
#  The ensure value for the setuptools package, 'installed' by default.
#
# [*ez_base_url*]
#  The base url to download the setuptools package from when using
#  `ez_setup.py`.  Defaults to:
#    'https://pypi.python.org/packages/source/s/setuptools/'
#
# [*ez_version*]
#  The version of setuptools to install with `ez_setup.py`, defaults to
#  '3.4.1'
#
# [*package*]
#  The name of the setuptools package to install, uses platform default.
#  If not set, then `ez_setup.py` will be used to install setuptools.
#
# [*provider*]
#  The provider for the setuptools package, uses platform default.
#
# [*source*]
#  The source for the setuptools package, uses platform default.
#
class python::setuptools(
  $ensure      = 'installed',
  $ez_base_url = $python::params::ez_base_url,
  $ez_version  = $python::params::ez_version,
  $package     = $python::params::setuptools,
  $provider    = $python::params::provider,
  $source      = $python::params::source,
) inherits python::params {
  if $package {
    package { $package:
      ensure   => $ensure,
      provider => $provider,
      source   => $source,
    }

    # Set up path to easy_install, in case there's no `pip` package
    # specified.
    if $::osfamily == 'OpenBSD' {
      $easy_install = "/usr/local/bin/easy_install-${version}"
    } else {
      $easy_install = '/usr/bin/easy_install'
    }
  } elsif $ensure in ['installed', 'present'] {
    # When there's no package, then use ez_setup.py.
    if $::osfamily == 'windows' {
      $ez_setup = "${python::scripts}\\ez_setup.py"
      $easy_install = "${python::scripts}\\easy_install.exe"
    } else {
      $ez_setup = "${python::scripts}/ez_setup.py"
      $easy_install = "${python::scripts}/easy_install"
    }

    # Create the `ez_setup.py` from template (which allows customization of
    # the setuptools verion and URL to download from).  The owner, group, and
    # mode of this file are inherited from python::params (and left undefined
    # on Windows).
    file { $ez_setup:
      ensure  => file,
      owner   => $ez_setup_owner,
      group   => $ez_setup_group,
      mode    => $ez_setup_mode,
      content => template('python/ez_setup.py.erb'),
    }

    # Install setuptools by running ez_setup.py.
    exec { 'setuptools-install':
      command => "${python::interpreter} ${ez_setup}",
      creates => $easy_install,
      require => File[$ez_setup],
    }
  }
}
