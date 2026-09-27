export function setupControlLayout(){
  const $=id=>document.getElementById(id);
  // Keep one instance of every control and its handlers at all breakpoints.
  const nav=$('view-switch').closest('.view-navigation');nav.id='bench-navigation';nav.dataset.view='explore';
  $('bench-wrap').after(nav);
  const controls=$('observation-controls');controls.id='position-controls';nav.append(controls);
  controls.prepend(controls.querySelector('.screen-track'));
  const notice=$('screen-status');notice.classList.add('state-notice');
  $('observation-layout').after(notice,$('cancel-screen'));
  const focus=document.createElement('details');focus.id='focus-options';
  focus.innerHTML='<summary>Fine tuning <span id="focus-offset-label">0 µm</span></summary>';
  $('focus-control').before(focus);focus.append($('focus-control'));controls.append(controls.querySelector('.slice-bar'));
  document.querySelector('.bench-toolbar').prepend($('component-summary'));
  // Finished/calculation detail belongs in settings; only actionable status is
  // repeated outside them. The original complete text remains accessible.
  const waveStatus=$('wave-status'),brief=$('wave-notice');
  const mirrorWave=()=>{
    const s=waveStatus.textContent;
    let text=s;
    if(/saved calculation$|^XZ and YZ ready/.test(s))text='';
    else if(/loading/i.test(s))text='Loading saved wave…';
    else if(/cancelled/i.test(s))text='Calculation cancelled.';
    else if(/changed|new view|click Compute/i.test(s))text='Settings changed · '+$('calculate-yz').textContent;
    brief.textContent=text;brief.hidden=!text;
  };
  new MutationObserver(mirrorWave).observe(waveStatus,{childList:true,subtree:true,characterData:true});mirrorWave();
  $('profile-dialog').addEventListener('close',()=>$('open-profile').focus({preventScroll:true}));
  // The same controls move between the desktop layout and mobile dialogs.
  const media=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)');
  const display=$('view-display-controls');
  const displayDialog=$('display-dialog');
  const sliceSettings=document.createElement('section');sliceSettings.id='slice-settings';
  sliceSettings.innerHTML='<h3>Slice settings</h3>';sliceSettings.append(display);
  const profileOption=document.createElement('label');profileOption.id='desktop-profile-option';profileOption.innerHTML='<input type="checkbox" id="enable-intensity-profile" autocomplete="off"> Enable intensity profile';sliceSettings.append(profileOption);
  const profileToggle=profileOption.querySelector('input');profileToggle.checked=false;
  profileToggle.addEventListener('change',()=>document.body.classList.toggle('profile-enabled',profileToggle.checked));
  const waveSettings=document.createElement('section');waveSettings.id='global-wave-settings';waveSettings.innerHTML='<h3>Wave settings</h3>';
  const aboutSettings=document.createElement('section');aboutSettings.id='about-settings';aboutSettings.innerHTML='<h3>About</h3>';
  const modelButton=$('model-button'),modelHome=document.createComment('mobile about');modelButton.after(modelHome);
  // Relocate the actual controls, so desktop and phone always share values.
  const referenceOptions=document.createElement('fieldset');referenceOptions.id='reference-display-options';
  referenceOptions.innerHTML='<legend>Key positions</legend>';
  for(const id of ['source-view','mask-view','pupil-view']){
    const select=$(id),label=document.querySelector(`label[for="${id}"]`);
    label.classList.remove('sr-only');const row=document.createElement('div');row.className='reference-display-row';row.append(label,select);referenceOptions.append(row);
  }
  const referenceDetails=document.createElement('details');referenceDetails.id='reference-calculation-details';
  referenceDetails.innerHTML='<summary>Calculation details</summary>';
  const detailHomes=['status','calculation-detail'].map(id=>{const node=$(id),home=document.createComment(id+' home');node.after(home);return {node,home};});
  const referenceWindows=document.createElement('div');referenceWindows.className='reference-window-details';
  const windowHomes=[['source-axis','Source'],['mask-axis','Mask'],['pupil-axis','Aperture plane'],['image-axis','Image Plane']].map(([id,name])=>{
    const node=$(id),home=document.createComment(id+' home'),row=document.createElement('div'),label=document.createElement('strong');node.after(home);label.textContent=name;row.append(label);referenceWindows.append(row);return {node,home,row};
  });
  sliceSettings.append(referenceOptions,referenceDetails);
  $('display-dialog-controls').append(sliceSettings,waveSettings,aboutSettings);
  function openSettings(){ $('app-menu').open=false;displayDialog.showModal(); }
  $('open-display-settings').onclick=openSettings;$('desktop-settings').onclick=openSettings;
  $('close-display-settings').onclick=()=>displayDialog.close();
  displayDialog.addEventListener('close',()=>{(media.matches?$('app-menu').querySelector('summary'):$('desktop-settings')).focus({preventScroll:true});});
  const wave=document.querySelector('.wave-section'),main=document.createElement('div'),sidebar=document.createElement('aside');
  main.className='wave-main';sidebar.className='wave-sidebar';sidebar.setAttribute('aria-label','Wave controls');
  main.append(...wave.children);wave.append(main,sidebar);
  const waveControls=main.querySelector('.wave-controls'),waveOptions=main.querySelector('.wave-options');
  const waveOptionsBody=waveOptions.querySelector('.wave-options-body'),waveRegion=$('wave-scope').closest('label');
  waveRegion.id='wave-region-setting';waveSettings.append(waveOptionsBody);
  const syncWaveAction=()=>{$('calculate-yz').textContent=$('wave-scope').value==='near'?'Compute near mask':'Compute full path';};
  $('wave-scope').addEventListener('change',syncWaveAction);syncWaveAction();
  const waveRegions=document.createElement('div');waveRegions.id='wave-regions';waveRegions.className='path-regions';waveRegions.setAttribute('aria-label','Wave illumination and projection regions');main.querySelector('.yz-wrap').before(waveRegions);
  const notes=document.createElement('details');notes.className='wave-notes';notes.innerHTML='<summary>Calculation details</summary>';
  for(const p of waveOptionsBody.querySelectorAll('p'))notes.append(p);
  waveOptionsBody.append(notes);
  const focusHeading=document.createElement('div');focusHeading.className='focus-heading';focusHeading.innerHTML='<span>Fine tuning <small id="tuning-anchor"></small></span><button type="button" id="return-focus" class="quiet">Reset offset</button>';
  focus.prepend(focusHeading);
  const planeSelect=$('plane'),planeLabels=[...planeSelect.options].map(o=>o.textContent);
  const shortLabels={image:'Image',mask:'Mask',near:'Mask + 1 µm',source:'Source',condenser:'Condenser',lens1:'Lens 1',pupil:'Aperture',lens2:'Lens 2',custom:'Custom'};
  function shortenPlane(){[...planeSelect.options].forEach((o,i)=>{o.textContent=media.matches&&o.selected?shortLabels[o.value]:planeLabels[i];});}
  function fullPlane(){[...planeSelect.options].forEach((o,i)=>{o.textContent=planeLabels[i];});}
  planeSelect.addEventListener('pointerdown',fullPlane);planeSelect.addEventListener('keydown',fullPlane);planeSelect.addEventListener('blur',shortenPlane);planeSelect.addEventListener('change',shortenPlane);
  const zLabel=$('slice-z').closest('label');zLabel.lastChild.textContent='';const unit=document.createElement('span');unit.className='z-unit';unit.textContent='mm';zLabel.append(unit);
  let phoneFocusOpen=false,adaptingFocus=false;
  focus.addEventListener('toggle',()=>{if(media.matches&&!adaptingFocus)phoneFocusOpen=focus.open;});
  function adapt(){
    const compact=media.matches;
    if(displayDialog.open)displayDialog.close();
    $('display-title').textContent='Settings';
    $('calculate').textContent='Compute all slices';
    referenceOptions.querySelector('legend').textContent=compact?'Key positions':'Reference positions';
    $('display-description').hidden=true;
    sliceSettings.querySelector('h3').hidden=false;
    waveSettings.hidden=false;aboutSettings.hidden=compact;
    referenceDetails.hidden=!compact;
    compact?modelHome.before(modelButton):aboutSettings.append(modelButton);
    if(compact)document.querySelector('.header-actions').prepend($('reset'));
    else document.querySelector('.workspace-heading').append($('reset'));
    for(const {node,home} of detailHomes)compact?referenceDetails.append(node):home.before(node);
    for(const {node,home,row} of windowHomes)compact?row.append(node):home.before(node);
    referenceDetails.append(referenceWindows);
    compact?main.querySelector('.wave-heading').after(waveControls):sidebar.append(waveControls);
    compact?waveSettings.querySelector('h3').after(waveRegion):waveControls.prepend(waveRegion);waveOptions.hidden=true;
    waveOptions.open=false;adaptingFocus=true;focus.open=compact?phoneFocusOpen:true;queueMicrotask(()=>adaptingFocus=false);shortenPlane();
  }
  media.addEventListener('change',adapt);adapt();
  // Programmatic changes of the position must update its compact label too.
  document.addEventListener('observation-position-change',shortenPlane);
  for(const b of document.querySelectorAll('[data-wave-section]'))b.onclick=()=>{
    $('wave-section').value=b.dataset.waveSection;$('wave-section').dispatchEvent(new Event('change'));
  };
  const syncSection=()=>document.querySelectorAll('[data-wave-section]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.waveSection===$('wave-section').value)));
  $('wave-section').addEventListener('change',syncSection);syncSection();
  $('wave-elements-toggle').onchange=()=>{
    const hidden=!$('wave-elements-toggle').checked;
    $('wave-components').toggleAttribute('hidden',hidden);
    $('wave-components').setAttribute('aria-hidden',String(hidden));
  };
}
