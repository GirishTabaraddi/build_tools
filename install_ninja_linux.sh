mkdir -p ninja-linux
wget https://github.com/ninja-build/ninja/releases/download/v1.12.1/ninja-linux.zip
unzip ninja-linux.zip -d ninja-linux && rm ninja-linux.zip
chmod +x ninja-linux/ninja
./ninja-linux/ninja --version