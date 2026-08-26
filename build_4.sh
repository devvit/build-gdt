#

brew update
brew install scons yasm

gd_ver='4.7'

root_dir=$(pwd)

git clone --depth 1 -b $gd_ver --recursive https://github.com/godotengine/godot
cd godot
gd_dir=$(pwd)

openssl rand -hex 32 >godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY=$(cat godot.gdkey)

echo "version=$(git rev-parse --short HEAD)" >>$GITHUB_ENV

sh misc/scripts/install_vulkan_sdk_macos.sh

build_extension() {
    cd $root_dir

    git clone --depth 1 --recursive --shallow-submodules $1
    repo_dir=$(basename $1)

    cd $repo_dir

    rm -rf godot-cpp
    git clone --depth 1 https://github.com/godotengine/godot-cpp
    cp $root_dir/vmap.hpp godot-cpp/include/godot_cpp/templates/

    git grep -l SharedLibrary | while read f; do
        perl -pi -e 's/SharedLibrary/StaticLibrary/g' $f
    done

    if [[ -f tools/config.json ]]; then
        perl -i -pe 's/"godotProjectFolder":\s*"[^"]*"/"godotProjectFolder": ""/' tools/config.json
    fi

    if [[ -f "$root_dir/$repo_dir".patch ]]; then
        git apply "$root_dir/$repo_dir".patch
    fi

    scons target=editor arch=x86_64 api_version=$gd_ver

    libpath=$(find . -name lib*editor* -type f | grep -v libgodot-cpp | head -n1)
    libname=$(basename $libpath)
    modname=$(echo $libname | perl -ne 's/-/_/g; /lib(.*?)\./ && print $1')
    entryfunc=$(git grep entry_symbol | perl -ne '/"(.*)"/ && print $1')

    cd $gd_dir/modules
    cp -r $root_dir/my_module $modname

    cd $modname
    find . -type f | while read f; do
        perl -pi -e "s/MY_MODULE/\U${modname}/g" $f
        perl -pi -e "s/my_module/${modname}/g" $f
        perl -pi -e "s/sandbox/${modname}/g" $f
        perl -pi -e "s/libgodot_riscv/lib${modname}/g" $f
        perl -pi -e "s/my_addon_library_init/${entryfunc}/g" $f
    done
    perl -i -ne 'print unless /gdextension_interface/' register_types.cpp
    perl -i -pe 'print "#include \"core/config/engine.h\"\n" if $. == 1' register_types.cpp

    mkdir -p bin/addons/my_library/bin/libmy_library.macos.template_release.x86_64.framework

    cp $root_dir/$repo_dir/$libpath bin/addons/my_library/bin/libmy_library.macos.template_release.x86_64.framework/lib${modname}.macos.template_release.x86_64.a
    cp $root_dir/$repo_dir/godot-cpp/bin/libgodot-cpp.macos.editor.x86_64.a ext/godot-cpp/bin/libgodot-cpp.macos.template_release.x86_64.a
}

build_extension 'https://github.com/2shady4u/godot-sqlite'
build_extension 'https://github.com/Daylily-Zeleen/Godot-DragonBones'
build_extension 'https://github.com/nikoladevelops/godot-blast-bullets-2d'

cd $gd_dir

# git clone --depth 1 --recursive https://github.com/HKunogi/godot_luaAPI modules/luaAPI
# git clone --depth 1 --recursive https://github.com/mauville-technologies/godot_dragonbones modules/godot_dragonbones
# git apply --directory modules/godot_dragonbones ../4.x_1.patch
# git clone --depth 1 --recursive https://github.com/quinnvoker/qurobullet modules/qurobullet
# git apply --directory modules/qurobullet ../4.x_2.patch
git clone --depth 1 --recursive https://github.com/Zylann/godot_voxel modules/voxel
git clone --depth 1 --recursive https://github.com/limbonaut/limboai modules/limboai
git clone --depth 1 --recursive https://github.com/gd-avif/gd-avif modules/avif
perl -pi -e 's/#include "core\/extension\/ext_wrappers\.gen\.inc"/#include "core\/extension\/ext_wrappers.gen.h"/' modules/avif/resource_saver_avif.h
# git clone --depth 1 --recursive https://github.com/libriscv/godot-sandbox modules/sandbox
# perl -i -ne 'print unless /gdextension_interface/' modules/sandbox/register_types.cpp
# git clone --depth 1 --recursive https://github.com/godotjs/GodotJS modules/GodotJS
# qjs="use_quickjs_ng=yes"
build_args="$qjs"

echo 'BUILD MACOS'
scons platform=macos arch=x86_64 target=editor $build_args
# scons platform=macos arch=arm64 target=editor $build_args
# lipo -create bin/godot.macos.editor.x86_64 bin/godot.macos.editor.arm64 -output bin/godot.macos.editor.universal
cp -r misc/dist/macos_tools.app ./Godot.app
mkdir -p Godot.app/Contents/MacOS
# cp bin/godot.macos.editor.universal Godot.app/Contents/MacOS/Godot
cp bin/godot.macos.editor.x86_64 Godot.app/Contents/MacOS/Godot
chmod +x Godot.app/Contents/MacOS/Godot
codesign --force --timestamp --options=runtime --entitlements misc/dist/macos/editor.entitlements -s - Godot.app

echo 'BUILD WEB'
# scons platform=web dlink_enabled=yes target=template_release $build_args

echo 'BUILD ANDROID'
# export JAVA_HOME=$JAVA_HOME_17_arm64
# scons platform=android target=template_release arch=arm32 $build_args
# scons platform=android target=template_release arch=arm64 generate_apk=yes $build_args
# cd platform/android/java
# ./gradlew generateGodotTemplates

echo 'PACKAGE ALL'
cd $gd_dir
cp godot.gdkey bin/
ls -la bin/
rm -rf bin/godot.macos* bin/obj
bsdtar -czf Godot.tgz Godot.app bin/*
