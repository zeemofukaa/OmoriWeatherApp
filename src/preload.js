// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

const { contextBridge, desktopCapturer, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  getVideoSources: () => desktopCapturer.getSources({ types: ['window', 'screen'] }),
  saveDialog: (options) => ipcRenderer.invoke('show-save-dialog', options),
  writeFile: (path, buffer) => ipcRenderer.send('save-file', path, buffer)
});
