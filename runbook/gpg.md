anatomy of a key:
```
pub   rsa2048 2025-01-14 [SC]           ← public key: algorithm, date, capabilities
        FDSJKLFJDLJFLSDJFLKJLDJFLSDJFJFS  ← fingerprint (40 hex chars)
  uid           [some_descriptor] Marvin Dore <some_email>  ← identity + trust level
  sub   rsa2048 2025-01-14 [A]            ← subkey (auth)
  sub   rsa2048 2025-01-14 [E]            ← subkey (encrypt)
```

list all keys:
`gpg --list-keys <optional_email_for_filtering>`

list keys which  have private keys:
`gpg --list-secret-keys <optional_email_for_filtering>`

reading key output info:
```
Note the > on sec>

  sec>  ← the > means the private key lives on a hardware token (your YubiKey)
  sec   ← no > means the private key is stored in software on disk

  Either works for exporting the public key to GitHub. The > just tells you where the private half lives.
```
