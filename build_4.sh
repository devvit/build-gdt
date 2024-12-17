#

export JAVA_HOME=$JAVA_HOME_17_X64
# scons platform=android target=template_release arch=arm32 use_quickjs=yes
scons platform=android target=template_release arch=arm64 use_quickjs=yes
# scons platform=android target=template_debug arch=arm32 use_quickjs=yes
scons platform=android target=template_debug arch=arm64 use_quickjs=yes
cd platform/android/java
./gradlew generateGodotTemplates
