# == Class: cloudera::cm
#
# This class handles installing and configuring the Cloudera Manager Agent.
#
# === Parameters:
#
# [*ensure*]
#   Ensure if present or absent.
#   Default: present
#
# [*autoupgrade*]
#   Upgrade package automatically, if there is a newer version.
#   Default: false
#
# [*service_ensure*]
#   Ensure if service is running or stopped.
#   Default: running
#
# [*server_host*]
#   Hostname of the Cloudera Manager server.
#   Default: localhost
#
# [*server_port*]
#   Port to which the Cloudera Manager server is listening.
#   Default: 7182
#
# === Actions:
#
# Installs the packages.
# Configures the server connection.
# Starts the service.
#
# === Requires:
#
#   Package['jdk']
#
# === Sample Usage:
#
#   class { 'cloudera::cm':
#     server_host => 'smhost.example.com',
#   }
#
# === Authors:
#
# Mike Arnold <mike@razorsedge.org>
#
# === Copyright:
#
# Copyright (C) 2013 Mike Arnold, unless otherwise noted.
#
class cloudera::cm (
  $ensure         = $cloudera::params::ensure,
  $autoupgrade    = $cloudera::params::safe_autoupgrade,
  $service_ensure = $cloudera::params::service_ensure,
  $server_host    = $cloudera::params::cm_server_host,
  $server_port    = $cloudera::params::cm_server_port
) inherits cloudera::params {
  # Validate our booleans
  validate_bool($autoupgrade)

  case $ensure {
    /(present)/: {
      if $autoupgrade == true {
        $package_ensure = 'latest'
      } else {
        $package_ensure = 'present'
      }

      if $service_ensure in [ running, stopped ] {
        $service_ensure_real = $service_ensure
        $service_enable = true
      } else {
        fail('service_ensure parameter must be running or stopped')
      }
      $file_ensure = 'present'
    }
    /(absent)/: {
      $package_ensure = 'absent'
      $service_ensure_real = 'stopped'
      $service_enable = false
      $file_ensure = 'absent'
    }
    default: {
      fail('ensure parameter must be present or absent')
    }
  }

  package { 'cloudera-manager-agent':
    ensure => $package_ensure,
  }

  package { 'cloudera-manager-daemons':
    ensure => $package_ensure,
  }

  file { 'scm-config.ini':
    ensure  => $file_ensure,
    path    => '/etc/cloudera-scm-agent/config.ini',
    content => template('cloudera/scm-config.ini.erb'),
    require => Package['cloudera-manager-agent'],
    notify  => Service['cloudera-scm-agent'],
  }

  service { 'cloudera-scm-agent':
    ensure     => $service_ensure_real,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['cloudera-manager-agent'],
  }
}
