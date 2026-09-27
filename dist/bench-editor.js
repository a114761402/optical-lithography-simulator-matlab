// Move the existing inspector, rather than duplicating its state and inputs.
export function setupBenchEditor({components,onSelect,onLayout}){
  const $=id=>document.getElementById(id),media=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)');
  const inspector=$('component-inspector'),dialog=$('component-dialog'),summary=$('component-summary'),grid=$('component-grid');
  const menu=$('app-menu');
  for(const [key,name] of components){const b=document.createElement('button');b.type='button';b.textContent=key==='condenser'?'Cond.':name;b.setAttribute('aria-label',`Select ${key==='image'?'Image Plane':name}`);b.dataset.editorComponent=key;b.setAttribute('aria-pressed','false');b.onclick=()=>onSelect(key);grid.append(b);}
  function open(){if(!media.matches)return;dialog.showModal();summary.setAttribute('aria-expanded','true');grid.querySelector('[aria-pressed=true]')?.focus({preventScroll:true});}
  function close(){if(dialog.open)dialog.close();}
  summary.onclick=open;$('close-component').onclick=close;
  dialog.addEventListener('close',()=>{summary.setAttribute('aria-expanded','false');if(media.matches)summary.focus({preventScroll:true});});
  function adapt(){const wasOpen=dialog.open,compact=media.matches;close();document.body.classList.toggle('phone-bench',compact);(compact?$('component-editor-host'):$('bench-workspace')).append(inspector);onLayout();if(wasOpen&&!compact)inspector.querySelector('input,select,button')?.focus({preventScroll:true});}
  menu.addEventListener('click',e=>{if(e.target.closest('button'))menu.open=false;});
  document.addEventListener('click',e=>{if(!menu.contains(e.target))menu.open=false;});
  menu.addEventListener('keydown',e=>{if(e.key==='Escape'){menu.open=false;menu.querySelector('summary').focus();}});
  media.addEventListener('change',adapt);
  return {start:adapt,open,close,get compact(){return media.matches;},update(key,detail){const name=components.find(c=>c[0]===key)[1];$('component-summary-name').textContent=key==='image'?'Image Plane':name;$('component-summary-value').textContent=detail;summary.setAttribute('aria-label',`Components · ${name}${detail?' · '+detail:''}`);grid.querySelectorAll('button').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.editorComponent===key)));}};
}
