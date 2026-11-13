# Keychain
Store secrets in the macOS Keychain instead of plaintext `export` lines in rc files.
The `security` CLI ships with macOS.

## Store a secret
Start the line with a space so zsh does not save it to history (needs `setopt HIST_IGNORE_SPACE`):
```bash
 security add-generic-password -U -a "$USER" -s MY_SERVICE_CLIENT_ID -w '<client id>'
 security add-generic-password -U -a "$USER" -s MY_SERVICE_SECRET -w '<secret>'
```
- `-s` service name: the key you look the secret up by
- `-a` account: use `$USER`
- `-w` the secret value
- `-U` update the item if it already exists (use this to rotate a secret)

Run `security add-generic-password -U -a "$USER" -s MY_SERVICE_SECRET -w` with no value after `-w` and it prompts for the secret, so the secret is never on the command line.

## Read a secret
`security find-generic-password -s MY_SERVICE_SECRET -w`

`-w` prints only the value. Without it you get the item metadata.

## Use a secret for one command only
Wrap the command in a function in `~/.workrc` so the secret is only in that command's environment, not in every shell:
```bash
unalias mytool 2>/dev/null   # a function cannot replace an existing alias
mytool() {
  MY_SERVICE_CLIENT_ID=$(security find-generic-password -s MY_SERVICE_CLIENT_ID -w) \
  MY_SERVICE_SECRET=$(security find-generic-password -s MY_SERVICE_SECRET -w) \
  python3 $HOME/scripts/mytool.py "$@"
}
```
Then delete the old `export MY_SERVICE_*` lines from the rc file.

## Delete a secret
`security delete-generic-password -s MY_SERVICE_SECRET`

## Check that the secret is not in history
- zsh history: `grep MY_SERVICE ~/.cache/zsh/history`
- atuin records history separately and `HIST_IGNORE_SPACE` does not control it: `atuin search security`
