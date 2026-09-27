// Share one inspector between the desktop workspace and the phone sheet.
export function setupBenchEditor({components,onSelect,onLayout}){
  const $=id=>document.getElementById(id),media=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)');
  const inspector=$('component-inspector'),dialog=$('component-dialog'),grid=$('component-grid'),launcher=$('open-components'),menu=$('app-menu');
  let returnKey=null;
  // SVG elements are redrawn on selection; resolve their stable component key later.
  function returnTarget(){return returnKey?$('bench').querySelector(`[data-component="${returnKey}"]`)||menu.querySelector('summary'):menu.querySelector('summary');}
  for(const [key,name] of components){const b=document.createElement('button');b.type='button';b.textContent=key==='condenser'?'Cond.':name;b.setAttribute('aria-label',`Select ${key==='image'?'Image Plane':name}`);b.dataset.editorComponent=key;b.setAttribute('aria-pressed','false');b.onclick=()=>onSelect(key);grid.append(b);}
  function open(key=null){if(!media.matches)return;returnKey=typeof key==='string'?key:null;dialog.showModal();grid.querySelector('[aria-pressed=true]')?.focus({preventScroll:true});}
  function close(){if(dialog.open)dialog.close();}
  launcher.onclick=()=>{$('display-dialog').close();open();};$('close-component').onclick=close;
  dialog.addEventListener('close',()=>{if(media.matches&&!document.querySelector('dialog[open]'))returnTarget()?.focus({preventScroll:true});});
  function adapt(){const wasOpen=dialog.open,compact=media.matches;close();document.body.classList.toggle('phone-bench',compact);(compact?$('component-editor-host'):$('bench-workspace')).append(inspector);onLayout();if(wasOpen&&!compact)inspector.querySelector('input,select,button')?.focus({preventScroll:true});}
  menu.addEventListener('click',e=>{if(e.target.closest('button'))menu.open=false;});
  document.addEventListener('click',e=>{if(!menu.contains(e.target))menu.open=false;});
  menu.addEventListener('keydown',e=>{if(e.key==='Escape'){menu.open=false;menu.querySelector('summary').focus();}});
  media.addEventListener('change',adapt);
  return {start:adapt,open,close,returnTarget,get compact(){return media.matches;},update(key){grid.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.editorComponent===key)));}};
}
