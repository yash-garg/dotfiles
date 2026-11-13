_: {
  sops.age = {
    # Decrypt through the SSH host key below. With no keyFile, generateKey
    # invokes age-keygen with an empty output path and prints an unused private key.
    generateKey = false;
    sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };
}
