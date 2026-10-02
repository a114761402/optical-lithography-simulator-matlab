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
    // Calculation progress already lives in the plot and Compute button.
    if(/saved calculation$|^XZ and YZ ready|^Wave path · \d+%$|^Calculating both XZ and YZ/.test(s))text='';
    else if(/loading/i.test(s))text='Loading saved wave…';
    else if(/cancelled/i.test(s))text='Calculation cancelled.';
    else if(/changed|new view|No calculation|click Compute/i.test(s))text='Compute to update this view.';
    brief.textContent=text;brief.hidden=!text;
  };
  new MutationObserver(mirrorWave).observe(waveStatus,{childList:true,subtree:true,characterData:true});mirrorWave();
  $('profile-dialog').addEventListener('close',()=>$('open-profile').focus({preventScroll:true}));
  const raySettings=document.createElement('section');raySettings.id='ray-settings';raySettings.innerHTML='<h3>Beam path</h3>';
  const rays=document.querySelector('[aria-label="Ray display"]');raySettings.append(rays);$('display-dialog-controls').prepend(raySettings);
  const componentSettings=document.createElement('section');componentSettings.id='component-settings';componentSettings.innerHTML='<h3>Components</h3><button type="button" id="open-components" class="secondary" aria-haspopup="dialog" aria-controls="component-dialog">Edit components</button>';raySettings.after(componentSettings);
  const tuningSettings=document.createElement('section');tuningSettings.id='tuning-settings';
  tuningSettings.innerHTML='<details><summary>Position tuning</summary><div class="tuning-setting-fields"><label>Slow drag<select id="tuning-slow-speed"><option value="0.5">0.5×</option><option value="1" selected>1× · Default</option><option value="2">2×</option></select></label><label>Fast drag<select id="tuning-fast-speed"><option value="0.5">0.5×</option><option value="1" selected>1× · Default</option><option value="1.5">1.5×</option></select></label><label>Glide<select id="tuning-glide"><option value="0">Off</option><option value="0.5">Short</option><option value="1" selected>Default</option></select></label></div></details>';
  componentSettings.after(tuningSettings);

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
  const projectionDisplay=document.createElement('label');
  projectionDisplay.innerHTML='Projection display<select id="projection-display"><option value="lenses" selected>Within lens outlines</option><option value="full">Full computed field</option></select>';
  const projectionHelp=document.createElement('p');projectionHelp.className='wave-setting-help';projectionHelp.id='projection-display-help';projectionHelp.textContent='Display crop only. Hidden light is not zero; calculations stay unchanged.';
  projectionDisplay.querySelector('select').setAttribute('aria-describedby',projectionHelp.id);
  const transmitted=document.createElement('label');transmitted.className='projection-transmitted-toggle';
  transmitted.innerHTML='<input type="checkbox" id="projection-transmitted-only" checked> Aperture-transmitted projection';
  const transmittedHelp=document.createElement('p');transmittedHelp.className='wave-setting-help';transmittedHelp.textContent='Illumination shows the actual incident field. Projection shows the aperture-selected reconstruction inside illustrated outlines. Hidden light is not a calculated zero. Fine presets update automatically; edited settings need Compute.';
  projectionDisplay.querySelector('select').disabled=true;
  waveSettings.append(transmitted,transmittedHelp,projectionDisplay,projectionHelp);
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
  $('display-dialog-controls').append(tuningSettings,sliceSettings,waveSettings,aboutSettings,resetHelp);
  function openSettings(){ $('app-menu').open=false;displayDialog.showModal(); }
  $('open-display-settings').onclick=openSettings;$('desktop-settings').onclick=openSettings;
  $('close-display-settings').onclick=()=>displayDialog.close();
  displayDialog.addEventListener('close',()=>{if(document.querySelector('dialog[open]'))return;(media.matches?$('app-menu').querySelector('summary'):$('desktop-settings')).focus({preventScroll:true});});
  const wave=document.querySelector('.wave-section'),main=document.createElement('div'),sidebar=document.createElement('aside');
  main.className='wave-main';sidebar.className='wave-sidebar';sidebar.setAttribute('aria-label','Wave controls');
  main.append(...wave.children);wave.append(main,sidebar);
  wave.prepend(main.querySelector('.wave-heading'));
  const waveControls=main.querySelector('.wave-controls'),waveOptions=main.querySelector('.wave-options');
  const waveActionGroup=document.createElement('div');waveActionGroup.className='wave-action-group';wave.querySelector('.wave-actions').before(waveActionGroup);waveActionGroup.append(main.querySelector('.wave-section-control'),wave.querySelector('.wave-actions'));
  const waveOptionsBody=waveOptions.querySelector('.wave-options-body'),waveRegion=$('wave-scope').closest('label');
  waveRegion.id='wave-region-setting';waveOptionsBody.prepend(waveRegion);
  const syncWaveAction=()=>{$('calculate-yz').textContent='Compute';};
  $('wave-scope').addEventListener('change',syncWaveAction);syncWaveAction();
  const waveRegions=document.createElement('div');waveRegions.id='wave-regions';waveRegions.className='path-regions';waveRegions.setAttribute('aria-label','Wave illumination and projection regions');main.querySelector('.yz-wrap').before(waveRegions);
  const notes=document.createElement('details');notes.className='wave-notes';notes.innerHTML='<summary>Calculation details</summary>';
  for(const p of waveOptionsBody.querySelectorAll('p'))notes.append(p);
  const more=document.createElement('details');more.className='wave-more';more.innerHTML='<summary><span>More options</span></summary>';
  for(const label of waveOptionsBody.querySelectorAll('.toggle-label'))more.append(label);
  more.append(notes);waveOptionsBody.append(more);
  const componentOption=document.createElement('label');componentOption.className='detail-toggle desktop-wave-components';
  componentOption.innerHTML='<input id="desktop-wave-elements" type="checkbox" role="switch"><span>Show components</span>';
  const componentSwitch=componentOption.querySelector('input'),componentsToggle=$('wave-elements-toggle');
  componentSwitch.checked=componentsToggle.checked;
  componentSwitch.addEventListener('change',()=>{componentsToggle.checked=componentSwitch.checked;componentsToggle.dispatchEvent(new Event('change',{bubbles:true}));});
  componentsToggle.addEventListener('change',()=>{componentSwitch.checked=componentsToggle.checked;});
  waveControls.append(componentOption);
  const detail=$('wave-detail'),scale=$('wave-brightness');
  detail.closest('label').firstChild.textContent='Calculation detail';
  scale.closest('label').firstChild.textContent='Intensity scale';
  scale.options[2].textContent='Logarithmic';
  const detailHelp=document.createElement('p');detailHelp.className='wave-setting-help';detailHelp.textContent='Saved Fine presets load automatically. Other views need Compute. Separate from slice High detail.';detail.closest('label').after(detailHelp);
  const scaleHelp=document.createElement('p');scaleHelp.id='wave-scale-help';scaleHelp.className='wave-setting-help';scale.closest('label').after(scaleHelp);scale.setAttribute('aria-describedby',scaleHelp.id);
  const updateScaleHelp=()=>{scaleHelp.textContent={local:'Each position has its own scale. Compare shape, not brightness.',shared:'One reference scale across the path. Compare relative intensity.','shared-log':'One logarithmic scale reveals weaker light.'}[scale.value]+' Display only; no recalculation.';};
  scale.addEventListener('change',updateScaleHelp);updateScaleHelp();
  const contact=document.querySelector('.site-contact'),waveLegend=main.querySelector('.wave-footer');
  waveSettings.append(waveOptionsBody);waveSettings.querySelector('p').textContent='Presets load saved High detail results. Other detail levels need Compute.';
  const waveDetail=document.createElement('label');waveDetail.className='detail-toggle wave-detail-toggle';waveDetail.title='Wave only. Off: Preview sampling. On: Fine sampling.';
  waveDetail.innerHTML='<input id="wave-high-detail" type="checkbox" role="switch" aria-label="Wave high detail"><span>High detail</span>';
  const waveHigh=waveDetail.querySelector('input');
  const syncWaveDetail=()=>{waveHigh.checked=detail.value==='512';};
  waveHigh.addEventListener('change',()=>{detail.value=waveHigh.checked?'512':'128';detail.dispatchEvent(new Event('change',{bubbles:true}));});
  detail.addEventListener('change',syncWaveDetail);syncWaveDetail();
  const waveTitleGroup=$('wave-title').parentElement;waveTitleGroup.classList.add('wave-title-group');waveActionGroup.insertBefore(waveDetail,wave.querySelector('.wave-actions'));

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
  const tuningRow=document.createElement('div');tuningRow.id='mobile-tuning-row';
  const planeGroup=document.createElement('div');planeGroup.className='mobile-plane';
  const identity=document.createElement('b');identity.id='mobile-position-id';planeGroup.append(identity);
  const scrubber=document.createElement('div');scrubber.id='relative-tuning';scrubber.tabIndex=0;scrubber.setAttribute('role','slider');scrubber.setAttribute('aria-label','Position tuning. Drag slowly for fine adjustment, quickly for coarse adjustment. Arrow keys: 1 micrometre; Shift: 1 millimetre.');scrubber.innerHTML='<span class="tuning-ticks" aria-hidden="true"></span><span class="tuning-center" aria-hidden="true"></span>';
  tuningRow.append(scrubber);controls.append(tuningRow);
  const zLabel=$('slice-z').closest('label');
  const positionFields=document.createElement('div');positionFields.className='mobile-position-fields';positionFields.append(planeGroup);
  $('reference-title').innerHTML='<span class="wide-label">Key positions</span><span class="phone-label">Options</span>';
  const modeHome=document.createComment('mode home');$('view-switch').before(modeHome);
  const presetRow=document.createElement('div');presetRow.id='mobile-preset-row';presetHome.before(presetRow);
  const presetNames=[...$('preset').options].map(o=>o.textContent);
  function fullPreset(){[...$('preset').options].forEach((o,i)=>o.textContent=presetNames[i]);}
  function shortPreset(){[...$('preset').options].forEach((o,i)=>o.textContent=media.matches&&o.selected?({'':'Custom',default:'Preset',filtering:'4f filtering',diffraction:'Diffraction',annular:'Annular',dipole:'Dipole'}[o.value]):presetNames[i]);}
  $('preset').setAttribute('aria-label','Experiment preset');
  $('preset').addEventListener('pointerdown',fullPreset);$('preset').addEventListener('keydown',fullPreset);$('preset').addEventListener('blur',shortPreset);$('preset').addEventListener('change',shortPreset);
  function adaptPosition(){
    $('calculate').before(expertDetail);
    const heading=$('reference-preset-row'),mobile=media.matches,standard=mobile&&nav.dataset.view==='explore';
    const regions=$('beam-regions'),benchWrap=$('bench-wrap');
    if(standard){if(regions.parentElement!==benchWrap)benchWrap.append(regions);}
    else if(regions.parentElement===benchWrap)benchWrap.before(regions);
    advanced.hidden=true;positionButton.hidden=true;action.hidden=mobile&&!standard;
    if(focus.parentElement!==controls)controls.append(focus);
    if(sliceBar.parentElement!==controls)controls.append(sliceBar);
    if(mobile){
      if($('add-mobile-position')&&$('position-edit-actions')&&$('add-mobile-position').parentElement!==$('position-edit-actions'))$('position-edit-actions').append($('add-mobile-position'));
      if($('add-position')&&$('add-position').parentElement!==document.querySelector('.observation-toolbar'))document.querySelector('.observation-toolbar').append($('add-position'));
      if(planeSelect.parentElement!==planeGroup)planeGroup.append(planeSelect);
      if(standard){if(planeGroup.parentElement!==positionFields)positionFields.prepend(planeGroup);}
      else if(planeGroup.parentElement!==tuningRow)tuningRow.append(planeGroup);
      if(zLabel.parentElement!==positionFields)positionFields.append(zLabel);
      const positionHeading=standard?document.querySelector('.observation-heading'):$('reference-title').parentElement;
      if(positionFields.parentElement!==positionHeading)positionHeading.append(positionFields);
      const editActions=$('position-edit-actions');
      if(editActions&&editActions.parentElement!==$('reference-title').parentElement)$('reference-title').parentElement.append(editActions);
      if(sliceControls.parentElement!==sliceBar)sliceBar.append(sliceControls);
      if(action.parentElement!==$('profile-menu'))$('profile-menu').prepend(action);
      if($('view-switch').parentElement!==presetRow)presetRow.append(presetLabel,$('view-switch'));
      if(standard)action.after(notice);else $('calculate').closest('.calculation-actions').after(notice);
    }else{
      const editActions=$('position-edit-actions');
      if($('add-mobile-position')&&$('mobile-position-actions')&&$('add-mobile-position').parentElement!==$('mobile-position-actions'))$('mobile-position-actions').append($('add-mobile-position'));
      if($('add-position')&&editActions&&$('add-position').parentElement!==editActions)editActions.append($('add-position'));
      if(planeSelect.parentElement!==sliceControls)sliceControls.prepend(planeSelect,zLabel);
      const editTitle=nav.dataset.view==='explore'?$('observation-title'):$('reference-title');
      if(editActions&&editActions.parentElement!==editTitle.parentElement)editTitle.after(editActions);
      if(heading&&sliceControls.parentElement!==heading)heading.append(sliceControls);
      const host=document.querySelector('.observation-toolbar');if(host&&action.parentElement!==host)host.append(action);
      if($('view-switch').parentElement!==modeHome.parentElement)modeHome.before($('view-switch'));
      focus.open=true;focus.before(sliceBar);sliceBar.after(notice);
    }
    tuningRow.hidden=!mobile;positionFields.hidden=!mobile;syncPositionLabel();shortPreset();
  }
  function syncPositionLabel(){
    identity.textContent=nav.dataset.view==='fixed'?$('active-observation')?.querySelector('b')?.textContent||'—':'';
    $('standard-position-label').textContent=$('slice-z').value?'z = '+Number(Number($('slice-z').value).toFixed(3))+' mm':'';
  }
  document.addEventListener('position-grid-updated',adaptPosition);
  document.addEventListener('position-view-change',adaptPosition);
  // Value changes must not reparent a native range during an active drag.
  document.addEventListener('observation-position-change',syncPositionLabel);
  zLabel.lastChild.textContent='';const unit=document.createElement('span');unit.className='z-unit';unit.textContent='mm';zLabel.append(unit);

  function adapt(){
    const compact=media.matches;
    if(displayDialog.open)displayDialog.close();
    $('display-title').textContent=compact?'General':'Settings';
    $('model-dialog').querySelector('h2').textContent=compact?'About':'How this bench works';
    $('calculate').textContent='Compute';
    referenceOptions.querySelector('legend').textContent='Key positions';
    $('display-description').hidden=true;
    sliceSettings.querySelector('h3').hidden=false;
    waveSettings.hidden=false;aboutSettings.hidden=compact;
    referenceDetails.hidden=!compact;
    compact?modelHome.before(modelButton):aboutSettings.append(modelButton);
    if(compact)document.querySelector('.header-actions').append($('reset'));
    if(compact)document.querySelector('.header-actions').append($('app-menu'));
    else document.querySelector('.bench-toolbar').prepend(presetLabel,$('reset'));
    if(compact)presetRow.prepend(presetLabel);
    raySettings.hidden=false;componentSettings.hidden=!compact;
    for(const {node,home} of detailHomes)compact?referenceDetails.append(node):home.before(node);
    for(const {node,home,row} of windowHomes)compact?row.append(node):home.before(node);
    referenceDetails.append(referenceWindows);
    sidebar.append(waveControls);
    compact?waveOptionsBody.prepend(waveRegion):waveControls.prepend(waveRegion);
    compact?main.append(waveLegend):sidebar.append(waveLegend);
    compact?$('model-dialog').querySelector('.dialog-header').after(contact):sidebar.append(contact);waveControls.hidden=compact;waveOptions.hidden=true;
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
