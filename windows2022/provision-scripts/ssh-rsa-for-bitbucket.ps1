# Hotfix to remedy an issue that BB is proposing deprecated `ssh-rsa` and `ssh-dsa`.
# Remove this remedy accordingly once Atlassian makes a proper action to obsolete them.

$ErrorActionPreference="Stop"

@"
Host bitbucket.org
        HostkeyAlgorithms +ssh-rsa
        PubkeyAcceptedAlgorithms +ssh-rsa
"@ | Out-File "C:\Program Files\Git\etc\ssh\ssh_config" -Append -Encoding ascii
