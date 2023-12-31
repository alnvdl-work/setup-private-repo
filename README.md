# setup-private-repo

setup-private-repo is a GitHub action that Clones a private GitHub repository
using an SSH key or personal access token, and configures Git to use that local
copy instead.

This action implements 3 steps:
1. Sets ups a dedicated folder so that multiple private repos can be setup
   simultaneously if needed (`$GITHUB_WORKSPACE/.private-repos`).
1. Clones private repositories fully (history of all branches and tags) to the
   `$GITHUB_WORKSPACE/.private-repos` folder using
   [`actions/checkout`](https://github.com/actions/checkout).
2. Configures Git with a `insteadOf` directive to use the local clone whenever
   the HTTPS URL of the private repo is referenced.

This action is most useful for building Go applications relying on private
dependencies, as it will enable Go to find the required tag or commit from the
cloned repo without requiring any ad-hoc hacks to go.mod or git configuration
files.

## Inputs
- `repository` (required): the full name of the GitHub repository
  (e.g., `alnvdl-work/setup-private-repo`).
- `ssh-key` (recommended): a private SSH key to use for cloning. See
  [SSH key setup](#ssh-key-setup).
- `token`: a personal access token to use for cloning. See
  [Personal access token setup](#personal-access-token-setup).
- `ref` (optional, usually inferred by `actions/checkout`): The ref to
  checkout. You most likely don't need this. One use case for this is to
  indicate to `actions/checkout` that you want to checkout a branch containing
  certain commits when building pull requests for repositories that import
  themselves as private repositories (so that this action sets up the private
  repository using a ref that is not dictated by the PR).

## Outputs
None.

## Example
```yaml
name: Build with a dependency on a private repo

on: [push]

jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - name: load-private-repo
        uses: alnvdl-work/setup-private-repo@v1
        with:
          repository: alnvdl-work/my-private-dep
          ssh-key: ${{ secrets.MY_PRIVATE_DEP_SSH_KEY }}
      - name: verify-that-it-worked
        run: |
          cat ~/.gitconfig
          cat $GITHUB_WORKSPACE/.private-repos/alnvdl-work/my-private-dep/LICENSE
        shell: bash
```

## SSH key setup
Consider the following two repos:
- `my-private-dep`: the private repo you are trying to clone for a build.
- `my-build-repo`: the repo you are building using a GitHub Actions workflow.

1. Generate a key pair without a passphrase:
   ```sh
   ssh-keygen -N "" -C "my-private-dep" -f ~/.ssh/my-private-dep-key
   ```

2. Obtain the public key:
   ```sh
   cat ~/.ssh/my-private-dep-key.pub
   ```

   Then set it up as a **read-only deploy key** in `my-private-dep`. You can do
   that in the GitHub settings for `my-private-dep`. See:
   https://docs.github.com/en/authentication/connecting-to-github-with-ssh/managing-deploy-keys#deploy-keys

3. Obtain the private key:
   ```sh
   cat ~/.ssh/my-private-dep-key
   ```
   Then set it up as a GitHub Actions secret in `my-build-repo`. You can do
   that in the GitHub settings for `my-build-repo`. Make sure to use an
   unambigous name, like `MY_PRIVATE_DEP_SSH_KEY`. See:
   https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions

4. Remove the public and private keys from your machine:
   ```sh
   rm -rf ~/.ssh/my-private-dep-key
   rm -rf ~/.ssh/my-private-dep-key.pub
   ```

5. In your GitHub Actions workflow in `my-build-repo`, make sure to set the
   `ssh-key` input for `alnvdl-work/setup-private-repo@v1` with the **name** of
   the secret you configured in step 4.

## Personal access token setup
If an SSH read-only deploy key cannot be used, a fine-grained personal access
token can be used instead.

See: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens#fine-grained-personal-access-tokens

Make sure to only grant the minimal access possible (read-only for `content`
and `metadata`, and only in the repos needed).
