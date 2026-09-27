import {Capacitor} from '@capacitor/core';
import {Directory,Filesystem} from '@capacitor/filesystem';
import {Preferences} from '@capacitor/preferences';
import {Share} from '@capacitor/share';

if(Capacitor.isNativePlatform()){
  document.documentElement.classList.add('ios-native');
  const automaticKey='optical-bench-session-v1';
  const manualKey='optical-bench-saved-experiment-v1';
  const read=async key=>{
    const {value}=await Preferences.get({key});
    if(!value)return null;
    try{return JSON.parse(value);}catch{return null;}
  };
  const save=async key=>{
    const state=window.OpticalBenchSession?.snapshot();
    if(!state)return false;
    await Preferences.set({key,value:JSON.stringify(state)});
    return true;
  };
  const sharePng=async file=>{
    const bytes=new Uint8Array(await file.arrayBuffer());
    let binary='';
    for(let i=0;i<bytes.length;i+=8192)binary+=String.fromCharCode(...bytes.subarray(i,i+8192));
    const saved=await Filesystem.writeFile({path:file.name,data:btoa(binary),directory:Directory.Cache});
    return Share.share({files:[saved.uri],title:'Optical Bench observation',dialogTitle:'Save or share image'});
  };
  let timer=null;
  let autosaveEnabled=true;
  const clearAutosave=()=>{autosaveEnabled=false;clearTimeout(timer);return Preferences.remove({key:automaticKey});};
  window.OpticalBenchNative={sharePng,clearAutosave};
  function schedule(){if(!autosaveEnabled)return;clearTimeout(timer);timer=setTimeout(()=>save(automaticKey).catch(error=>console.warn('Could not save experiment:',error)),350);}
  async function ready(){
    const app=window.OpticalBenchSession;
    if(!app)return;
    try{const previous=await read(automaticKey);if(previous)app.restore(previous);}catch(error){console.warn('Could not restore experiment:',error);}
    document.addEventListener('change',schedule);
    document.addEventListener('pointerup',schedule);
    document.addEventListener('keyup',schedule);
    document.addEventListener('position-view-change',schedule);
    document.addEventListener('visibilitychange',()=>{if(document.hidden&&autosaveEnabled)save(automaticKey).catch(error=>console.warn('Could not save experiment:',error));});
    const host=document.createElement('div');host.className='ios-experiments';
    host.innerHTML='<p>Experiments</p><div><button type="button" id="ios-save-experiment" class="secondary">Save experiment</button><button type="button" id="ios-open-experiment" class="secondary">Open saved experiment</button></div><p id="ios-experiment-status" role="status" aria-live="polite"></p>';
    document.getElementById('display-dialog-controls').prepend(host);
    const message=text=>document.getElementById('ios-experiment-status').textContent=text;
    document.getElementById('ios-save-experiment').onclick=async()=>{
      try{await save(manualKey);message('Experiment saved on this iPhone.');}
      catch{message('Could not save this experiment.');}
    };
    document.getElementById('ios-open-experiment').onclick=async()=>{
      try{const saved=await read(manualKey);if(!saved){message('No saved experiment yet.');return;}
        app.restore(saved);schedule();message('Experiment opened. Images that need recalculation are marked.');}
      catch{message('Could not open the saved experiment.');}
    };
  }
  window.addEventListener('optical-bench-ready',ready,{once:true});
  if(window.OpticalBenchSession)ready();
}
