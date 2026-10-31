# Distrust CA roots with known compromised private keys.
# https://emudhra.we-have-a-problem.com/
_: {
  security.pki.caCertificateBlacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
}
