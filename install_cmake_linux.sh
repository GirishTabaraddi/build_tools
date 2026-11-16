CMAKE_VER=4.5.0
wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VER}/cmake-${CMAKE_VER}-linux-x86_64.tar.gz

mkdir -p CMake-linux
tar -xzf cmake-${CMAKE_VER}-linux-x86_64.tar.gz -C CMake-linux --strip-components=1
rm cmake-${CMAKE_VER}-linux-x86_64.tar.gz

./CMake-linux/bin/cmake --version