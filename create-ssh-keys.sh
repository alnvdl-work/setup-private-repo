#!/bin/bash

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 <PRIVATE_DEP> <DEP_CONSUMER>"
    echo "  PRIVATE_DEP: org/repo of the private dependency (e.g., alnvdl-work/my-private-dep)"
    echo "  DEP_CONSUMER: org/repo that uses the dependency (e.g., alnvdl-work/my-build-repo)"
    exit 1
fi

PRIVATE_DEP="$1"
DEP_CONSUMER="$2"

REPO_NAME=$(echo "$PRIVATE_DEP" | tr '/' '_' | tr '-' '_')
KEY_NAME="tmp-${REPO_NAME}-key"
KEY_PATH="$HOME/.ssh/$KEY_NAME"

echo "Setting up SSH keys for private dependency: $PRIVATE_DEP"
echo "To be used in consumer repo: $DEP_CONSUMER"
echo ""

echo "Generating SSH key pair..."
ssh-keygen -N "" -C "$DEP_CONSUMER" -f "$KEY_PATH"
echo ""

PUBLIC_KEY=$(cat "${KEY_PATH}.pub")
PRIVATE_KEY=$(cat "$KEY_PATH")

echo "Setup instructions"
echo ""
echo "1. Setup the public key as a deploy key in $PRIVATE_DEP:"
echo "   A. Go to: https://github.com/$PRIVATE_DEP/settings/keys"
echo "   B. Click 'Add deploy key'"
echo "   C. Title: Deploy key for $DEP_CONSUMER"
echo "   D. Key (copy the text below):"
echo ""
echo "$PUBLIC_KEY"
echo ""
echo "   E. Make sure 'Allow write access' is unchecked (read-only)"
echo "   F. Click 'Add key'"
echo ""
echo "2. Setup the private key as a secret in $DEP_CONSUMER:"
echo "   A. Go to: https://github.com/$DEP_CONSUMER/settings/secrets/actions"
echo "   B. Click 'New repository secret'"
echo "   C. Name: ${REPO_NAME^^}_SSH_KEY"
echo "   D. Secret (copy the text below):"
echo ""
echo "$PRIVATE_KEY"
echo ""
echo "   E. Click 'Add secret'"
echo ""
echo "3. Setup the private key as a Dependabot secret in $DEP_CONSUMER:"
echo "   A. Go to: https://github.com/$DEP_CONSUMER/settings/secrets/dependabot"
echo "   B. Click 'New repository secret'"
echo "   C. Name: ${REPO_NAME^^}_SSH_KEY"
echo "   D. Secret (copy the same private key from step 2)"
echo "   E. Click 'Add secret'"
echo ""
echo "4. Use the secret in your workflows in $DEP_CONSUMER:"
echo ""
echo "      - name: setup-private-repo"
echo "        uses: alnvdl-work/setup-private-repo@v2"
echo "        with:"
echo "          repository: $PRIVATE_DEP"
echo "          ssh-key: \${{ secrets.${REPO_NAME^^}_SSH_KEY }}"
echo ""
echo "Cleaning up temporary key files..."
rm -f "$KEY_PATH" "${KEY_PATH}.pub"
echo "Key files deleted successfully."
echo ""
echo "Setup complete! Follow the instructions above to configure your repositories."
