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
# [*package*]
#  The name of the setuptools package to install, uses platform default.
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

    if $::osfamily == 'OpenBSD' {
      $easy_install = "/usr/local/bin/easy_install-${version}"
    } else {
      $easy_install = '/usr/bin/easy_install'
    }
  } elsif $ensure in ['installed', 'present'] {
    # If there's no package, then use ez_setup.py.
    if $::osfamily == 'windows' {
      $ez_setup_dir = inline_template(
        "<%= File.dirname(scope['python::interpreter']) %>"
      )
      $ez_setup = "${ez_setup_dir}\\ez_setup.py"
      $easy_install = "${python::scripts}\\easy_install.exe"
    } else {
      $ez_setup = '/usr/local/bin/ez_setup.py'
      $easy_install = '/usr/local/bin/easy_install'
    }

    file { $ez_setup:
      ensure  => file,
      owner   => $ez_setup_owner,
      group   => $ez_setup_group,
      mode    => $ez_setup_mode,
      content => template('python/ez_setup.py.erb'),
    }

    exec { 'setuptools-install':
      command => "${python::interpreter} ${ez_setup}",
      creates => $easy_install,
      require => File[$ez_setup],
    }
  }
}
