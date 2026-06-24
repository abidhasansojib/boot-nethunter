#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "========================================="
echo "   Git & GitHub CLI Auto-Installer       "
echo "========================================="

# 1. Install prerequisites
echo -e "\n[*] Updating package lists and installing prerequisites..."
apt update && apt install curl gpg -y

# 2. Add the official GitHub CLI repository correctly
echo -e "\n[*] Adding GitHub CLI repository..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg --yes

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# 3. Update and install Git + GH
echo -e "\n[*] Installing git and gh..."
apt update && apt install git gh -y

# 4. Trigger GitHub authentication
echo -e "\n[*] Starting GitHub Authentication..."
echo "-----------------------------------------------------------------"
echo "CRITICAL: When prompted:"
echo "1. Choose HTTPS or SSH"
echo "2. Select 'Yes' to authenticate Git with GitHub credentials"
echo "3. Ensure you grant 'repo' permissions during browser/token login"
echo "-----------------------------------------------------------------"
gh auth login

# 5. Ask user for Git identity setup
echo -e "\n[*] Configuring Git Identity..."
read -p "Enter your GitHub Username: " github_user
read -p "Enter your GitHub Email: " github_email

git config --global user.name "$github_user"
git config --global user.email "$github_email"

# 6. Bridge Git and GH credentials
echo -e "\n[*] Linking Git with GitHub CLI credential helper..."
gh auth setup-git

# 7. Final Verification
echo -e "\n========================================="
echo "✅ Setup Complete! Here is your config:"
echo "========================================="
git config --list | grep -E "user.name|user.email|credential.helper"
