#

brew update
brew install emscripten scons yasm

git clone --depth 1 -b 3.x --recursive https://github.com/godotengine/godot
cd godot
gd_dir=$(pwd)

openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)

echo "version=$(git rev-parse --short HEAD)" >>$GITHUB_ENV

curl -fsSL -JO https://github.com/mauville-technologies/godot_dragonbones/archive/a1387eea95c68d988e4868b2affc6a48cf1506b2.zip
bsdtar -xf godot_dragonbones*.zip
rm -rf godot_dragonbones*.zip
mv godot_dragonbones* modules/godot_dragonbones
# git clone --depth 1 -b 3.4 --recursive https://github.com/godotjs/javascript modules/ECMAScript
git clone --depth 1 -b godot-3.x --recursive https://github.com/quinnvoker/qurobullet modules/qurobullet
perl -pi -e 's/-fno-rtti//g' platform/android/detect.py
perl -pi -e 's/-fno-rtti//g' platform/javascript/detect.py
git apply --directory modules/godot_dragonbones ../3.x_1.patch
scons platform=osx arch=x86_64 target=release_debug tools=yes
scons platform=osx arch=arm64 target=release_debug tools=yes
lipo -create bin/godot.osx.opt.tools.x86_64 bin/godot.osx.opt.tools.arm64 -output bin/godot.osx.tools.universal
cp -r misc/dist/osx_tools.app Godot.app
mkdir -p Godot.app/Contents/MacOS
cp bin/godot.osx.tools.universal Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
scons platform=javascript tools=no target=release LINKFLAGS='-sGL_ENABLE_GET_PROC_ADDRESS'
# https://github.com/Geequlim/ECMAScript/issues/57
# scons platform=javascript tools=no target=release_debug LINKFLAGS='-sGL_ENABLE_GET_PROC_ADDRESS'

export JAVA_HOME=$JAVA_HOME_17_arm64
scons platform=android target=release android_arch=armv7
scons platform=android target=release android_arch=arm64v8
# scons platform=android target=release_debug android_arch=armv7
# scons platform=android target=release_debug android_arch=arm64v8
cd platform/android/java
./gradlew generateGodotTemplates

cd $gd_dir
cp godot.gdkey bin/
rm -rf bin/godot.osx*
bsdtar -czf Godot.tgz Godot.app bin/*
