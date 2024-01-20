#

test

```bash
ibtool --compile ConsoleWindow.nib ConsoleWindow.xib
lipo -create bin/godot.macos.editor.x86_64 bin/godot.macos.editor.arm64 -output bin/godot.macos.editor.universal
```
