#

TEST

```bash
ibtool --compile ConsoleWindow.nib ConsoleWindow.xib
lipo -create bin/godot.macos.editor.x86_64 bin/godot.macos.editor.arm64 -output bin/godot.macos.editor.universal
openssl rand -hex 32 > godot.gdkey
export SCRIPT_AES256_ENCRYPTION_KEY="your_generated_key"
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -keystore debug.keystore -storepass android -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
keytool -v -genkey -keystore mygame.keystore -alias mygame -keyalg RSA -validity 10000

keytool -genkey -v -keystore mygame.keystore -alias mygame -keyalg RSA -keysize 2048 -validity 10000
apksigner sign --ks mygame.keystore --ks-key-alias mygame mygame.apk
```

```javascript
// Modules to control application life and create native browser window
const { app, BrowserWindow } = require('electron');
const path = require('node:path');

function createWindow() {
  // Create the browser window.
  const mainWindow = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      webSecurity: false,
    },
    // frame: true,
    // titleBarStyle: 'customButtonsOnHover',
    // roundedCorners: false,
    frame: false,
    minimizable: false,
    maximizable: false,
    closable:false,
    // thickFrame: false,
    titleBarStyle: 'customButtonsOnHover'

  });
  mainWindow.webContents.session.webRequest.onBeforeSendHeaders(
    (details, callback) => {
      callback({
        requestHeaders: {
          Origin: '*',
          // 'Cross-Origin-Opener-Policy': 'same-origin',
          // 'Cross-Origin-Embedder-Policy': 'require-corp',
          ...details.requestHeaders,
        },
      });
    }
  );

  mainWindow.webContents.session.webRequest.onHeadersReceived(
    (details, callback) => {
      callback({
        responseHeaders: {
          'Access-Control-Allow-Origin': ['*'],
          'Cross-Origin-Embedder-Policy': 'require-corp',
          'Cross-Origin-Opener-Policy': 'same-origin',
          ...details.responseHeaders,
        },
      });
    }
  );

  // and load the index.html of the app.
  mainWindow.loadFile('index.html', {
    // extraHeaders: 'Cross-Origin-Opener-Policy: same-origin\nCross-Origin-Embedder-Policy: require-corp'
  });

  // Open the DevTools.
  // mainWindow.webContents.openDevTools()
}

app.commandLine.appendSwitch('enable-features', 'SharedArrayBuffer');
// app.commandLine.appendSwitch('disable-features', 'OutOfBlinkCors')

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(() => {
  createWindow();

  app.on('activate', function () {
    // On macOS it's common to re-create a window in the app when the
    // dock icon is clicked and there are no other windows open.
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

// In this file you can include the rest of your app's specific main process
// code. You can also put them in separate files and require them here.
```
