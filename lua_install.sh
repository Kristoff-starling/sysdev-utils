#!/bin/bash

# Install LuaRocks package manager
sudo apt update
sudo apt install -y luarocks

# Install luasocket module (required by wrk Lua scripts)
sudo luarocks install luasocket

# Verify installation
echo "Verifying installation..."
luarocks list | grep socket
lua -e "require('socket'); print('socket module loaded successfully')" 2>&1 || luajit -e "require('socket'); print('socket module loaded successfully')" 2>&1

echo "Installation complete!"
