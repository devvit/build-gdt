docker pull ghcr.io/crazy-max/osxcross

mkdir -p build

docker run --rm \
    -v "$(pwd)":/build \
    -w /build \
    ghcr.io/crazy-max/osxcross \
    bash -c "
apt-get update && apt-get install -y scons
OSXCROSS_ROOT=/osxcross

git clone --depth 1 --recursive https://github.com/godotengine/godot
cd godot
gd_dir=$(pwd)

openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)

echo 'BUILD MACOS'
scons platform=macos arch=x86_64 target=editor
cp -r misc/dist/macos_tools.app ./Godot.app
mkdir -p Godot.app/Contents/MACOS
cp bin/godot.macos.editor.x86_64 Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
codesign --force --timestamp --options=runtime --entitlements misc/dist/macos/editor.entitlements -s - Godot.app

echo 'PACKAGE ALL'
cd $gd_dir
cp godot.gdkey bin/
ls -la bin/
rm -rf bin/godot.macos* bin/obj
bsdtar -czf Godot.tgz Godot.app bin/*
mv Godot.tgz /build
"
