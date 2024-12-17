#

export JAVA_HOME=$JAVA_HOME_17_X64
scons platform=android target=release android_arch=armv7
scons platform=android target=release android_arch=arm64v8
# scons platform=android target=release_debug android_arch=armv7
# scons platform=android target=release_debug android_arch=arm64v8
cd platform/android/java
./gradlew generateGodotTemplates
