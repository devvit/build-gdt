#

brew update
brew install scons yasm

git clone --depth 1 --recursive https://github.com/godotengine/godot
cd godot
gd_dir=$(pwd)

openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)

echo "version=$(git rev-parse --short HEAD)" >>$GITHUB_ENV

sh misc/scripts/install_vulkan_sdk_macos.sh
git clone --depth 1 --recursive https://github.com/mauville-technologies/godot_dragonbones modules/godot_dragonbones
# git clone --depth 1 --recursive https://github.com/godotjs/GodotJS modules/GodotJS
git clone --depth 1 --recursive https://github.com/quinnvoker/qurobullet modules/qurobullet
git clone --depth 1 --recursive https://github.com/limbonaut/limboai modules/limboai
# qjs="use_quickjs=yes"
qjs=""
scons platform=macos arch=x86_64 target=editor $qjs
cp -r misc/dist/macos_tools.app ./Godot.app
mkdir -p Godot.app/Contents/MacOS
cp bin/godot.macos* Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
codesign --force --timestamp --options=runtime --entitlements misc/dist/macos/editor.entitlements -s - Godot.app
scons platform=web target=template_release $qjs
# scons platform=web target=template_debug $qjs

export JAVA_HOME=$JAVA_HOME_17_X64
scons platform=android target=template_release arch=arm32 $qjs
scons platform=android target=template_release arch=arm64 generate_apk=yes $qjs
# scons platform=android target=template_debug arch=arm32 $qjs
# scons platform=android target=template_debug arch=arm64 $qjs
cd platform/android/java
./gradlew generateGodotTemplates

cd $gd_dir
cp godot.gdkey bin/
bsdtar -czf Godot.tgz Godot.app bin/*
