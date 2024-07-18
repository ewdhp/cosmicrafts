#!/bin/bash

# Update and upgrade packages
echo "sudo apt update"
sudo apt update

echo "sudo apt upgrade"
sudo apt upgrade -y  # Use -y flag to automatically answer yes to all prompts

# Install nvm and node
echo "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

echo "export NVM_DIR=\"\$([ -z \"\${XDG_CONFIG_HOME-}\" ] && printf %s \"\${HOME}/.nvm\" || printf %s \"\${XDG_CONFIG_HOME}/nvm\")\" [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\""
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")" [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "source ~/.bashrc"
source ~/.bashrc

echo "nvm install node"
nvm install node

# Install dfx and ic-mops
echo "sh -ci \"\$(curl -fsSL https://internetcomputer.org/install.sh)\""
sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)" < <(echo -ne '\n')

echo "npm i -g ic-mops"
npm i -g ic-mops

# Install vessel
echo "wget https://github.com/dfinity/vessel/releases/download/v0.7.0/vessel-linux64"
wget https://github.com/dfinity/vessel/releases/download/v0.7.0/vessel-linux64

echo "mv vessel-linux64 vessel"
mv vessel-linux64 vessel

echo "chmod +x vessel"
chmod +x vessel

echo "mkdir bin"
mkdir -p ~/bin  # Create bin directory if it doesn't exist

echo "cp ~/vessel ~/bin/"
cp ~/vessel ~/bin/

echo "export PATH=\"\$HOME/bin:\$PATH\""
export PATH="$HOME/bin:$PATH"

echo "source ~/.bashrc"
source ~/.bashrc

echo "Script execution completed."


