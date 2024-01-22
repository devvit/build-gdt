#

export JAVA_HOME=$JAVA_HOME_17_X64
scons platform=android target=template_release arch=arm32
scons platform=android target=template_release arch=arm64
scons platform=android target=template_debug arch=arm32
scons platform=android target=template_debug arch=arm64
cd platform/android/java
./gradlew generateGodotTemplates
