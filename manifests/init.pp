#####################################################
# docker_base class
#####################################################

class docker_base {

  #####################################################
  # create groups and users
  #####################################################
  $user = 'ops'
  $group = 'ops'
  $docker_group = 'docker'

  group { $group:
    ensure     => present,
  }

  user { $user:
    ensure     => present,
    gid        => $group,
    groups     => [ $docker_group ],
    shell      => '/bin/bash',
    home       => "/home/$user",
    managehome => true,
    require    => [
                   Group[$group],
                   Package["docker-ce"],
                  ],
  }


  file { "/home/$user":
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    require => User[$user],
  }


  file { "/etc/sudoers.d/90-cloudimg-$user":
    ensure  => file,
    content  => template('docker_base/90-cloudimg-user'),
    mode    => 0440,
    require => [
                User[$user],
               ],
  }


  #####################################################
  # add .inputrc to users' home
  #####################################################

  inputrc { 'root':
    home => '/root',
  }
  
  inputrc { $user:
    home    => "/home/$user",
    require => User[$user],
  }


  #####################################################
  # change default user
  #####################################################

  file_line { "default_user":
    ensure  => present,
    line    => "    name: $user",
    path    => "/etc/cloud/cloud.cfg",
    match   => "^    name:",
    require => User[$user],
  }


  #####################################################
  # install .bashrc
  #####################################################

  file { "/home/$user/.bashrc":
    ensure  => present,
    content => template('docker_base/bashrc'),
    owner   => $user,
    group   => $group,
    mode    => 0644,
    require => User[$user],
  }


  file { "/root/.bashrc":
    ensure  => present,
    content => template('docker_base/bashrc'),
    mode    => 0600,
  }


  #####################################################
  # install packages
  #####################################################

  package {
    'screen': ensure => installed;
    'bind-utils': ensure => installed;
    'curl': ensure => installed;
    'wget': ensure => installed;
    'vim-enhanced': ensure => installed;
    'nscd': ensure => installed;
    'ntp': ensure => installed;
    'git': ensure => installed;
    'subversion': ensure => installed;
    'python': ensure => present;
    'python-devel': ensure => present;
    'python-virtualenv': ensure => present;
    'pbzip2': ensure => installed;
    'pigz': ensure => installed;
    'docker-ce': ensure => installed;
    'yum-utils': ensure => installed;
    'device-mapper-persistent-data': ensure => installed;
    'lvm2': ensure => installed;
  }


  #####################################################
  # link vim
  #####################################################
  update_alternatives { 'vi':
    link     => '/bin/vi',
    path     => '/bin/vim',
    priority => 1,
    require  => Package['vim-enhanced'],
  }


  #####################################################
  # refresh ld cache
  #####################################################

  if ! defined(Exec['ldconfig']) {
    exec { 'ldconfig':
      command     => '/sbin/ldconfig',
      refreshonly => true,
    }
  }
  

  #####################################################
  # link sciflo data area
  #####################################################
  file { '/data':
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => 0775,
  }


  #####################################################
  # start docker service
  #####################################################

  service { 'docker':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   Package['docker-ce'],
                  ],
  }


}
