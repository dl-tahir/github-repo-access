#!/bin/bash
set -e

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}GitHub SSH Key Setup Script${NC}"
echo "=============================="

# 1. Check if SSH directory exists, if not create it
if [ ! -d "$HOME/.ssh" ]; then
    echo -e "${YELLOW}Creating ~/.ssh directory${NC}"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
else
    echo -e "${GREEN}SSH directory already exists${NC}"
fi

# 2. Check if SSH key already exists
if [ -f "$HOME/.ssh/id_rsa" ] && [ -f "$HOME/.ssh/id_rsa.pub" ]; then
    echo -e "${YELLOW}SSH key pair already exists at ~/.ssh/id_rsa${NC}"
    read -p "Do you want to create a new key anyway? (y/n): " create_new_key
    if [[ "$create_new_key" != "y" && "$create_new_key" != "Y" ]]; then
        echo "Using existing key."
    else
        create_key=true
    fi
else
    create_key=true
fi

# 3. Generate SSH key if needed
if [ "$create_key" = true ]; then
    echo -e "${GREEN}Generating new SSH key${NC}"
    read -p "Enter your email address for the SSH key: " email
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/id_rsa" -N ""
    echo -e "${GREEN}SSH key generated successfully${NC}"
fi

# 4. Start SSH agent and add key
echo -e "${GREEN}Starting SSH agent and adding key${NC}"
eval "$(ssh-agent -s)"
ssh-add "$HOME/.ssh/id_rsa"

# 5. Create SSH config file if it doesn't exist
if [ ! -f "$HOME/.ssh/config" ]; then
    echo -e "${GREEN}Creating SSH config file${NC}"
    cat > "$HOME/.ssh/config" << EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa
  IdentitiesOnly yes
EOF
    chmod 600 "$HOME/.ssh/config"
    echo -e "${GREEN}SSH config created${NC}"
else
    echo -e "${YELLOW}SSH config already exists, skipping${NC}"
fi

# 6. Ensure correct permissions
echo -e "${GREEN}Setting correct permissions${NC}"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh/id_rsa"
chmod 644 "$HOME/.ssh/id_rsa.pub"

# 7. Display the public key for GitHub
echo -e "${GREEN}Your public SSH key (add this to GitHub):${NC}"
echo "========================================"
cat "$HOME/.ssh/id_rsa.pub"
echo "========================================"
echo -e "${YELLOW}Copy the above key and add it to GitHub at:${NC}"
echo "https://github.com/settings/keys"

# 8. Offer to test connection
echo ""
read -p "Would you like to test the connection to GitHub now? (y/n): " test_connection
if [[ "$test_connection" == "y" || "$test_connection" == "Y" ]]; then
    echo -e "${GREEN}Testing connection to GitHub...${NC}"
    ssh -o StrictHostKeyChecking=accept-new -T git@github.com
    if [ $? -eq 1 ]; then
        # SSH to GitHub returns exit code 1 when successful (weird but true)
        echo -e "${GREEN}Connection successful! You're now set up to use GitHub with SSH.${NC}"
    else
        echo -e "${RED}Connection test failed. Please check your setup or run with debug:${NC}"
        echo "ssh -vT git@github.com"
    fi
else
    echo -e "${YELLOW}Skipping connection test.${NC}"
    echo "When ready, test your connection with: ssh -T git@github.com"
fi

echo -e "${GREEN}Setup complete!${NC}"

