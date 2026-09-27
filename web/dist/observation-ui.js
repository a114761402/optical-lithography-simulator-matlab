export function setupObservationUI(getPlanes,{onSelect,onRemove,onAdd,onUndo,onReference}){
  const $=id=>document.getElementById(id),grid=document.createElement('div');
  grid.id='observation-grid';grid.setAttribute('role','group');grid.setAttribute('aria-label','Observation positions');
  $('observation-layout').before(grid);
  const preset=document.createElement('div');preset.id='reference-preset-row';preset.innerHTML='<span>Explore any position</span><button type="button" id="reference-positions" class="secondary" title="Restore Pupil, Mask, Aperture and Image positions">Default positions</button>';
  $('position-controls').before(preset);$('reference-positions').onclick=onReference;
  const toolbar=document.createElement('div');toolbar.className='observation-toolbar';
  toolbar.innerHTML='<button id="add-position" class="secondary" type="button" aria-label="Add position group" title="Add four comparison positions">＋</button><span id="removed-position" role="status"></span><button id="undo-position" class="quiet" type="button" hidden>Undo</button>';
  toolbar.prepend($('reference-positions'));
  $('observation-title').closest('.observation-heading').append(toolbar);$('add-position').onclick=onAdd;$('undo-position').onclick=onUndo;
  const empty=document.createElement('p');empty.id='observation-empty';empty.textContent='Add a position to explore the light.';grid.after(empty);
  const active=document.createElement('p');active.id='active-observation';active.setAttribute('aria-live','polite');$('reference-preset-row').append(active);
  const badge=document.createElement('span');badge.id='observation-state';badge.className='slice-state';$('observation-label').after(badge);
  $('observation-title').innerHTML='<span class="wide-label">Key positions</span><span class="phone-label">Observation screen</span>';
  return {
    render(){
      const planes=getPlanes();
      for(const node of [...grid.children])if(!planes.some(p=>String(p.instance)===node.dataset.instance))node.remove();
      for(const panel of planes){
        let item=grid.querySelector(`[data-instance="${panel.instance}"]`);
        if(!item){
          item=document.createElement('div');item.className='slice-item';item.dataset.instance=panel.instance;
          const button=document.createElement('button');button.type='button';button.className='slice-panel';button.id=`slice-panel-${panel.id}`;
          button.innerHTML=`<span class="slice-heading"><b>${panel.id}</b><span id="slice-label-${panel.id}"></span><span class="slice-state" id="slice-state-${panel.id}"></span></span><canvas id="slice-canvas-${panel.id}" width="320" height="320" aria-label="Observation ${panel.id} intensity"></canvas><span class="slice-caption"><span id="slice-position-${panel.id}"></span><span id="slice-target-${panel.id}" class="slice-target"></span><span id="slice-axis-${panel.id}"></span></span>`;
          button.onclick=()=>onSelect(panel.id);
          button.onkeydown=e=>{
            if((e.key==='Delete'||e.key==='Backspace')&&!button.disabled){e.preventDefault();onRemove(panel.id);return;}
            if(!['ArrowLeft','ArrowRight'].includes(e.key))return;
            e.preventDefault();const list=getPlanes(),index=list.findIndex(p=>p.id===panel.id),next=list[(index+(e.key==='ArrowRight'?1:list.length-1))%list.length];
            onSelect(next.id);$(`slice-panel-${next.id}`).focus();
          };
          const remove=document.createElement('button');remove.type='button';remove.className='remove-position';remove.textContent='−';remove.title=`Remove position ${panel.id}`;remove.setAttribute('aria-label',remove.title);remove.onclick=()=>onRemove(panel.id);
          item.append(button,remove);
        }
        grid.append(item);
      }
      grid.dataset.count=planes.length;$('observation-panel').dataset.count=planes.length;empty.hidden=planes.length>0;
      $('observation-layout').hidden=planes.length===0;document.dispatchEvent(new Event('position-grid-updated'));
    },
    removed(id){this.notice(id?`Removed ${id}`:'');},
    notice(text){$('removed-position').textContent=text;$('undo-position').hidden=!text;const mobile=document.getElementById('undo-mobile-position');if(mobile)mobile.hidden=!text;}
  };
}
