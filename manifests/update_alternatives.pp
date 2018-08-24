define docker_base::update_alternatives ($link, $path, $priority) {
  exec { "set-${name}":
    path => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command => "update-alternatives --install ${link} ${name} ${path} ${priority}",
    unless => "update-alternatives --display ${name} | grep 'points to' | grep -q '${path}'",
  }
}
