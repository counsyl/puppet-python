# == Resource: python::pip_conf
#
# Template for defining a standard pip configuration for a user. This sets up
# index URLS and caching directives for downloaded packages and wheels.
#
# === Parameters
#
# [*user*]
#  The user to install the configuration file for. Defaults to the name of the
#  resource.
#
# [*conf_dir*]
#  Directory to place the pip configuration file in. Defaults to the `.pip` dir
#  in the user's home directory.
#
# [*cache_dir*]
#  Directory to place pip cache directories in. Defaults to the same value as
#  `conf_dir`.
#
# [*index_url*]
#  Location of the primary PyPi index to use.
#
# [*extra_index_url*]
#  Location of an extra fallback PyPi index to use.
#
define python::pip_conf(
  $user            = $name,
  $conf_dir        = "/home/${user}/.pip",
  $cache_dir       = $conf_dir,
  $index_url       = undef,
  $extra_index_url = undef,
) {
  $download_cache = "${cache_dir}/downloads"
  $wheel_cache    = "${cache_dir}/wheels"

  $pip_dirs = [$conf_dir, $cache_dir, $download_cache, $wheel_cache]
  file { $pip_dirs:
    ensure => directory,
    owner  => $user,
    mode   => '0644',
  }

  $pip_config = "${conf_dir}/pip.conf"
  file { $pip_config:
    ensure  => file,
    owner   => $user,
    mode    => '0644',
    content => template('python/pip.conf.erb'),
    require => File[$pip_dirs],
  }
}
