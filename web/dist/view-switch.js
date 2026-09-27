// One shared results workspace on desktop, tablet and phone.
export function setupViewSwitch(){
  const byId=id=>document.getElementById(id),workspace=byId('view-workspace');
  const media=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)');
  const bar=byId('view-switch'),tabs=[byId('view-explore'),byId('view-fixed')];
  const panels=[byId('observation-panel'),byId('fixed-panel')];
  const display=byId('view-display-controls');
  const controls=[byId('quality').closest('label'),byId('brightness').closest('label'),byId('brightness-help')];
  workspace.classList.add('tabbed-views');
  workspace.insertBefore(panels[0],panels[1]);
  controls.forEach(control=>display.append(control));
  panels.forEach((panel,i)=>{panel.setAttribute('role','tabpanel');panel.setAttribute('aria-labelledby',tabs[i].id);panel.removeAttribute('aria-label');panel.tabIndex=0;});
  let selected=0,phoneSelected=0,editing=false,start=null,ignoreClickUntil=0;
  function select(index,{focus=false}={}){
    if(media.matches)phoneSelected=index;else index=0;
    selected=index;workspace.dataset.view=index?'fixed':'explore';byId('bench-navigation').dataset.view=workspace.dataset.view;byId('position-controls').hidden=index!==0&&!editing;
    document.body.classList.toggle('editing-key-positions',media.matches&&index===1&&editing);
    const grid=byId('observation-grid');if(grid){if(media.matches&&index===1)byId('mobile-key-grid-host').append(grid);else byId('observation-layout').before(grid);}
    document.dispatchEvent(new CustomEvent('position-view-change',{detail:{key:media.matches&&index===1,editing}}));
    tabs.forEach((tab,i)=>{tab.setAttribute('aria-selected',String(i===index));tab.tabIndex=i===index?0:-1;panels[i].hidden=i!==index;});
    if(focus)tabs[index].focus({preventScroll:true});
  }
  function adapt(){
    const compact=media.matches,active=document.activeElement;
    workspace.classList.toggle('compact-views',compact);
    const layout=panels[0].querySelector('.observation-layout'),figure=panels[0].querySelector('.observation-field');
    layout.prepend(figure);
    bar.hidden=!compact;
    panels.forEach((panel,i)=>{panel.setAttribute('role',compact?'tabpanel':'region');panel.setAttribute('aria-labelledby',compact?tabs[i].id:i?'reference-title':'observation-title');});
    select(compact?phoneSelected:0);
    if(compact&&panels[1-selected].contains(active))tabs[selected].focus({preventScroll:true});
  }
  tabs.forEach((tab,i)=>tab.addEventListener('click',()=>{if(performance.now()>=ignoreClickUntil)select(i);}));
  bar.addEventListener('keydown',event=>{
    if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;
    event.preventDefault();select(event.key==='Home'?0:event.key==='End'?1:1-selected,{focus:true});
  });
  bar.addEventListener('pointerdown',event=>{if(!event.isPrimary||event.button!==0)return;start={x:event.clientX,y:event.clientY};});
  bar.addEventListener('pointerup',event=>{
    if(!start)return;const dx=event.clientX-start.x,dy=event.clientY-start.y;start=null;
    if(Math.abs(dx)>32&&Math.abs(dx)>Math.abs(dy)*1.5){ignoreClickUntil=performance.now()+400;select(dx>0?1:0);}
  });
  bar.addEventListener('pointercancel',()=>{start=null;});
  media.addEventListener('change',adapt);adapt();
  return {showObservation(){select(0);},get keyView(){return media.matches&&selected===1;},get editing(){return editing;},setEditing(value){editing=value;select(selected);},adapt};
}
