#

brew update
brew install scons yasm

git clone --depth 1 --branch 4.3 --recursive https://github.com/godotengine/godot
cd godot
gd_dir=$(pwd)

openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)

echo "version=$(git rev-parse --short HEAD)" >>$GITHUB_ENV

sh misc/scripts/install_vulkan_sdk_macos.sh
git clone --depth 1 --recursive https://github.com/mauville-technologies/godot_dragonbones modules/godot_dragonbones
# git clone --depth 1 --recursive https://github.com/Geequlim/ECMAScript modules/javascript
git clone --depth 1 --recursive https://github.com/godotjs/GodotJS modules/GodotJS
scons platform=macos arch=x86_64 target=editor use_quickjs=yes
cp -r misc/dist/macos_tools.app ./Godot.app
mkdir -p Godot.app/Contents/MacOS
cp bin/godot.macos* Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
codesign --force --timestamp --options=runtime --entitlements misc/dist/macos/editor.entitlements -s - Godot.app
scons platform=web target=template_release use_quickjs=yes
# scons platform=web target=template_debug use_quickjs=yes

export JAVA_HOME=$JAVA_HOME_17_X64
# scons platform=android target=template_release arch=arm32 use_quickjs=yes
scons platform=android target=template_release arch=arm64 use_quickjs=yes generate_apk=yes
# scons platform=android target=template_debug arch=arm32 use_quickjs=yes
# scons platform=android target=template_debug arch=arm64 use_quickjs=yes
cd platform/android/java
./gradlew generateGodotTemplates

cd $gd_dir
cp bin/android_release.apk bin/android_debug.apk
cp bin/godot.web.template_release.wasm32.zip bin/web_nothreads_debug.zip
cp bin/godot.web.template_release.wasm32.zip bin/web_nothreads_release.zip
bsdtar -czf Godot.tgz godot.gdkey Godot.app bin/*
