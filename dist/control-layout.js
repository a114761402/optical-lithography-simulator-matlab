export function setupControlLayout(){
  const $=id=>document.getElementById(id);
  // Keep one instance of every control and its handlers at all breakpoints.
  const nav=$('view-switch').closest('.view-navigation');nav.id='bench-navigation';nav.dataset.view='explore';
  $('bench-wrap').after(nav);
  const controls=$('observation-controls');controls.id='position-controls';nav.append(controls);
  controls.prepend(controls.querySelector('.screen-track'));
  const screenNotice=$('screen-status');screenNotice.classList.add('state-notice');
  $('observation-layout').after(screenNotice,$('cancel-screen'));
  const focus=document.createElement('details');focus.id='focus-options';
  focus.innerHTML='<summary>Fine tuning</summary>';
  const fineButton=document.createElement('button');fineButton.id='fine-tuning-toggle';fineButton.type='button';fineButton.className='secondary';fineButton.setAttribute('aria-controls','focus-options');fineButton.setAttribute('aria-expanded','false');fineButton.innerHTML='<span>Fine tuning</span><span id="focus-offset-label"></span><span class="fine-chevron" aria-hidden="true">⌄</span>';
  let mobileFineOpen=false;
  fineButton.onclick=()=>{mobileFineOpen=!focus.open;focus.open=mobileFineOpen;};focus.addEventListener('toggle',()=>fineButton.setAttribute('aria-expanded',String(focus.open)));
  const rangeNotice=document.createElement('p');rangeNotice.id='path-range-notice';rangeNotice.className='muted';rangeNotice.hidden=true;$('bench-wrap').after(rangeNotice);
  $('focus-control').before(focus);focus.append($('focus-control'));controls.append(controls.querySelector('.slice-bar'));
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
  const raySettings=document.createElement('section');raySettings.id='ray-settings';raySettings.innerHTML='<h3>Beam path</h3>';
  const rays=document.querySelector('[aria-label="Ray display"]');raySettings.append(rays);$('display-dialog-controls').prepend(raySettings);
  const componentSettings=document.createElement('section');componentSettings.id='component-settings';componentSettings.innerHTML='<h3>Components</h3><button type="button" id="open-components" class="secondary" aria-haspopup="dialog" aria-controls="component-dialog">Edit components</button>';raySettings.after(componentSettings);
  const menuComponents=document.createElement('button');menuComponents.type='button';menuComponents.className='quiet';menuComponents.id='menu-components';menuComponents.textContent='Components';menuComponents.setAttribute('aria-haspopup','dialog');menuComponents.setAttribute('aria-controls','component-dialog');$('open-display-settings').after(menuComponents);menuComponents.onclick=()=>{$('app-menu').open=false;$('open-components').click();};
  const resetHelp=document.createElement('p');resetHelp.className='muted reset-help';resetHelp.textContent='Top Reset restores the default optical setup and positions. Reset in Expert Mode restores positions only.';$('display-dialog-controls').append(resetHelp);$('reset').title='Restore all default settings';$('reset').setAttribute('aria-label','Reset all settings');
  const presetLabel=document.querySelector('.preset-label'),presetHome=document.createComment('preset home');presetLabel.after(presetHome);
  // The same controls move between the desktop layout and mobile dialogs.
  const media=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)');
  const display=$('view-display-controls');
  const displayDialog=$('display-dialog');
  const sliceSettings=document.createElement('section');sliceSettings.id='slice-settings';
  sliceSettings.innerHTML='<h3>Slice settings</h3>';sliceSettings.append(display);
  const profileOption=document.createElement('label');profileOption.id='desktop-profile-option';profileOption.innerHTML='<input type="checkbox" id="enable-intensity-profile" autocomplete="off"> Enable intensity profile';sliceSettings.append(profileOption);
  const profileToggle=profileOption.querySelector('input');profileToggle.checked=false;
  profileToggle.addEventListener('change',()=>document.body.classList.toggle('profile-enabled',profileToggle.checked));
  const waveSettings=document.createElement('section');waveSettings.id='global-wave-settings';waveSettings.innerHTML='<h3>Wave settings</h3><p class="muted">Wave detail controls the full-path view. High detail beside Compute controls observation slices separately.</p>';
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
  const windowHomes=[['source-axis','Pupil plane'],['mask-axis','Mask'],['pupil-axis','Aperture plane'],['image-axis','Image Plane']].map(([id,name])=>{
    const node=$(id),home=document.createComment(id+' home'),row=document.createElement('div'),label=document.createElement('strong');node.after(home);label.textContent=name;row.append(label);referenceWindows.append(row);return {node,home,row};
  });
  sliceSettings.append(referenceOptions,referenceDetails);
  $('display-dialog-controls').append(sliceSettings,waveSettings,aboutSettings,resetHelp);
  function openSettings(){ $('app-menu').open=false;displayDialog.showModal(); }
  $('open-display-settings').onclick=openSettings;$('desktop-settings').onclick=openSettings;
  $('close-display-settings').onclick=()=>displayDialog.close();
  displayDialog.addEventListener('close',()=>{if(document.querySelector('dialog[open]'))return;(media.matches?$('app-menu').querySelector('summary'):$('desktop-settings')).focus({preventScroll:true});});
  const wave=document.querySelector('.wave-section'),main=document.createElement('div'),sidebar=document.createElement('aside');
  main.className='wave-main';sidebar.className='wave-sidebar';sidebar.setAttribute('aria-label','Wave controls');
  main.append(...wave.children);wave.append(main,sidebar);
  const waveControls=main.querySelector('.wave-controls'),waveOptions=main.querySelector('.wave-options');
  const waveActionGroup=document.createElement('div');waveActionGroup.className='wave-action-group';main.querySelector('.wave-actions').before(waveActionGroup);waveActionGroup.append(main.querySelector('.wave-section-control'),main.querySelector('.wave-actions'));
  const waveOptionsBody=waveOptions.querySelector('.wave-options-body'),waveRegion=$('wave-scope').closest('label');
  waveRegion.id='wave-region-setting';waveOptionsBody.prepend(waveRegion);
  const syncWaveAction=()=>{$('calculate-yz').textContent=$('wave-scope').value==='near'?'Compute near mask':'Compute full path';};
  $('wave-scope').addEventListener('change',syncWaveAction);syncWaveAction();
  const waveRegions=document.createElement('div');waveRegions.id='wave-regions';waveRegions.className='path-regions';waveRegions.setAttribute('aria-label','Wave illumination and projection regions');main.querySelector('.yz-wrap').before(waveRegions);
  const notes=document.createElement('details');notes.className='wave-notes';notes.innerHTML='<summary>Calculation details</summary>';
  for(const p of waveOptionsBody.querySelectorAll('p'))notes.append(p);
  const more=document.createElement('details');more.className='wave-more';more.innerHTML='<summary><span>More options</span></summary>';
  for(const label of waveOptionsBody.querySelectorAll('.toggle-label'))more.append(label);
  more.append(notes);waveOptionsBody.append(more);
  const detail=$('wave-detail'),scale=$('wave-brightness');
  detail.closest('label').firstChild.textContent='Calculation detail';
  scale.closest('label').firstChild.textContent='Intensity scale';
  scale.options[2].textContent='Logarithmic';
  const detailHelp=document.createElement('p');detailHelp.className='wave-setting-help';detailHelp.textContent='Region or detail changes need Compute. Separate from slice High detail.';detail.closest('label').after(detailHelp);
  const scaleHelp=document.createElement('p');scaleHelp.id='wave-scale-help';scaleHelp.className='wave-setting-help';scale.closest('label').after(scaleHelp);scale.setAttribute('aria-describedby',scaleHelp.id);
  const updateScaleHelp=()=>{scaleHelp.textContent={local:'Each position has its own scale. Compare shape, not brightness.',shared:'One reference scale across the path. Compare relative intensity.','shared-log':'One logarithmic scale reveals weaker light.'}[scale.value]+' Display only; no recalculation.';};
  scale.addEventListener('change',updateScaleHelp);updateScaleHelp();
  const contact=document.querySelector('.site-contact'),waveLegend=main.querySelector('.wave-footer');
  waveSettings.append(waveOptionsBody);waveSettings.querySelector('p').textContent='High detail uses Fine sampling; off uses Preview. Changes take effect when you Compute.';
  const waveDetail=document.createElement('label');waveDetail.className='detail-toggle wave-detail-toggle';waveDetail.title='Wave only. Off: Preview sampling. On: Fine sampling.';
  waveDetail.innerHTML='<input id="wave-high-detail" type="checkbox" role="switch" aria-label="Wave high detail"><span>High detail</span>';
  const waveHigh=waveDetail.querySelector('input');
  const syncWaveDetail=()=>{waveHigh.checked=detail.value==='512';};
  waveHigh.addEventListener('change',()=>{detail.value=waveHigh.checked?'512':'128';detail.dispatchEvent(new Event('change',{bubbles:true}));});
  detail.addEventListener('change',syncWaveDetail);syncWaveDetail();
  const waveTitleGroup=$('wave-title').parentElement;waveTitleGroup.classList.add('wave-title-group');waveTitleGroup.append(waveDetail);

  const focusHeading=document.createElement('div');focusHeading.className='focus-heading';focusHeading.innerHTML='<span>Fine tuning <small id="tuning-anchor"></small></span><button type="button" id="return-focus" class="quiet">Reset offset</button>';
  const fineContent=document.createElement('div');fineContent.className='fine-content';fineContent.append(focusHeading,$('focus-control'));focus.append(fineContent);
  const planeSelect=$('plane'),planeLabels=[...planeSelect.options].map(o=>o.textContent);
  const shortLabels={'':'Select a position',image:'Image',mask:'Mask',near:'Mask + 1 µm',source:'Pupil',condenser:'Condenser',lens1:'Lens 1',pupil:'Aperture',lens2:'Lens 2',custom:'Custom'};
  function shortenPlane(){[...planeSelect.options].forEach((o,i)=>{o.textContent=media.matches&&o.selected?shortLabels[o.value]:planeLabels[i];});}
  function fullPlane(){[...planeSelect.options].forEach((o,i)=>{o.textContent=planeLabels[i];});}
  planeSelect.addEventListener('pointerdown',fullPlane);planeSelect.addEventListener('keydown',fullPlane);planeSelect.addEventListener('blur',shortenPlane);planeSelect.addEventListener('change',shortenPlane);
  const advanced=document.createElement('details');advanced.id='standard-position-options';
  advanced.innerHTML='<summary>Position settings</summary>';
  const positionButton=document.createElement('button');positionButton.id='standard-position-toggle';positionButton.className='secondary';positionButton.type='button';positionButton.title='Position settings';positionButton.setAttribute('aria-controls',advanced.id);positionButton.setAttribute('aria-expanded','false');positionButton.innerHTML='<span id="standard-position-label">z = 450 mm</span><span aria-hidden="true">⌄</span>';
  const observationHeading=document.querySelector('.observation-heading');observationHeading.append(positionButton);observationHeading.after(advanced);
  positionButton.onclick=()=>{advanced.open=!advanced.open;positionButton.setAttribute('aria-expanded',String(advanced.open));};
  advanced.addEventListener('toggle',()=>positionButton.setAttribute('aria-expanded',String(advanced.open)));
  const sliceBar=controls.querySelector('.slice-bar'),sliceControls=sliceBar.querySelector('.slice-controls');
  sliceControls.insertBefore(fineButton,$('show-slice'));sliceBar.after(focus);
  const computeHome=document.createComment('slice action');$('show-slice').before(computeHome);
  const action=document.createElement('div');action.className='slice-compute-action';action.append($('show-slice'));computeHome.after(action);
  function detailToggle(id){const label=document.createElement('label');label.className='detail-toggle';label.title='Off: faster sampling. On: finer sampling. Existing high detail results are reused.';label.innerHTML=`<input id="${id}" type="checkbox" role="switch" data-high-detail><span>High detail</span>`;return label;}
  action.append(detailToggle('slice-high-detail'));
  const expertDetail=detailToggle('expert-high-detail');$('calculate').after(expertDetail);
  const notice=document.createElement('p');notice.id='slice-compute-notice';notice.className='state-notice';notice.setAttribute('role','status');notice.hidden=true;controls.append(notice);
  function adaptPosition(){
    if(expertDetail.previousElementSibling!==$('reset-key-positions'))$('calculate').before(expertDetail);
    const standard=media.matches&&nav.dataset.view==='explore';advanced.hidden=!standard;positionButton.hidden=!standard;action.hidden=media.matches&&!standard;
    if(standard){
      if(focus.parentElement!==advanced)advanced.append(sliceBar,focus);if(action.parentElement!==$('profile-menu'))$('profile-menu').prepend(action);action.after($('cancel-screen'),notice);
    }else{
      if(focus.parentElement!==controls)controls.append(sliceBar,focus);
      const actionHost=media.matches?sliceControls:document.querySelector('.observation-toolbar');
      if(actionHost&&action.parentElement!==actionHost)actionHost.append(action);
      if(!media.matches)focus.open=true;
      if(media.matches){$('calculate').closest('.calculation-actions').after($('cancel-screen'),notice);}
      else{sliceBar.after($('cancel-screen'),notice);}
    }
    $('standard-position-label').textContent=$('slice-z').value?'z = '+Number(Number($('slice-z').value).toFixed(3))+' mm':'';
  }
  document.addEventListener('position-grid-updated',adaptPosition);
  document.addEventListener('position-view-change',adaptPosition);
  document.addEventListener('observation-position-change',adaptPosition);
  const zLabel=$('slice-z').closest('label');zLabel.lastChild.textContent='';const unit=document.createElement('span');unit.className='z-unit';unit.textContent='mm';zLabel.append(unit);

  function adapt(){
    const compact=media.matches;
    if(displayDialog.open)displayDialog.close();
    $('display-title').textContent='Settings';
    $('calculate').textContent='Compute all slices';
    referenceOptions.querySelector('legend').textContent='Key positions';
    $('display-description').hidden=true;
    sliceSettings.querySelector('h3').hidden=false;
    waveSettings.hidden=false;aboutSettings.hidden=compact;
    referenceDetails.hidden=!compact;
    compact?modelHome.before(modelButton):aboutSettings.append(modelButton);
    if(compact)(matchMedia('(max-width:350px)').matches?document.querySelector('.workspace-heading'):document.querySelector('.header-actions')).append($('reset'));
    if(compact)document.querySelector('.header-actions').append($('app-menu'));
    else document.querySelector('.bench-toolbar').prepend(presetLabel,$('reset'));
    if(compact)presetHome.before(presetLabel);
    raySettings.hidden=compact;componentSettings.hidden=!compact;
    for(const {node,home} of detailHomes)compact?referenceDetails.append(node):home.before(node);
    for(const {node,home,row} of windowHomes)compact?row.append(node):home.before(node);
    referenceDetails.append(referenceWindows);
    sidebar.append(waveControls);
    compact?waveOptionsBody.prepend(waveRegion):waveControls.prepend(waveRegion);
    compact?main.append(waveLegend):sidebar.append(waveLegend);
    compact?wave.append(contact):sidebar.append(contact);waveControls.hidden=compact;waveOptions.hidden=true;
    waveOptions.open=false;focus.open=compact?mobileFineOpen:true;shortenPlane();adaptPosition();
  }
  media.addEventListener('change',adapt);matchMedia('(max-width:350px)').addEventListener('change',adapt);adapt();
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
