#

brew update
brew install scons yasm

git clone --depth 1 -b 4.4 --recursive https://github.com/godotengine/godot
cd godot
gd_dir=$(pwd)

openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)

echo "version=$(git rev-parse --short HEAD)" >>$GITHUB_ENV

sh misc/scripts/install_vulkan_sdk_macos.sh
git clone --depth 1 --recursive https://github.com/mauville-technologies/godot_dragonbones modules/godot_dragonbones
# git clone --depth 1 --recursive https://github.com/godotjs/GodotJS modules/GodotJS
# git clone --depth 1 --recursive https://github.com/quinnvoker/qurobullet modules/qurobullet
# git clone --depth 1 --recursive https://github.com/Zylann/godot_voxel modules/voxel
# git clone --depth 1 --recursive https://github.com/limbonaut/limboai modules/limboai
git apply --directory modules/godot_dragonbones ../4.x_1.patch
# qjs="use_quickjs_ng=yes"
qjs=""
scons platform=macos arch=x86_64 target=editor $qjs
scons platform=macos arch=arm64 target=editor $qjs
lipo -create bin/godot.macos.editor.x86_64 bin/godot.macos.editor.arm64 -output bin/godot.macos.editor.universal
cp -r misc/dist/macos_tools.app ./Godot.app
mkdir -p Godot.app/Contents/MacOS
cp bin/godot.macos.editor.universal Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
codesign --force --timestamp --options=runtime --entitlements misc/dist/macos/editor.entitlements -s - Godot.app
scons platform=web dlink_enabled=yes target=template_release $qjs

export JAVA_HOME=$JAVA_HOME_17_arm64
scons platform=android target=template_release arch=arm32 $qjs
scons platform=android target=template_release arch=arm64 generate_apk=yes $qjs
cd platform/android/java
./gradlew generateGodotTemplates

cd $gd_dir
cp godot.gdkey bin/
rm -rf bin/godot.macos* bin/obj
bsdtar -czf Godot.tgz Godot.app bin/*
