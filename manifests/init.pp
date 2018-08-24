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
  # install .bash_profile
  #####################################################

  file { "/home/$user/.bash_profile":
    ensure  => present,
    content => template('docker_base/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => 0644,
    require => User[$user],
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
    'bzip2': ensure => installed;
    'pbzip2': ensure => installed;
    'pigz': ensure => installed;
    'docker-ce': ensure => installed;
    'yum-utils': ensure => installed;
    'device-mapper-persistent-data': ensure => installed;
    'lvm2': ensure => installed;
  }


  #####################################################
  # install docker-compose
  #####################################################

  file { '/usr/local/bin':
    ensure  => directory,
    mode    => 0755,
  }


  file { "/usr/local/bin/docker-compose":
    ensure  => file,
    mode    => 0755,
    source => 'puppet:///modules/docker_base/docker-compose',
    require => [
        File['/usr/local/bin'],
    ],
  }


  #####################################################
  # systemd daemon reload
  #####################################################

  exec { "daemon-reload":
    path        => ["/sbin", "/bin", "/usr/bin"],
    command     => "systemctl daemon-reload",
    refreshonly => true,
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
  # docker-ephemeral-lvm service
  #####################################################

  file { '/etc/systemd/system/docker-ephemeral-lvm.d':
    ensure  => directory,
    mode    => 0755,
  }


  file { '/etc/systemd/system/docker-ephemeral-lvm.d/docker-ephemeral-lvm.sh':
    ensure  => present,
    mode    => 0755,
    content => template('docker_base/docker-ephemeral-lvm.sh'),
    require => File['/etc/systemd/system/docker-ephemeral-lvm.d'],
  }


  file { "/etc/systemd/system/docker-ephemeral-lvm.d/beefed-autoindex-open_in_new_win.tbz2":
    ensure  => file,
    mode    => 0644,
    source => 'puppet:///modules/docker_base/beefed-autoindex-open_in_new_win.tbz2',
    require => File['/etc/systemd/system/docker-ephemeral-lvm.d'],
  }


  file { '/etc/systemd/system/docker-ephemeral-lvm.service':
    ensure  => present,
    mode    => 0644,
    content => template('docker_base/docker-ephemeral-lvm.service'),
    require => [
                File['/etc/systemd/system/docker-ephemeral-lvm.d/docker-ephemeral-lvm.sh'],
                File['/etc/systemd/system/docker-ephemeral-lvm.d/beefed-autoindex-open_in_new_win.tbz2'],
               ],
    notify  => Exec['daemon-reload'],
  }


  service { 'dm-event':
    ensure  => running,
    enable  => true,
    require => Exec['daemon-reload'],
  }


  service { 'docker-ephemeral-lvm':
    ensure  => stopped,
    enable  => true,
    require => [
                Service['dm-event'],
                File['/etc/systemd/system/docker-ephemeral-lvm.service'],
                Exec['daemon-reload'],
               ],
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
                   Service['docker-ephemeral-lvm'],
                  ],
  }


}
