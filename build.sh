#

build_dir=$(pwd)

mkdir -p $build_dir/osxcross
docker pull ghcr.io/crazy-max/osxcross
docker create --name tmp-osxcross ghcr.io/crazy-max/osxcross
docker cp tmp-osxcross:/osxcross/. $build_dir/osxcross/
docker rm tmp-osxcross
export OSXCROSS_ROOT=$build_dir/osxcross
export PATH="$build_dir/osxcross/bin:$PATH"
export LD_LIBRARY_PATH="$build_dir/osxcross/lib:$LD_LIBRARY_PATH"

# macOS needs MoltenVK
mkdir -p $build_dir/moltenvk
cd $build_dir/moltenvk
curl -fSL -JO https://github.com/godotengine/moltenvk-osxcross/releases/download/vulkan-sdk-1.3.283.0-2/MoltenVK-all.tar
bsdtar -xf MoltenVK*.tar
mv MoltenVK/MoltenVK/include/ MoltenVK/
mv MoltenVK/MoltenVK/static/MoltenVK.xcframework/ MoltenVK/
rm -rf MoltenVK*.tar

# accesskit-c for Windows, macOS and Linux
mkdir -p $build_dir/accesskit
cd $build_dir/accesskit
curl -fSL -JO https://github.com/godotengine/godot-accesskit-c-static/releases/download/0.18.0/accesskit-c-0.18.0.zip
bsdtar -xf accesskit*.zip
mv accesskit-c-* accesskit-c
rm -rf accesskit*.zip

# Windows and macOS need ANGLE
mkdir -p $build_dir/angle
cd $build_dir/angle
base_url=https://github.com/godotengine/godot-angle-static/releases/download/chromium%2F7578/godot-angle-static
curl -fSL -JO $base_url-arm64-llvm-release.zip
curl -fSL -JO $base_url-x86_64-gcc-13-release.zip
curl -fSL -JO $base_url-x86_32-gcc-13-release.zip
curl -fSL -JO $base_url-arm64-macos-release.zip
curl -fSL -JO $base_url-x86_64-macos-release.zip
for f in $(ls *.zip); do
    bsdtar -xf "$f"
    rm -rf $f
done

cd $build_dir
git clone --depth 1 --recursive https://github.com/godotengine/godot
cd godot
openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)
echo "version=$(git rev-parse --short HEAD)" >>$GITHUB_ENV

echo 'BUILD MACOS'
scons platform=macos arch=x86_64 target=editor osxcross_sdk=darwin15 production=yes use_volk=no \
    vulkan_sdk_path=$build_dir/moltenvk angle_libs=$build_dir/angle accesskit_sdk_path=$build_dir/accesskit/accesskit-c
# lipo -create bin/godot.macos.editor.x86_64 bin/godot.macos.editor.arm64 -output bin/godot.macos.editor.universal
cp -r misc/dist/macos_tools.app ./Godot.app
mkdir -p Godot.app/Contents/MacOS
cp bin/godot.macos.editor.x86_64 Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
codesign --force --timestamp --options=runtime --entitlements misc/dist/macos/editor.entitlements -s - Godot.app

echo 'PACKAGE ALL'
cd $build_dir/godot
cp godot.gdkey bin/
ls -la bin/
rm -rf bin/godot.macos* bin/obj
bsdtar -czf Godot.tgz Godot.app bin/*
