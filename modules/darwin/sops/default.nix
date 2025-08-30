_: {
  sops.age = {
    generateKey = true;
    # Generate manually via `sudo ssh-keygen -A`
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
