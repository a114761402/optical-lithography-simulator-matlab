import {setupRelativeTuning} from './relative-tuning.js?v=20260929-layout';
import {PositionHistory,positionSnapshot} from './position-history.js?v=20260928-history';
import {comparisonScale,scaleBar} from './slice-comparison.js?v=20260928-tuning';
import {DetailPreferences,sameSlice,bestSlice} from './quality-policy.js?v=20260930-interpolate';
import {sampleIntensity} from './image-sampling.js?v=20260927-positions3';
import {presetDefinition,presetParams,matchingPreset} from './presets.js?v=20260927-positions3';
import {loadPresetCache} from './preset-cache.js?v=20260927-positions3';
import {validate,geometry,sourceValue,sourceExtent,pupilValue,makeMask,maximum} from './optics.js?v=20260927-positions3';
import {centerCuts,brightness} from './wave.js?v=20260927-positions3';
import {renderWavePixels} from './wave-display.js?v=20261002-projection-display';
import {QUALITY,waveParameters} from './quality.js?v=20260927-positions3';
import {waveCacheKey} from './cache.js?v=20260927-positions3';
import {setupViewSwitch} from './view-switch.js?v=20260928-tuning';
import {setupControlLayout} from './control-layout.js?v=20261002-progress-notice';
import {waveComponentSVG} from './wave-components.js?v=20260927-overview';
import {compactBench} from './compact-bench.js?v=20260928-tuning';
import {regionMarkup,waveView} from './path-layout.js?v=20260927-position-fit';
import {desktopBench} from './desktop-bench.js?v=20260927-overview';
import {setupBenchEditor} from './bench-editor.js?v=20260927-mobile-align';
import {palette,lightRegion,RAY_BLUE,RAY_YELLOW} from './light-palette.js?v=20260927-positions3';
import {createPlane,appendPositionGroup,duplicatePositionAfter,relabelPositions,interpolatePositions,markedPositions,quantizePosition,SliceBatch,createPlanes,PLANE_NAMES,tuningBase,observationZ,setObservation,tuneObservation,sliceKey,sliceRequest,acceptsSlice,screenSnapshot,referenceScreens,SliceCache} from './observation-state.js?v=20260930-interpolate';
import {setupObservationUI} from './observation-ui.js?v=20260929-card-actions';
import {setupScreenDrag} from './screen-drag.js?v=20260930-interpolate';
import {setupSliceShare} from './slice-share.js?v=20260927-controls1';
import {SerialJobs} from './serial-jobs.js?v=20260927-positions3';
import {restorePositions,hydratePositions,atReferencePositions,referenceDisplayMode} from './reference-positions.js?v=20260930-interpolate';
const $=id=>document.getElementById(id),NS='http://www.w3.org/2000/svg';
setupControlLayout();
const sliceShare=setupSliceShare();
const viewTabs=setupViewSwitch();
const details=new DetailPreferences();
const compactMedia=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)');
let p=presetParams('default'),selected='pupil',rayMode='principal',result=null,screenResult=null,screenRevision=-1,yzResult=null,busy=false,revision=0,calculatedRevision=-1,activeJob=null;
let dragLayout=null,tuningInteraction=null;
let benchFrame=null,planes=createPlanes(),activeId=matchMedia('(max-width:780px), (max-width:1000px) and (max-height:600px)').matches?'D':null,lastPosition=450,batch=null;
let interpolationMode=false,interpolationEndpoints=[];
const positionHistory=new PositionHistory(positionSnapshot(planes,activeId,lastPosition));
let positionGestureStart=null,positionGestureSource=null;
const activePlane=()=>planes.find(panel=>panel.id===activeId),sliceCache=new SliceCache();
const screenParams=()=>({...p,...quality(),defocusUm:0});
const jobs=new SerialJobs(()=>setBusy());
const observationUI=setupObservationUI(()=>planes,{onSelect:selectInterpolationOrObservation,onRemove:removeObservation,onDuplicate:duplicateObservation,onAdd:addObservation,onUndo:undoObservation,onReference:useReferencePositions,onZoom:id=>{selectObservation(id);if(!screenResult)return;zoomReturn=$('zoom-position-'+id);$('observation-zoom-dialog').showModal();drawObservationZoom();}});observationUI.render();
let zoomReturn=null;
let imageZoom=1,fixedPreviewMemo=null,fixedImageSaved=null;
const fieldEdits={z:false,offset:false};
let waveRequest=0,waveLoading=true,presetTicket=0,waveProgress=1;
$('quality').value='fine';
const keyHost=document.createElement('div');keyHost.id='mobile-key-grid-host';document.querySelector('#fixed-panel .results-heading').after(keyHost);
const keyActions=document.querySelector('#fixed-panel .calculation-actions');
for(const [id,label,action] of [['reset-key-positions','Reset',useReferencePositions]]){const b=document.createElement('button');b.id=id;b.textContent=label;b.className='secondary';b.onclick=action;if(id==='reset-key-positions'){b.title='Restore default positions only';b.setAttribute('aria-label','Reset key positions');}keyActions.insertBefore(b,$('calculate'));}
const presetInfo=document.createElement('section');presetInfo.id='preset-info';$('display-dialog-controls').prepend(presetInfo);
const smoothing=document.createElement('label');smoothing.id='smoothing-option';smoothing.innerHTML='<input type="checkbox" id="smooth-intensity" checked> Smooth intensity display';$('slice-settings').append(smoothing);$('smooth-intensity').onchange=()=>{drawResults();drawScreen();drawBench();renderInspectorPreview();};

const comparisonOptions=document.createElement('fieldset');comparisonOptions.id='illumination-comparison';
comparisonOptions.innerHTML='<legend>Image display</legend><label>Physical scale<select id="image-scale"><option value="auto">Auto-fit each image</option><option value="illumination" selected>Shared illumination</option><option value="fixed">Fixed all images</option></select></label><label id="fixed-width-label" hidden>Image width (mm)<input id="fixed-image-width" type="number" min="0.001" max="1000" step="any" value="40"></label><label><input type="checkbox" id="show-scale-bars" checked> Show scale bars</label><label><input type="checkbox" id="show-image-details"> Show image details</label><label><input type="checkbox" id="compare-intensity"> Same illumination brightness</label><p class="muted">Physical scale applies to intensity images. Source weights and aperture openings use normalized coordinates.</p><label>Desktop fine range (± mm)<input id="fine-range" type="number" min="0.001" max="100" step="0.001" value="2.5"></label>';
$('slice-settings').append(comparisonOptions);
function updateDisplayOptions(){
  $('fixed-width-label').hidden=$('image-scale').value!=='fixed';
  document.body.classList.toggle('show-image-details',$('show-image-details').checked);
  syncFocus();drawScreen();
}
for(const id of ['image-scale','compare-intensity','show-scale-bars','show-image-details'])$(id).onchange=updateDisplayOptions;
for(const [id,fallback]of [['fixed-image-width',40],['fine-range',2.5]])$(id).onchange=()=>{
  if(!$(id).checkValidity()||!Number.isFinite(Number($(id).value))||Number($(id).value)<=0)$(id).value=fallback;
  updateDisplayOptions();
};
const visibleCards=new WeakSet();
const cardObserver=new IntersectionObserver(entries=>{for(const entry of entries){if(entry.isIntersecting){visibleCards.add(entry.target);const panel=planes.find(p=>'slice-canvas-'+p.id===entry.target.id);if(panel)paintScreen(entry.target,panel);}else visibleCards.delete(entry.target);}},{rootMargin:'200px'});
const observedCards=new Set();
function observeCards(){for(const canvas of observedCards)if(!canvas.isConnected){cardObserver.unobserve(canvas);observedCards.delete(canvas);}for(const canvas of document.querySelectorAll('#observation-grid canvas'))if(!observedCards.has(canvas)){observedCards.add(canvas);cardObserver.observe(canvas);}}
document.addEventListener('position-grid-updated',observeCards);observeCards();
const mobilePositionActions=document.createElement('div');mobilePositionActions.id='mobile-position-actions';
for(const [id,label,action]of [['undo-mobile-position','Undo',undoObservation],['add-mobile-position','+',addObservation]]){const button=document.createElement('button');button.id=id;button.className='secondary';button.textContent=label;button.onclick=action;if(id.startsWith('undo'))button.hidden=true;else{button.title='Add two comparison positions';button.setAttribute('aria-label','Add two positions');}mobilePositionActions.append(button);}
const mobileKeyTitle=document.createElement('span');mobileKeyTitle.className='mobile-key-title';mobileKeyTitle.textContent='Key Positions';mobilePositionActions.prepend(mobileKeyTitle);
keyActions.prepend(mobilePositionActions);
const interpolateButton=document.createElement('button');interpolateButton.id='interpolate-positions';interpolateButton.type='button';interpolateButton.className='secondary';interpolateButton.textContent='Interpolate';interpolateButton.title='Set positions between two selected slices to even steps';interpolateButton.setAttribute('aria-label','Interpolate between two key positions');interpolateButton.setAttribute('aria-pressed','false');interpolateButton.onclick=toggleInterpolation;
const interpolateGuide=document.createElement('p');interpolateGuide.id='interpolate-guide';interpolateGuide.setAttribute('role','status');interpolateGuide.hidden=true;
keyActions.insertBefore(interpolateButton,$('calculate'));keyActions.append(interpolateGuide);
const positionEditActions=document.createElement('div');positionEditActions.id='position-edit-actions';
keyActions.insertBefore(positionEditActions,$('calculate'));
positionEditActions.append($('reset-key-positions'));
$('reset-key-positions').textContent='Reset';$('reset-key-positions').setAttribute('aria-label','Reset positions');
$('slice-settings').append($('undo-mobile-position'));
const historyIcon='<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false"><path d="M8 5 3 10l5 5M3 10h10a6 6 0 1 1-6 6"/></svg>';
for(const [id,label,action]of [['undo-position-edit','Undo',undoPositionEdit],['redo-position-edit','Redo',redoPositionEdit]]){
  const button=document.createElement('button');button.id=id;button.type='button';button.className='secondary position-history-action';button.innerHTML=historyIcon;button.title=label+' position edit';button.setAttribute('aria-label',label+' position edit');button.onclick=action;
  positionEditActions.append(button);
}
if(!document.body.classList.contains('phone-bench'))positionEditActions.append($('add-position'));
syncPositionHistoryButtons();
document.dispatchEvent(new Event('position-grid-updated'));

function updatePresetInfo(){const choice=matchingPreset(p);presetInfo.innerHTML='<h3>Preset</h3><p>'+ (choice?choice.name:'Custom settings')+'</p><p>'+(choice?choice.description:'Your edited optical parameters.')+'</p>'+(choice?.url?'<a target="_blank" rel="noopener" href="'+choice.url+'">'+choice.source+'</a>':'')+'<p class="muted">Literature-inspired teaching examples; ideal scalar optics, not a reproduction of a published instrument.</p>';}
function requestedWaveKey(){return waveCacheKey(waveParameters(p,$('wave-detail').value),$('wave-scope').value);}
async function restoreDefaultWave(){
  const choice=matchingPreset(p),ticket=++waveRequest,key=requestedWaveKey();
  if(!choice||$('wave-scope').value!=='full'||Number($('wave-detail').value)!==512){waveLoading=false;return;}
  waveLoading=true;$('wave-status').textContent='Loading saved Fine wave…';
  try{const saved=await loadPresetCache(choice.id);if(ticket!==waveRequest||key!==requestedWaveKey())return;waveLoading=false;yzResult=saved.wave;drawYZ();$('wave-status').textContent='Fine · saved calculation';}
  catch(error){console.warn('Saved wave:',error.message);if(ticket!==waveRequest)return;waveLoading=false;drawYZ();$('wave-status').textContent='Saved wave unavailable · Compute full path to calculate locally.';}
}
async function restorePresetSlices(id){
  const ticket=++presetTicket,version=revision;
  try{const saved=await loadPresetCache(id);if(ticket!==presetTicket||version!==revision||matchingPreset(p)?.id!==id)return;
    for(const r of saved.slices)rememberSlice(sliceKey(r.params,r.z),r);
    hydratePositions(planes,geometry(p),screenParams(),sliceCache,revision);drawScreen();setBusy();status('Fine · saved key positions');drawBench();renderInspectorPreview();
  }catch(error){console.warn('Saved slices:',error.message);if(ticket===presetTicket&&version===revision){status('Saved slices unavailable · calculating locally.');calculate();}}
}
const components=[['source','Source pupil','Source pupil','Source pupil shape is the illumination pupil: a distribution of independent emitters, separate from the projection aperture.'],['condenser','Condenser','Condenser lens','Collects the source light and illuminates the mask.'],['mask','Mask','Patterned mask','The openings decide which parts of the light pass through.'],['lens1','Lens 1','First relay lens','Brings the mask’s spatial frequencies to the projection aperture plane.'],['pupil','Aperture','Projection aperture','A separate physical opening in the projection system passes some diffracted light and blocks the rest.'],['lens2','Lens 2','Second relay lens','Recombines the transmitted field into a reduced, inverted image.'],['image','Image','Fixed image plane','The ideal image forms here. This reference stays fixed when you move the observation screen.']];
const sources=['Point','Circular','Square','Annular','Dipole X','Dipole Y','Quadrupole','Freeform'],masks=['1D Grating','2D Grating','Circular Aperture','Square Aperture','Diamond Aperture','Annular Aperture','Cross'],pupils=['Circular','Annular','Square','Diamond','Horizontal Slit','Vertical Slit','Freeform'];
const fmt=(n,d=3)=>Number(n.toFixed(d)).toString();
const benchEditor=setupBenchEditor({components,onSelect(key){selected=key;renderInspector();drawBench();},onLayout(){drawBench();syncScreen();drawScreen();setBusy();}});
function updateComponentSummary(){const g=geometry(p),detail={source:`${p.sourceType} · ${fmt(p.wavelengthNm)} nm`,condenser:`f = ${fmt(p.condenserFocalMm)} mm`,mask:p.maskType,lens1:`f = ${fmt(p.f1Mm)} mm`,pupil:`${p.lensType} · NA ${fmt(p.projNA)}`,lens2:`f = ${fmt(g.f2)} mm`,image:`z = ${fmt(g.image)} mm`};benchEditor.update(selected,detail[selected]);}
function status(s){$('status').textContent=s;if(activeJob==='yz'||s.includes('cancelled')||s.includes('changed')||s.includes('stopped'))$('wave-status').textContent=s;}
function currentZ(){return activePlane()?observationZ(activePlane(),geometry(p)):lastPosition;}
function loadActiveScreen(){screenResult=activePlane()?.result||null;screenRevision=activePlane()?.resultRevision??-1;}
function selectObservation(id){cancelInterpolation();tuningInteraction?.stop();if(!planes.some(panel=>panel.id===id))return;activeId=id;loadActiveScreen();syncScreen();drawBench();drawScreen();setBusy();}
function selectInterpolationOrObservation(id){if(interpolationMode)selectInterpolationEndpoint(id);else selectObservation(id);}
function placeInterpolationControls(){
  if(compactMedia.matches){
    keyActions.insertBefore(interpolateButton,keyActions.querySelector('.detail-toggle'));
    keyActions.append(interpolateGuide);
  }else{
    positionEditActions.append(interpolateButton);
    $('view-workspace').prepend(interpolateGuide);
  }
}
function showInterpolationGuide(message,error=false){interpolateGuide.textContent=message;interpolateGuide.title=message;interpolateGuide.classList.toggle('error',error);}
function syncInterpolationUI(){
  document.body.classList.toggle('interpolating-positions',interpolationMode);
  interpolateButton.classList.toggle('active',interpolationMode);
  const ready=interpolationMode&&interpolationEndpoints.length===2;
  interpolateButton.classList.toggle('ready',ready);
  interpolateButton.textContent=ready?'Apply':'Interpolate';
  interpolateButton.setAttribute('aria-label',ready?'Apply interpolation between selected key positions':'Interpolate between two key positions');
  interpolateButton.title=ready?'Apply even position steps between the selected cards':'Set positions between two selected slices to even steps';
  interpolateButton.setAttribute('aria-pressed',String(interpolationMode));
  interpolateGuide.hidden=!interpolationMode;
  for(const item of document.querySelectorAll('#observation-grid .slice-item')){
    const order=interpolationEndpoints.indexOf(item.dataset.positionId);
    if(interpolationMode&&order>=0)item.dataset.interpolateEndpoint=String(order+1);
    else delete item.dataset.interpolateEndpoint;
  }
  syncPositionHistoryButtons();
}
function cancelInterpolation(){
  if(!interpolationMode)return;
  interpolationMode=false;interpolationEndpoints=[];showInterpolationGuide('');syncInterpolationUI();
}
function selectInterpolationEndpoint(id){
  const selected=interpolationEndpoints.indexOf(id);
  if(selected>=0)interpolationEndpoints.splice(selected,1);
  else if(interpolationEndpoints.length===2)interpolationEndpoints[1]=id;
  else interpolationEndpoints.push(id);
  const [first,second]=interpolationEndpoints;
  showInterpolationGuide(second?`${first}–${second} selected · tap Apply`:first?`${first} selected · choose another card`:'Choose two cards with slices between them');
  syncInterpolationUI();
}
function toggleInterpolation(){
  if(!interpolationMode){
    commitPositionFields();tuningInteraction?.stop();endPositionGesture();
    interpolationMode=true;interpolationEndpoints=[];
    showInterpolationGuide('Choose two cards with slices between them');syncInterpolationUI();return;
  }
  if(interpolationEndpoints.length!==2){showInterpolationGuide('Choose two cards first',true);return;}
  const [first,second]=interpolationEndpoints,from=planes.findIndex(panel=>panel.id===first),to=planes.findIndex(panel=>panel.id===second);
  if(Math.abs(from-to)<2){showInterpolationGuide('Choose cards with at least one between them',true);return;}
  const requested={...quality()};
  try{validate({...p,...requested});}catch(error){showInterpolationGuide(error.message,true);return;}
  const before=positionSnapshot(planes,activeId,lastPosition);
  stopPositionJobs();const updated=interpolatePositions(planes,first,second,geometry(p));
  for(const panel of updated){panel.result=null;panel.resultKey=null;panel.resultRevision=-1;panel.pending=false;panel.progress=null;}
  hydratePositions(updated,geometry(p),screenParams(),sliceCache,revision);
  if(activePlane())lastPosition=observationZ(activePlane(),geometry(p));
  recordPositionEdit(before);cancelInterpolation();refreshObservations();
  const pending=updated.filter(panel=>!sameSlice(panel.result,screenParams(),observationZ(panel,geometry(p))));
  if(pending.length){batch=new SliceBatch(pending);for(const panel of pending)calculate('screen',requested,panel,batch);}
  observationUI.notice(`Interpolated ${updated[0].id}–${updated.at(-1).id}`);
}
function markChanged(){cancelInterpolation();tuningInteraction?.stop();positionGestureStart=null;positionGestureSource=null;positionHistory.clear(positionSnapshot(planes,activeId,lastPosition));syncPositionHistoryButtons();revision++;presetTicket++;updatePresetInfo();waveRequest++;waveLoading=false;$('preset').value='';if(result)status('Settings changed — displayed fields are from the previous calculation.');else status('Ready to calculate.');cancel(false);sliceCache.clear();fixedImageSaved=null;for(const panel of planes){panel.generation++;tuneObservation(panel,geometry(p),panel.offset);}yzResult=null;$('yz-note').textContent='Each column is normalized; brightness cannot be compared along z.';drawYZ();drawBench();syncScreen();renderInspectorPreview();drawScreen();restoreDefaultWave();}

function inputControl(key,label,min,max,step,unit=''){const wrap=document.createElement('div');wrap.className='control';const labelEl=document.createElement('label');labelEl.htmlFor=`${key}-number`;const name=document.createElement('span');name.className='parameter-name';name.textContent=label;labelEl.append(name);const nf=document.createElement('span');nf.className='number-field';const num=document.createElement('input');num.type='number';num.inputMode='decimal';num.min=min;num.max=max;num.step=step;num.value=p[key];num.id=`${key}-number`;num.setAttribute('aria-label',`${label}${unit?' in '+unit:''}`);nf.append(num);if(unit){const suffix=document.createElement('span');suffix.className='field-unit';suffix.textContent=unit;suffix.setAttribute('aria-hidden','true');nf.append(suffix);}labelEl.append(nf);const range=document.createElement('input');range.type='range';range.id=`${key}-range`;range.min=min;range.max=max;range.step=step;range.value=p[key];range.setAttribute('aria-label',label);function change(v){if(v.trim()==='')return;const value=Math.min(max,Math.max(min,Number(v)));if(!Number.isFinite(value))return;range.value=value;num.value=value;p[key]=value;if(key==='maskSizeUm'){p.fieldSizeUm=Math.max(p.fieldSizeUm,Math.ceil(value*4/3/10)*10);const el=$('fieldSizeUm-number');if(el){el.value=p.fieldSizeUm;$('fieldSizeUm-range').value=p.fieldSizeUm;}}if(key==='sourceOuter'&&p.sourceInner>=p.sourceOuter)p.sourceInner=p.sourceOuter*.65;markChanged();if(selected==='mask')$('component-note').textContent=`The 50.8 mm plate is illustrative. Only the ${fmt(p.fieldSizeUm)} µm local window is calculated; everything outside it is blocked.`;}range.addEventListener('input',()=>change(range.value));num.addEventListener('change',()=>{if(num.value.trim()==='')num.value=p[key];else change(num.value);});wrap.append(labelEl,range);return wrap;}
function selectControl(key,label,options){const wrap=document.createElement('div');wrap.className='control';const l=document.createElement('label');l.htmlFor=key;l.textContent=label;const s=document.createElement('select');s.id=key;for(const value of options){const o=document.createElement('option');o.value=value;o.textContent=value;s.append(o);}s.value=p[key];s.addEventListener('change',()=>{p[key]=s.value;if(s.value==='Freeform')ensurePaint(key==='sourceType'?'source':'pupil');markChanged();renderInspector();});wrap.append(l,s);return wrap;}
function renderInspector(){$('component-inspector').scrollTop=0;$('component-picker').value=selected;const c=components.find(c=>c[0]===selected),index=components.indexOf(c);$('component-number').textContent=`0${index+1} / ${(selected==='pupil'?'Projection aperture':c[1]).toUpperCase()}`;$('component-description').textContent=c[3];const controls=$('component-controls');controls.replaceChildren();const add=(...a)=>controls.append(inputControl(...a));const sel=(...a)=>controls.append(selectControl(...a));let note='';
  switch(selected){
    case 'source':sel('sourceType','Source pupil shape',sources);add('wavelengthNm','Wavelength',250,800,5,'nm');if(p.sourceType==='Point'){add('pointSourceU','Horizontal position',-.7,.7,.01);add('pointSourceV','Vertical position',-.7,.7,.01);}else{add('sourceOuter',p.sourceType.includes('Dipole')?'Lobe radius':'Source radius',.05,.7,.01);if(p.sourceType==='Annular')add('sourceInner','Inner radius',0,p.sourceOuter-.01,.01);if(p.sourceType.includes('pole'))add('quadSeparation','Lobe separation',.1,1,.05);}add('sourceEmissionNA','Emitter divergence',.01,.15,.005);note='Illumination pupil: emitter positions use normalized source coordinates. Yellow shows illumination; blue shows projection, not different wavelengths. Independent emitters add in intensity.';break;
    case 'condenser':add('condenserFocalMm','Focal length',50,180,5,'mm');add('condenserAperture','Soft aperture radius',0,2,.05);note='A Gaussian transmission aperture: light fades toward the edge. The source and mask remain one focal length from the condenser.';break;
    case 'mask':sel('maskType','Pattern',masks);add('maskSizeUm','Pattern width',4,120,1,'µm');if(p.maskType.includes('Grating')){add('gratingPitchUm','Pitch',2,40,1,'µm');add('gratingDuty','Open fraction',.1,.9,.05);}if(p.maskType==='Annular Aperture')add('maskInnerRatio','Inner / outer radius',.1,.9,.05);add('fieldSizeUm','Calculation window',10,200,1,'µm');note=`The 50.8 mm plate is illustrative. Only the ${fmt(p.fieldSizeUm)} µm local window is calculated; everything outside it is blocked.`;break;
    case 'lens1':add('f1Mm','Focal length',50,180,5,'mm');add('reduction','Image reduction',1,8,.5,'×');note='The ideal 4f spacing updates with focal length. Lens curvature and mount dimensions are illustrative.';break;
    case 'pupil':sel('lensType','Aperture shape',pupils);add('projNA','Image-side NA',.03,.3,.01);if(['Annular','Horizontal Slit','Vertical Slit'].includes(p.lensType))add('lensInner',p.lensType==='Annular'?'Central obstruction':'Slit half-width',.05,.9,.05);note='NA sets the largest transmitted angle. This projection aperture is in the Fourier plane. Its opening is independent of the illumination source shape.';break;
    case 'lens2':add('reduction','Image reduction',1,8,.5,'×');add('f1Mm','Lens 1 focal length',50,180,5,'mm');note=`Lens 2 focal length = ${fmt(p.f1Mm/p.reduction)} mm. The image is inverted and ${fmt(p.reduction)}× smaller than the mask.`;break;
    case 'image':renderImageControls(controls);note='Use the separate Observation screen below to explore other positions or move through focus. This image plane stays at the ideal focus.';break;
  }
  if((selected==='source'&&p.sourceType==='Freeform')||(selected==='pupil'&&p.lensType==='Freeform')){const b=document.createElement('button');b.className='secondary control';b.textContent='Paint custom pattern';b.addEventListener('click',()=>openPaint(selected));controls.append(b);}
  $('component-note').textContent=note;renderInspectorPreview();
}
function rememberSlice(key,r){sliceCache.set(key,r);if(sameSlice(r,screenParams(),geometry(p).image))fixedImageSaved={key,result:r};}
function findSavedSlice(params,z){return bestSlice([...sliceCache.values(),...planes.map(panel=>panel.result),fixedImageSaved?.result].filter(Boolean),params,z);}
function fixedImageResult(){return findSavedSlice({...screenParams(),...QUALITY.standard},geometry(p).image);}
function fixedImageCanvas(size=256,zoom=1){
  const r=fixedImageResult();if(!r)return null;
  const canvas=document.createElement('canvas');canvas.width=canvas.height=size;
  const half=(r.screenHalf||Math.max(Math.abs(r.screenAxis[0]),Math.abs(r.screenAxis.at(-1))))/zoom;
  paintImage(canvas,r.screenRaw,r.screenAxis.length,r.screenAxis,'blue',$('brightness').value.startsWith('shared')?r.sharedPeak:null,true,half);return canvas;
}
function fixedImagePicture(zoom=1){
  const r=fixedImageResult();if(!r)return null;
  const style=$('brightness').value+':'+$('smooth-intensity').checked+':'+zoom;
  if(fixedPreviewMemo?.result===r&&fixedPreviewMemo.style===style)return fixedPreviewMemo.url;
  const url=fixedImageCanvas(160,zoom).toDataURL();fixedPreviewMemo={result:r,style,url};return url;
}
function renderImageControls(host){
  const g=geometry(p),meta=document.createElement('p');meta.className='image-plane-meta';meta.textContent=`z = ${fmt(g.image)} mm · ${fmt(p.reduction)}× reduction`;
  const label=document.createElement('label');label.className='control';label.textContent='Display window';
  const select=document.createElement('select');select.id='fixed-image-zoom';select.setAttribute('aria-label','Fixed image display window');
  for(const [value,text]of [[1,'Fit'],[2,'2×'],[4,'4×']]){const o=document.createElement('option');o.value=value;o.textContent=text;select.append(o);}select.value=imageZoom;
  select.onchange=()=>{imageZoom=Number(select.value);renderInspectorPreview();};label.append(select);
  const actions=document.createElement('div');actions.className='fixed-image-actions';
  const go=document.createElement('button');go.id='go-fixed-image';go.className='secondary';go.textContent='Use image plane';go.disabled=!activePlane();go.title='Move the selected observation to the fixed image plane';go.onclick=()=>setPosition(geometry(p).image,'image');
  const save=document.createElement('button');save.id='save-fixed-image';save.className='secondary';save.textContent='Save image';save.disabled=!fixedImageResult();save.onclick=()=>{const canvas=fixedImageCanvas(960,imageZoom);if(canvas){benchEditor.close();sliceShare.open(canvas,geometry(p).image,document.body.classList.contains('phone-bench')?benchEditor.returnTarget:save);}};
  const status=document.createElement('p');status.id='fixed-image-status';status.className='control-hint';status.setAttribute('role','status');
  actions.append(go,save);host.append(meta,label,actions,status);
}
function benchPattern(kind){
  const c=document.createElement('canvas');c.width=c.height=128;const ctx=c.getContext('2d'),img=ctx.createImageData(128,128),e=kind==='source'?sourceExtent(p):1.1;
  for(let y=0;y<128;y++)for(let x=0;x<128;x++){
    let v=0;for(const dy of [.25,.75])for(const dx of [.25,.75]){const u=((x+dx)/128*2-1)*e,w=(1-(y+dy)/128*2)*e;v+=(kind==='source'?sourceValue(p,u,w):1-pupilValue(p,u,w))/4;}
    const k=4*(y*128+x),color=kind==='source'?[255,225,155]:[38,56,70];img.data.set([...color,Math.round(v*255)],k);
  }
  ctx.putImageData(img,0,0);return c.toDataURL();
}
function imageDataURL(kind){const c=document.createElement('canvas');c.width=c.height=96;const a=new Float64Array(96*96),e=kind==='source'?sourceExtent(p):1.1;for(let y=0;y<96;y++)for(let x=0;x<96;x++){const u=(x/95*2-1)*e,v=(1-y/95*2)*e;a[y*96+x]=kind==='source'?sourceValue(p,u,v):pupilValue(p,u,v);}paintImage(c,a,96,null,kind==='source'?'warm':'mono',1,false);return c.toDataURL();}
function maskDiagram(){let marks='';if(p.maskType.includes('Grating')){const pitch=Math.max(5,Math.min(28,p.gratingPitchUm/p.maskSizeUm*74));for(let x=-36;x<=36;x+=pitch)marks+=`<rect x="${x}" y="-34" width="${pitch*p.gratingDuty}" height="68" fill="#e9f5ff"/>`;if(p.maskType==='2D Grating')for(let y=-34;y<34;y+=pitch)marks+=`<rect x="-38" y="${y+pitch*p.gratingDuty}" width="76" height="${pitch*(1-p.gratingDuty)}" fill="#304659"/>`;}else if(p.maskType==='Circular Aperture'||p.maskType==='Annular Aperture'){marks='<circle r="27" fill="#e9f5ff"/>';if(p.maskType==='Annular Aperture')marks+=`<circle r="${27*p.maskInnerRatio}" fill="#304659"/>`;}else if(p.maskType==='Diamond Aperture')marks='<path d="M0-32 32 0 0 32-32 0Z" fill="#e9f5ff"/>';else if(p.maskType==='Cross')marks='<path d="M-10-32H10V-10H32V10H10V32H-10V10H-32V-10H-10Z" fill="#e9f5ff"/>';else marks='<rect x="-27" y="-27" width="54" height="54" fill="#e9f5ff"/>';return `<rect x="-45" y="-43" width="90" height="86" rx="3" fill="#8093a3"/><rect x="-39" y="-37" width="78" height="74" rx="1" fill="#304659"/>${marks}`;}
function lensDiagram(h=63,w=13){return `<path d="M0 ${-h}Q${-w*2} 0 0 ${h}Q${w*2} 0 0 ${-h}Z" fill="url(#glass)" stroke="#6497b9" stroke-width="1.3"/><path d="M-1 ${-h+8}Q${-w*1.4} 0 -1 ${h-8}" fill="none" stroke="white" stroke-width="1.8" opacity=".8"/><path d="M-7 ${-h}h14M-7 ${h}h14" stroke="#536f87" stroke-width="4"/>`;}
const defs=`<defs><linearGradient id="glass"><stop stop-color="#8cc6ea" stop-opacity=".65"/><stop offset=".45" stop-color="#eaf8ff" stop-opacity=".3"/><stop offset="1" stop-color="#68aad6" stop-opacity=".65"/></linearGradient><radialGradient id="soft"><stop stop-color="#e6ad52" stop-opacity=".7"/><stop offset=".6" stop-color="#e6ad52" stop-opacity=".25"/><stop offset="1" stop-color="#e6ad52" stop-opacity="0"/></radialGradient></defs>`;
function renderInspectorPreview(){updateComponentSummary();if($('save-fixed-image'))$('save-fixed-image').disabled=!fixedImageResult();if($('go-fixed-image'))$('go-fixed-image').disabled=!activePlane();if($('fixed-image-status'))$('fixed-image-status').textContent=fixedImageResult()?'Fixed image plane':'Compute a slice at the image plane to update this preview.';let content;if(selected==='source')content=`<image href="${imageDataURL('source')}" x="-40" y="-40" width="80" height="80"/>`;else if(selected==='pupil')content=`<image href="${imageDataURL('pupil')}" x="-42" y="-42" width="84" height="84"/>`;else if(selected==='mask')content=`<g transform="scale(.85)">${maskDiagram()}</g>`;else if(selected==='image'&&fixedImagePicture(imageZoom))content=`<image href="${fixedImagePicture(imageZoom)}" x="-36" y="-40" width="72" height="80"/>`;else if(selected==='image')content='<rect x="-32" y="-38" width="64" height="76" rx="3" fill="#eef7ff" stroke="#7fa1bd"/>';else content=`${lensDiagram(37,13)}<path d="M-63-23 0-23 57 0M-63 23 0 23 57 0" fill="none" stroke="${selected==='condenser'?RAY_YELLOW:RAY_BLUE[0]}" stroke-width="1.5"/><text x="49" y="17" font-size="10" fill="#54708c">F</text>`;$('component-preview').innerHTML=`<svg viewBox="-75 -46 150 92" aria-hidden="true">${defs}${content}</svg>${selected==='pupil'?'<span class="aperture-legend"><span><i class="transmits"></i>White: passes light</span><span><i class="blocks"></i>Black: blocks light</span><small>Front view · opening shape</small></span>':''}`;}
function drawBench(){
  const focusedMarker=document.activeElement?.dataset?.positionMarker;
  const host=$('bench'),restoreFocus=document.activeElement?.hasAttribute('data-observation-screen'),width=Math.max(1,$('bench-wrap').clientWidth-16),mode=benchEditor.compact?'many':rayMode;
  $('beam-regions').innerHTML=regionMarkup(geometry(p));
  if(benchEditor.compact){const drawing=compactBench({width,geometry:geometry(p),params:p,components,selected,screen:activePlane()?currentZ():null,pupilValue,mode,dragLayout,observations:viewTabs.keyView?markedPositions(planes.map(panel=>({id:panel.id,z:observationZ(panel,geometry(p))})),activeId,4):[],activeId});host.setAttribute('viewBox',`0 0 ${width} ${drawing.height}`);host.classList.add('compact-beam');host.innerHTML=drawing.svg;bindBench();if(focusedMarker)host.querySelector(`[data-position-marker="${focusedMarker}"]`)?.focus({preventScroll:true});else if(restoreFocus)host.querySelector('[data-observation-screen]')?.focus({preventScroll:true});return;}
  const drawing=desktopBench({width,height:240,geometry:geometry(p),params:p,components,selected,screen:activePlane()?currentZ():null,pupilValue,mode,defs,lensDiagram,maskDiagram,observations:markedPositions(planes.map(panel=>({id:panel.id,z:observationZ(panel,geometry(p))})),activeId,8),activeId,pictures:{source:benchPattern('source'),pupil:benchPattern('pupil'),image:fixedImagePicture()}});
  host.setAttribute('viewBox',`0 0 ${width} ${drawing.height}`);host.classList.remove('compact-beam');host.innerHTML=drawing.svg;

  bindBench();if(restoreFocus)host.querySelector('[data-observation-screen]')?.focus({preventScroll:true});
}
function bindBench(){
  for(const el of $('bench').querySelectorAll('[data-component],[data-label]')){const action=()=>{selected=el.dataset.component||el.dataset.label;renderInspector();drawBench();benchEditor.open(selected);};el.addEventListener('click',action);el.addEventListener('keydown',e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();action();}});}
}
function syncFocus(){
  const panel=activePlane(),g=geometry(p),base=panel?tuningBase(panel,g):0,offset=panel?.offset||0;
  $('focus-options').hidden=false;$('focus-control').hidden=false;$('return-focus').disabled=!panel||offset===0;
  $('focus-offset-label').textContent=offset===0?'':`${offset>0?'+':''}${fmt(offset)} µm`;
  $('tuning-anchor').textContent=panel?`· from ${fmt(base,3)} mm`:'';
  $('fine-tuning-toggle').title=panel?`Fine tuning from ${fmt(base,3)} mm. Reset offset returns to this position.`:'Select an image to edit its position';$('fine-tuning-toggle').disabled=!panel;
  for(const id of ['tuning-number','tuning-range']){const input=$(id);if(input){input.disabled=!panel;const span=Math.max(Number($('fine-range').value)*1000,Math.abs(offset));input.min=Math.ceil(Math.max(-span,-base*1000));input.max=Math.floor(Math.min(span,(g.max-base)*1000));input.value=fmt(offset,0);}}
}

function syncScreen(){
  fieldEdits.z=false;fieldEdits.offset=false;
  if($('go-fixed-image'))$('go-fixed-image').disabled=!activePlane();
  syncFocus();const g=geometry(p),panel=activePlane(),at=currentZ();$('active-observation').classList.toggle('no-active-position',!panel);for(const id of ['plane','slice-z','screen-slider'])$(id).disabled=!panel;
  if(!panel){$('plane').value='';$('slice-z').value='';$('slice-z').placeholder='—';$('screen-slider').value=at;$('active-observation').textContent=planes.length?'Select an image to edit its position':'Add a position to start';document.dispatchEvent(new Event('observation-position-change'));syncWaveCursor();return;}$('plane').value=panel.offset!==0?'custom':panel.plane;$('slice-z').value=fmt(at,3);$('slice-z').max=Math.ceil(g.max*1000)/1000;$('screen-slider').max=g.image;$('screen-slider').value=at;
  const label=PLANE_NAMES[panel.plane];$('screen-location').textContent=`${label} · z = ${fmt(at,3)} mm`;
  $('active-observation').innerHTML=`<span class="phone-label">Editing </span><b aria-label="Observation ${panel.id}">${panel.id}</b><span class="phone-label"> ${panel.offset===0?label:'Custom position'}</span>`;
  document.dispatchEvent(new Event('observation-position-change'));syncWaveCursor();
}
function syncPositionHistoryButtons(){
  if($('undo-position-edit')){
    $('undo-position-edit').disabled=!interpolationMode&&!positionHistory.canUndo;
    $('undo-position-edit').title=interpolationMode?'Cancel interpolation selection':'Undo position edit';
    $('undo-position-edit').setAttribute('aria-label',interpolationMode?'Cancel interpolation selection':'Undo position edit');
  }
  if($('redo-position-edit'))$('redo-position-edit').disabled=!positionHistory.canRedo;
}
function recordPositionEdit(before){
  if(positionHistory.record(before,positionSnapshot(planes,activeId,lastPosition)))observationUI.notice('');
  syncPositionHistoryButtons();
}
function beginPositionGesture(source,selectedId=activeId){
  if(!positionGestureStart){positionGestureStart=positionSnapshot(planes,selectedId,lastPosition);positionGestureSource=source;}
}
function endPositionGesture(source=null){
  if(!positionGestureStart||(source&&positionGestureSource!==source))return;
  const before=positionGestureStart;positionGestureStart=null;positionGestureSource=null;recordPositionEdit(before);
}
function restorePositionEdit(saved){
  stopPositionJobs();planes=restorePositions(saved.planes);activeId=saved.activeId;lastPosition=saved.lastPosition;
  hydratePositions(planes,geometry(p),screenParams(),sliceCache,revision);
  observationUI.notice('');refreshObservations();syncPositionHistoryButtons();
}
function undoPositionEdit(){
  if(interpolationMode){cancelInterpolation();return;}
  tuningInteraction?.stop();endPositionGesture();const saved=positionHistory.undo();
  if(saved)restorePositionEdit(saved);
}
function redoPositionEdit(){
  cancelInterpolation();tuningInteraction?.stop();endPositionGesture();const saved=positionHistory.redo();
  if(saved)restorePositionEdit(saved);
}
function positionChanged(){
  jobs.cancel('screen-'+activeId);if(activePlane())activePlane().pending=false;syncScreen();
  if(benchFrame!==null)cancelAnimationFrame(benchFrame);benchFrame=requestAnimationFrame(()=>{benchFrame=null;drawBench();});drawScreen();
}
function setPosition(value,plane='custom'){
  if(!activePlane())return;
  cancelInterpolation();
  const before=positionGestureStart?null:positionSnapshot(planes,activeId,lastPosition);
  if(setObservation(activePlane(),geometry(p),plane==='custom'?quantizePosition(value):value,plane)){
    if(before)recordPositionEdit(before);
    positionChanged();
  }
}
function setFineOffset(value){
  const panel=activePlane(),span=Math.max(Number($('fine-range').value)*1000,Math.abs(panel?.offset||0));
  if(!panel)return;
  const before=positionGestureStart?null:positionSnapshot(planes,activeId,lastPosition);
  if(tuneObservation(panel,geometry(p),Math.round(Math.max(-span,Math.min(span,value))))){
    if(before)recordPositionEdit(before);
    positionChanged();
  }
}

function paintImage(canvas,data,n,coords=null,kind='blue',peak=null,flip=true,half=null,stop=null,coordsY=coords){
  const ctx=canvas.getContext('2d'),w=canvas.width,h=canvas.height,img=ctx.createImageData(w,h),m=peak??maximum(data),mode=kind==='mono'?'local':$('brightness').value,smooth=kind!=='mono'&&($('smooth-intensity')?.checked??true);
  for(let y=0;y<h;y++)for(let x=0;x<w;x++){
    let ix,iy;
    if(coords&&half){const xx=(x/(w-1)*2-1)*half,yy=(flip?1-y/(h-1)*2:y/(h-1)*2-1)*half,dx=coords[1]-coords[0];ix=(xx-coords[0])/dx;iy=(yy-coordsY[0])/(coordsY[1]-coordsY[0]);}
    else{ix=x/(w-1)*(n-1);iy=(flip?1-y/(h-1):y/(h-1))*(n-1);}
    const pass=!stop||pupilValue(stop.params,(x/(w-1)*2-1)*half/stop.radius,(1-y/(h-1)*2)*half/stop.radius)>0;
    const c=palette(brightness(pass?sampleIntensity(data,n,ix,iy,smooth):0,m,mode),kind),k=(y*w+x)*4;img.data[k]=c[0];img.data[k+1]=c[1];img.data[k+2]=c[2];img.data[k+3]=255;
  }ctx.putImageData(img,0,0);
}
function arrayPicture(type,params=p,n=128){const a=new Float64Array(n*n),e=type==='source'?sourceExtent(params):1.1;for(let y=0;y<n;y++)for(let x=0;x<n;x++){const u=(x/(n-1)*2-1)*e,v=(y/(n-1)*2-1)*e;a[y*n+x]=type==='source'?sourceValue(params,u,v):pupilValue(params,u,v);}return a;}
function drawResults(){if(!result)return;const r=result,q=r.params,shared=$('brightness').value.startsWith('shared'),n=q.gridSize,P=n*q.propagationPadding;if($('source-view').value==='weights')paintImage($('source-canvas'),arrayPicture('source',q),128,null,'mono');else paintImage($('source-canvas'),r.sourceRaw,r.sourceAxis.length,null,'warm',shared?r.sharedPeak:null);if($('mask-view').value==='intensity')paintImage($('mask-canvas'),r.maskRaw,n,null,'blue',shared?r.sharedPeak:null);else paintImage($('mask-canvas'),r.mask,n,null,'mono',1);if($('pupil-view').value==='opening')paintImage($('pupil-canvas'),arrayPicture('pupil',q),128,null,'mono',1);else paintImage($('pupil-canvas'),r.pupilRaw,r.pupilAxis.length,r.pupilAxis,'blue',shared?r.sharedPeak:null,true,1.1*r.geometry.f2*.001*q.projNA);paintImage($('image-canvas'),r.screenRaw,r.screenAxis.length,r.screenAxis,'blue',shared?r.sharedPeak:null,true,r.screenHalf);$('source-canvas').setAttribute('aria-label',$('source-view').value==='weights'?'Source distribution':'Pupil plane light intensity');$('mask-canvas').setAttribute('aria-label',$('mask-view').value==='amplitude'?'Mask amplitude transmission':'Mask exit light intensity');$('source-axis').textContent=$('source-view').value==='weights'?`±${fmt(r.sourceExtent)} source units`:`${fmt((r.sourceAxis.at(-1)-r.sourceAxis[0])*1e3)} mm source window`;$('mask-axis').textContent=`${fmt(q.fieldSizeUm)} µm local window`;$('pupil-axis').textContent=`±${fmt(1.1*r.geometry.f2*q.projNA)} mm`;$('image-title').textContent='Image Plane';$('image-z').textContent=`z = ${fmt(r.z,4)} mm`;const width=r.screenHalf?2*r.screenHalf:r.screenAxis.at(-1)-r.screenAxis[0];$('image-axis').textContent=`${width>=.001?fmt(width*1e3)+' mm':fmt(width*1e6)+' µm'} window${r.dark?' · no transmitted light':''}`;$('calculation-detail').textContent=`${n} × ${n} mask grid · ${r.samples} emitter${r.samples===1?'':'s'} · ${fmt(r.elapsed/1000,1)} s · scalar / ideal lenses`;drawScreen();}
function drawProfile(){if(!screenResult)return;const plotWidth=Math.max(240,$('profile').getBoundingClientRect().width||800),left=42,right=plotWidth-18,mid=(left+right)/2;$('profile').setAttribute('viewBox',`0 0 ${plotWidth} 170`);const r=screenResult,n=r.screenAxis.length,lo=r.screenHalf?-r.screenHalf:r.screenAxis[0],hi=r.screenHalf?r.screenHalf:r.screenAxis.at(-1),samples=[],cut=centerCuts(r.screenRaw,r.screenAxis,r.screenAxisY).xz;let peak=0;for(let x=0;x<n;x++)if(r.screenAxis[x]>=lo&&r.screenAxis[x]<=hi){const v=cut[x];samples.push([r.screenAxis[x],v]);peak=Math.max(peak,v);}let path='';for(let j=0;j<samples.length;j++){const [x,v]=samples[j];path+=`${j?'L':'M'}${left+(x-lo)/(hi-lo)*(right-left)},${133-(peak?v/peak:0)*104}`;}const useMm=Math.max(Math.abs(lo),Math.abs(hi))>=.001,unit=useMm?'mm':'µm',u=useMm?1e3:1e6;$('profile-plane').textContent=`${benchEditor.compact?'':activeId+' · '}${r.label} · z = ${fmt(r.z,4)} mm${screenRevision!==revision?' · previous settings':''}`;$('profile-description').textContent='Horizontal cut at y = 0; normalized to its own peak.';$('profile').innerHTML=`<path d="M${left} 29H${right}M${left} 81H${right}M${left} 133H${right}" stroke="#dfe7f0" stroke-dasharray="3 4"/><path d="${path}" fill="none" stroke="#176bda" stroke-width="2"/><g fill="#728197" font-size="12"><text x="21" y="34">1</text><text x="12" y="85">0.5</text><text x="21" y="138">0</text><text x="${left}" y="158">${fmt(lo*u)}</text><text x="${mid}" y="158" text-anchor="middle">${fmt((lo+hi)/2*u)}</text><text x="${right}" y="158" text-anchor="end">${fmt(hi*u)} ${unit}</text></g>`;}
function quality(){return details.quality(compactMedia.matches,viewTabs.keyView);}
function setBusy(){
  busy=!!jobs.current;activeJob=jobs.current?.job.kind||null;
  const referencesPending=jobs.has('references'),referencesStale=!!result&&calculatedRevision!==revision;
  $('fixed-panel').classList.toggle('updating-references',referencesPending);
  $('fixed-panel').classList.toggle('references-need-update',referencesStale);
  document.querySelector('.reference-progress-label').textContent=referencesPending?'Calculating…':referencesStale?'Needs update':'';
  const panel=activePlane(),pending=!!panel&&(jobs.has('screen-'+activeId)||jobs.current?.job.request?.instance===panel.instance&&activeJob==='image'),batchPending=!!batch?.active;
  $('cancel').hidden=true;$('cancel-screen').hidden=true;
  const wavePending=jobs.has('wave'),waveButton=$('calculate-yz');
  waveButton.textContent=wavePending?'Cancel':'Compute';waveButton.classList.toggle('is-computing',wavePending);
  waveButton.style.setProperty('--compute-progress',`${wavePending?waveProgress:0}%`);
  waveButton.title=wavePending?'Cancel wave calculation':'Compute wave intensity';
  $('wave-progress-overlay').hidden=!wavePending;
  $('wave-progress-value').textContent=`${waveProgress}%`;
  const cancelling=batchPending||pending;
  for(const id of ['calculate','show-slice']){
    const button=$(id);button.textContent=cancelling?'Cancel':'Compute';button.classList.toggle('is-computing',cancelling);
    button.style.setProperty('--compute-progress',`${batchPending?100*batch.completed/batch.total:0}%`);
    button.title=cancelling?'Cancel calculation; retain completed images':id==='show-slice'&&benchEditor.compact?'Compute the observation screen':`Compute all ${planes.length} observation positions`;
  }
  $('calculate').disabled=!cancelling&&(jobs.has('references')||!planes.length);
  $('show-slice').disabled=!cancelling&&((!panel&&benchEditor.compact)||!planes.length);
  $('calculate-yz').disabled=false;
  $('quality').disabled=false;screenMoved();
}
function cancel(show=true){batch=null;jobs.cancel();planes.forEach(panel=>panel.pending=false);$('progress').value=1;if(show){status('Calculation cancelled. Previous results retained.');screenMoved();}}
function commitPositionFields(){
  if(!activePlane())return;
  const z=$('slice-z').value.trim(),offset=$('tuning-number').value.trim();
  if(fieldEdits.z&&z!==''&&Number.isFinite(Number(z)))setPosition(Number(z));
  else if(fieldEdits.offset&&offset!==''&&Number.isFinite(Number(offset)))setFineOffset(Number(offset));
}
function computeSlices(all=false){
  cancelInterpolation();tuningInteraction?.stop();
  if(!planes.length||batch?.active)return;
  if(activePlane())for(const id of ['slice-z','tuning-number'])if(!$(id).checkValidity()){
    $('standard-position-options').open=true;$('focus-options').open=true;$(id).reportValidity();return;
  }
  commitPositionFields();
  const targets=benchEditor.compact&&!all&&!viewTabs.keyView?[activePlane()].filter(Boolean):[activePlane(),...planes.filter(panel=>panel.id!==activeId)].filter(Boolean);
  const requested={...quality()};
  try{if(targets.some(panel=>!findSavedSlice({...p,...requested},observationZ(panel,geometry(p)))))validate({...p,...requested});}catch(error){
    const message=(requested.gridSize<512?'Enable High detail for these settings. ':'')+error.message;
    const notice=$('slice-compute-notice');notice.textContent=message;notice.hidden=false;return;
  }
  $('slice-compute-notice').hidden=true;
  batch=new SliceBatch(targets);const ticket=batch;
  for(const panel of targets)calculate('screen',requested,panel,ticket);
  if(benchEditor.compact&&viewTabs.keyView&&viewTabs.editing){const anchor=document.querySelector('#fixed-panel .results-heading'),top=anchor.getBoundingClientRect().top;viewTabs.setEditing(false);refreshObservations();window.scrollBy(0,anchor.getBoundingClientRect().top-top);}
  setBusy();
}
function cancelScreens(){
  const instances=batch?.active?new Set(batch.states.keys()):new Set([activePlane()?.instance]);
  if(batch?.active)batch=null;
  for(const panel of planes)if(instances.has(panel.instance))jobs.cancel('screen-'+panel.id);
  if(instances.has(jobs.current?.job.request?.instance)&&jobs.current?.job.kind==='image')jobs.cancel('references');
  setBusy();
}
function refreshObservations(){observationUI.render();placeInterpolationControls();syncInterpolationUI();syncScreen();drawScreen();drawBench();setBusy();}
function removeObservation(id){
  const index=planes.findIndex(panel=>panel.id===id);if(index<0)return;
  cancelInterpolation();
  tuningInteraction?.stop();endPositionGesture();const before=positionSnapshot(planes,activeId,lastPosition);
  const panel=planes[index],previousActive=activePlane(),removedActive=activeId===id;
  stopPositionJobs();panel.generation++;planes.splice(index,1);relabelPositions(planes);
  activeId=removedActive?planes[Math.min(index,planes.length-1)]?.id||null:previousActive?.id||null;
  lastPosition=activePlane()?observationZ(activePlane(),geometry(p)):observationZ(panel,geometry(p));
  recordPositionEdit(before);
  refreshObservations();observationUI.removed(id);(activeId?$('slice-panel-'+activeId):$(benchEditor.compact?'add-mobile-position':'add-position')).focus({preventScroll:true});
}
function duplicateObservation(id){
  const viewportTop=window.scrollY;
  cancelInterpolation();
  commitPositionFields();tuningInteraction?.stop();endPositionGesture();
  if(!planes.some(panel=>panel.id===id))return;
  const before=positionSnapshot(planes,activeId,lastPosition);
  stopPositionJobs();const copy=duplicatePositionAfter(planes,id);
  activeId=copy.id;lastPosition=observationZ(copy,geometry(p));
  recordPositionEdit(before);refreshObservations();observationUI.notice(`Added ${copy.id}`);
  $('slice-panel-'+copy.id).focus({preventScroll:true});window.scrollTo(0,viewportTop);
}
function addObservation(){
  const viewportTop=window.scrollY;
  cancelInterpolation();
  commitPositionFields();const before=positionSnapshot(planes,activeId,lastPosition);
  const added=appendPositionGroup(planes,benchEditor.compact?2:4);observationUI.render();
  activeId=added[0].id;recordPositionEdit(before);refreshObservations();observationUI.notice('Added '+added.map(p=>p.id).join('–'));
  $('slice-panel-'+activeId).focus({preventScroll:true});window.scrollTo(0,viewportTop);
}
function undoObservation(){undoPositionEdit();}
function stopPositionJobs(){
  batch=null;jobs.cancel('references',false);for(const panel of planes)jobs.cancel('screen-'+panel.id,false);jobs.start();
}
function useReferencePositions(){
  cancelInterpolation();
  commitPositionFields();
  if(atReferencePositions(planes)){if(matchingPreset(p))restorePresetSlices(matchingPreset(p).id);hydratePositions(planes,geometry(p),screenParams(),sliceCache,revision);refreshObservations();return;}
  tuningInteraction?.stop();endPositionGesture();const before=positionSnapshot(planes,activeId,lastPosition);
  stopPositionJobs();
  planes=restorePositions();activeId=benchEditor.compact&&!viewTabs.keyView?'D':null;hydratePositions(planes,geometry(p),screenParams(),sliceCache,revision);
  recordPositionEdit(before);
  refreshObservations();observationUI.notice('Default positions restored');if(matchingPreset(p))restorePresetSlices(matchingPreset(p).id);
}
function calculate(kind='image',override=null,target=activePlane(),batchTicket=null){
  if(kind==='screen'&&!target)return;
  if(kind==='yz'&&matchingPreset(p)&&$('wave-scope').value==='full'&&Number($('wave-detail').value)===512&&(yzResult?.cached||waveLoading)){restoreDefaultWave();return;}
  const params={...p,...(kind==='yz'?waveParameters(p,$('wave-detail').value):(override||quality())),defocusUm:0},panel=target||createPlane('_','image'),request=sliceRequest(panel,geometry(p),params),version=revision,scope=$('wave-scope').value;
  const key=kind==='yz'?'wave':kind==='image'?'references':'screen-'+panel.id;
  const retained=()=>planes.includes(panel),settle=state=>{batchTicket?.settle(panel.instance,state);};
  if(kind==='yz'){waveRequest++;waveLoading=false;waveProgress=1;}
  if(kind!=='yz'){panel.pending=true;panel.error='';}
  jobs.add({key,kind,request,
    run(done){
      // Check again when this job starts: an earlier view may have filled the cache.
      if(kind==='screen'){const cached=findSavedSlice(params,request.z);if(cached){done(null,{result:cached,elapsed:0});return;}}
      $('error').hidden=true;$('progress').value=0;
      if(kind!=='yz'){panel.pending=true;panel.error='';screenMoved();}else{status('Calculating both XZ and YZ wave sections…');if(!yzResult)drawYZ();}
      const worker=new Worker(new URL('./worker.js?v=20260927-positions3',import.meta.url),{type:'module'});
      worker.onerror=()=>done(Error('The calculation could not start. Please try again.'));
      worker.onmessage=({data})=>{
        if(jobs.current?.job.request!==request)return;
        if(data.type==='progress'){$('progress').value=data.value;if(kind==='yz'){waveProgress=Math.max(1,Math.min(99,Math.round(data.value*100)));$('wave-progress-value').textContent=`${waveProgress}%`;$('calculate-yz').style.setProperty('--compute-progress',`${waveProgress}%`);status(`Wave path · ${waveProgress}%`);}else{panel.progress=Math.round(data.value*100);screenMoved();}}
        else if(data.type==='error')done(Error(data.message));else if(data.type==='result')done(null,data);
      };
      worker.postMessage({type:kind,params,z:request.z,scope});return ()=>worker.terminate();
    },
    cancelled(){if(kind!=='yz'){panel.pending=false;panel.progress=null;settle('cancelled');}},
    failed(error){panel.pending=false;panel.progress=null;settle('error');if(kind==='yz')$('wave-status').textContent=error.message;else panel.error=error.message;if(kind==='image'){$('error').textContent=error.message;$('error').hidden=false;}if(kind!=='yz'){$('slice-compute-notice').textContent=error.message;$('slice-compute-notice').hidden=false;}screenMoved();},
    finished(data){
      $('progress').value=1;
      if(kind==='yz'){if(version===revision){yzResult=data.result;drawYZ();status(`XZ and YZ ready · ${fmt(data.elapsed/1000,1)} s`);}return;}
      panel.pending=false;panel.progress=null;settle('done');
      if(version!==revision)return;
      let r=screenSnapshot(kind==='screen'?data.result:data.result.screen);
      r=findSavedSlice(r.params,r.z)||r;
      const actualKey=sliceKey(r.params,r.z);rememberSlice(actualKey,r);
      if(retained()&&acceptsSlice(panel,request,geometry(p),params)){panel.result=r;panel.resultKey=actualKey;panel.resultRevision=version;panel.error='';}
      if(kind==='image'){
        result=data.result.planes;result.elapsed=data.elapsed;calculatedRevision=version;
        for(const reference of referenceScreens(result)){
          const refKey=sliceKey(params,reference.z);rememberSlice(refKey,reference);
          for(const slot of planes)if(!slot.pending&&sliceKey(screenParams(),observationZ(slot,geometry(p)))===refKey){slot.result=reference;slot.resultKey=refKey;slot.resultRevision=version;slot.error='';}
        }
        drawResults();renderInspectorPreview();
      }
      drawScreen();drawBench();renderInspectorPreview();status(`Calculated · ${r.params.gridSize===512?'fine':'fast'} detail · ${fmt(data.elapsed/1000,1)} s`);
    }
  });setBusy();
}

function drawYZ(){
  const c=$('yz-canvas'),width=c.clientWidth,height=c.clientHeight;
  // Standard hides the entire section. Keep the last valid drawing rather than
  // replacing it with a one-pixel buffer and collapsed SVG coordinates.
  if(!(width>0&&height>0))return;
  const ratio=Math.min(devicePixelRatio||1,2);c.width=Math.round(width*ratio);c.height=Math.round(height*ratio);const ctx=c.getContext('2d');ctx.setTransform(ratio,0,0,ratio,0,0);ctx.fillStyle='#071624';ctx.fillRect(0,0,width,height);$('yz-labels').replaceChildren();$('wave-components').replaceChildren();$('wave-regions').replaceChildren();$('wave-regions').hidden=!yzResult||yzResult.scope==='near';syncWaveCursor();
  if(!yzResult){c.setAttribute('aria-label','Wave intensity — not calculated for these settings');$('wave-scale').textContent=$('wave-brightness').value.includes('log')?'−120 → 0 dB · XYZ reference':$('wave-brightness').value==='local'?'0 → 1 · normalized per z':'0 → 1 · XYZ reference';if(activeJob!=='yz')$('wave-status').textContent=waveLoading?'Loading the saved Fine calculation…':`Optics changed or new view selected · click ${$('calculate-yz').textContent}`;if(activeJob!=='yz'){ctx.fillStyle='#687f94';ctx.font='15px system-ui';ctx.textAlign='center';ctx.fillText(waveLoading?'Loading saved Fine wave…':`Click ${$('calculate-yz').textContent} for this view.`,width/2,height/2);}$('yz-note').textContent='XZ: horizontal cut at y = 0. YZ: vertical cut at x = 0. Dark outside the calculation window is canvas background; enable Show calculation window in Settings to see the bounds.';return;}
  const r=waveView(yzResult),section=$('wave-section').value,mode=$('wave-brightness').value,near=r.scope==='near',half=near?r.params.fieldSizeUm*.5e-6:Math.max(r.params.condenserFocalMm*.001*r.params.sourceEmissionNA*1.4,r.geometry.f1*.001*r.params.projNA/r.params.reduction*1.4),w=width,h=height,img=ctx.createImageData(c.width,c.height),cols=r.columns;
  img.data.set(renderWavePixels(r,{width:c.width,height:c.height,half,section,mode,palette:t=>palette(t,'blue'),illuminationPalette:t=>palette(t,'warm'),showWindow:$('wave-window-toggle').checked,projectionCrop:$('projection-display').value==='lenses',displayHeight:height}));
  ctx.putImageData(img,0,0);drawWaveMarkers(r,width,height);
  $('wave-regions').hidden=near;if(!near)$('wave-regions').innerHTML=regionMarkup(r.geometry);
  $('yz-labels').classList.toggle('full-path',!near);const labels=near?[[r.zMin,'0'],[(r.zMin+r.zMax)/2,'100 µm'],[r.zMax,'200 µm after mask']]:[0,100,200,300,400,r.zMax].filter((v,i,a)=>a.indexOf(v)===i&&v<=r.zMax).map(v=>[v,`${fmt(v)}${v===r.zMax?' mm':''}`]);$('yz-labels').innerHTML=labels.map(([at,name])=>`<span style="left:${(at-r.zMin)/(r.zMax-r.zMin)*100}%">${name}</span>`).join('');
  $('yz-note').textContent=`${r.params.gridSize} × ${r.params.gridSize} mask grid · ${r.samples} emitter${r.samples===1?'':'s'} · ${cols.length} z planes. Display interpolated between calculated planes; Dark outside the calculation window is background; enable Show calculation window in Settings to see its bounds. ${mode==='local'?'Each column is normalized; brightness cannot be compared along z.':'Fixed XYZ reference; intensities above it are clipped.'}`;
  $('wave-scale').textContent=mode.includes('log')?'−120 → 0 dB · XYZ reference':mode==='local'?'0 → 1 · normalized per z':'0 → 1 · XYZ reference';
  syncWaveCursor();c.setAttribute('aria-label',`${section.toUpperCase()} wave intensity, ${near?'0 to 200 micrometres after mask':'full optical path'}`);
}
function drawWaveMarkers(r,width,height){
  const overlay=$('wave-components');overlay.setAttribute('viewBox',`0 0 ${width} ${height}`);overlay.style.height=`${height}px`;
  overlay.innerHTML=waveComponentSVG(r,width,height);
}
let paintKind='pupil',paintArray=null,paintValue=1,painting=false,paintX=16,paintY=16;
function ensurePaint(kind){const key=kind==='source'?'customSource':'customPupil';if(!p[key])p[key]=Array.from({length:32*32},(_,k)=>Math.hypot(k%32-15.5,Math.floor(k/32)-15.5)<13?1:0);}
function openPaint(kind){paintKind=kind;ensurePaint(kind);paintArray=[...p[kind==='source'?'customSource':'customPupil']];$('paint-title').textContent=kind==='source'?'Paint the light source':'Paint the aperture opening';$('paint-description').textContent=kind==='source'?'Paint the source distribution. White emits light; black does not.':'Paint the aperture opening. White transmits; black blocks.';$('paint-white').textContent=kind==='source'?'Light':'Transmit';$('paint-black').textContent=kind==='source'?'Dark':'Block';$('paint-canvas').tabIndex=0;$('paint-dialog').showModal();paintRender();}
function paintRender(){paintImage($('paint-canvas'),paintArray,32,null,'mono',1,true);}
function dab(x,y){for(let yy=y-1;yy<=y+1;yy++)for(let xx=x-1;xx<=x+1;xx++)if(xx>=0&&xx<32&&yy>=0&&yy<32)paintArray[yy*32+xx]=paintValue;paintRender();}
function paintEvent(e){const r=$('paint-canvas').getBoundingClientRect();paintX=Math.floor((e.clientX-r.left)/r.width*32);paintY=31-Math.floor((e.clientY-r.top)/r.height*32);dab(paintX,paintY);}
$('paint-canvas').addEventListener('pointerdown',e=>{painting=true;e.target.setPointerCapture(e.pointerId);paintEvent(e);});$('paint-canvas').addEventListener('pointermove',e=>{if(painting)paintEvent(e);});$('paint-canvas').addEventListener('pointerup',()=>painting=false);$('paint-canvas').addEventListener('pointercancel',()=>painting=false);$('paint-canvas').addEventListener('keydown',e=>{const m={ArrowLeft:[-1,0],ArrowRight:[1,0],ArrowUp:[0,1],ArrowDown:[0,-1]};if(m[e.key]){e.preventDefault();paintX=Math.max(0,Math.min(31,paintX+m[e.key][0]));paintY=Math.max(0,Math.min(31,paintY+m[e.key][1]));paintRender();const ctx=$('paint-canvas').getContext('2d');ctx.strokeStyle='#e5a638';ctx.lineWidth=2;ctx.strokeRect(paintX*12,(31-paintY)*12,12,12);}else if(e.key===' '){e.preventDefault();dab(paintX,paintY);}});
for(const [id,value]of [['paint-white',1],['paint-black',0]])$(id).addEventListener('click',()=>{paintValue=value;$('paint-white').setAttribute('aria-pressed',String(value===1));$('paint-black').setAttribute('aria-pressed',String(value===0));});$('paint-clear').onclick=()=>{paintArray.fill(0);paintRender();};$('paint-fill').onclick=()=>{paintArray.fill(1);paintRender();};$('close-paint').onclick=()=>$('paint-dialog').close();$('paint-apply').onclick=()=>{p[paintKind==='source'?'customSource':'customPupil']=[...paintArray];$('paint-dialog').close();markChanged();renderInspector();};
$('open-profile').onclick=()=>{$('profile-dialog').showModal();drawProfile();};$('close-profile').onclick=()=>$('profile-dialog').close();
$('enable-intensity-profile').addEventListener('change',drawScreen);
$('open-observation-zoom').onclick=()=>{if(!screenResult)return;if(benchEditor.compact){drawObservationZoom();sliceShare.open($('observation-zoom-canvas'),screenResult.z);}else{$('observation-zoom-dialog').showModal();drawObservationZoom();}};$('close-observation-zoom').onclick=()=>$('observation-zoom-dialog').close();$('observation-zoom-dialog').addEventListener('close',()=>{(zoomReturn||$('open-observation-zoom')).focus({preventScroll:true});zoomReturn=null;});
$('return-focus').onclick=()=>setFineOffset(0);
let returnToSettings=false;$('model-button').onclick=()=>{returnToSettings=$('display-dialog').open;if(returnToSettings)$('display-dialog').close();$('app-menu').open=false;$('model-dialog').showModal();};$('model-dialog').addEventListener('close',()=>{if(returnToSettings){returnToSettings=false;$('display-dialog').showModal();}else $('app-menu').querySelector('summary').focus({preventScroll:true});});$('close-model').onclick=()=>$('model-dialog').close();for(const d of document.querySelectorAll('dialog'))d.addEventListener('click',e=>{if(e.target===d){const b=d.getBoundingClientRect();if(e.clientX<b.left||e.clientX>b.right||e.clientY<b.top||e.clientY>b.bottom)d.close();}});
$('calculate').onclick=()=>batch?.active?cancelScreens():computeSlices(true);$('show-slice').onclick=()=>batch?.active?cancelScreens():computeSlices();$('cancel-screen').onclick=cancelScreens;$('cancel').onclick=()=>cancel();$('calculate-yz').onclick=()=>{if(jobs.has('wave')){jobs.cancel('wave');status('Wave calculation cancelled.');}else calculate('yz');};for(const id of ['brightness','pupil-view','source-view','mask-view'])$(id).onchange=()=>{drawResults();drawScreen();drawBench();renderInspectorPreview();$('brightness-help').textContent=$('brightness').value.startsWith('shared')?'Intensity views share one reference scale. Openings and emitter weights use their own scale.':'Each view has its own brightness scale; compare shape, not absolute intensity.';};for(const id of ['wave-section','wave-brightness','wave-window-toggle','projection-display'])$(id).onchange=drawYZ;for(const id of ['wave-scope','wave-detail'])$(id).onchange=()=>{jobs.cancel('wave');waveRequest++;waveLoading=false;yzResult=null;drawYZ();if(id==='wave-scope'&&$('wave-scope').value==='near'){$('wave-section').value='xz';$('wave-section').dispatchEvent(new Event('change'));}restoreDefaultWave();};
$('plane').onchange=()=>{const plane=$('plane').value,g=geometry(p);setPosition(plane==='custom'?currentZ():plane==='near'?g.mask+.001:g[plane],plane);};$('slice-z').oninput=()=>fieldEdits.z=true;$('slice-z').onchange=()=>{if($('slice-z').value.trim()===''){syncScreen();return;}setPosition(Number($('slice-z').value));};$('screen-slider').oninput=()=>setPosition(Number($('screen-slider').value));
for(const b of document.querySelectorAll('[data-rays]'))b.onclick=()=>{rayMode=b.dataset.rays;for(const t of document.querySelectorAll('[data-rays]')){t.classList.toggle('active',t===b);t.setAttribute('aria-pressed',String(t===b));}drawBench();};
function preset(name){
  cancelInterpolation();cancel(false);const choice=presetDefinition(name);p=presetParams(choice.id);selected=choice.selected;
  planes=createPlanes();activeId=benchEditor.compact&&!viewTabs.keyView?'D':null;lastPosition=geometry(p).image;positionGestureStart=null;positionGestureSource=null;positionHistory.clear(positionSnapshot(planes,activeId,lastPosition));syncPositionHistoryButtons();observationUI.removed(null);observationUI.render();
  revision++;sliceCache.clear();fixedImageSaved=null;waveRequest++;waveLoading=false;result=null;yzResult=null;drawYZ();renderInspector();renderFocus();drawBench();syncScreen();drawScreen();updatePresetInfo();restorePresetSlices(choice.id);restoreDefaultWave();
}

$('preset').onchange=()=>preset($('preset').value);
$('reset').onclick=async()=>{
  cancel(false);
  if(window.OpticalBenchNative?.clearAutosave)await window.OpticalBenchNative.clearAutosave();
  // A fresh page also clears edited patterns, removed planes, workers, and
  // dialog state. Clear browser-restored form values before that fresh start.
  for(const select of document.querySelectorAll('select'))select.selectedIndex=Math.max(0,[...select.options].findIndex(option=>option.defaultSelected));
  for(const input of document.querySelectorAll('input')){input.value=input.defaultValue;input.checked=input.defaultChecked;}
  for(const details of document.querySelectorAll('details'))details.open=false;
  window.scrollTo(0,0);window.location.reload();
};
$('yz-canvas').onclick=e=>{if(!yzResult)return;const r=e.target.getBoundingClientRect(),view=waveView(yzResult);selectWavePosition(view.zMin+(e.clientX-r.left)/r.width*(view.zMax-view.zMin));};
window.addEventListener('resize',()=>requestAnimationFrame(()=>{drawBench();drawYZ();drawScreen();if($('profile-dialog').open)drawProfile();}));
// Revealing the section and opening/closing settings can change its available
// size without a window resize (for example when a scrollbar appears).
const waveResizeObserver=new ResizeObserver(()=>requestAnimationFrame(drawYZ));
waveResizeObserver.observe($('yz-canvas'));
$('component-picker').onchange=()=>{selected=$('component-picker').value;renderInspector();drawBench();};
const waveKeys=e=>{if(!yzResult)return;if(['ArrowLeft','ArrowRight','Home','End'].includes(e.key)){e.preventDefault();const view=waveView(yzResult),step=(view.zMax-view.zMin)/(e.shiftKey?1000:100);selectWavePosition(e.key==='Home'?view.zMin:e.key==='End'?view.zMax:Math.min(view.zMax,Math.max(view.zMin,currentZ()+(e.key==='ArrowRight'?step:-step))));}};
$('yz-canvas').onkeydown=waveKeys;$('wave-cursor').onkeydown=waveKeys;
let waveDrag=null;
const waveCursor=$('wave-cursor');
waveCursor.addEventListener('pointerdown',e=>{if(!yzResult||!activePlane()||e.button!==0||!e.isPrimary)return;e.preventDefault();waveDrag=e.pointerId;waveCursor.setPointerCapture(e.pointerId);beginPositionGesture('wave');});
waveCursor.addEventListener('pointermove',e=>{if(waveDrag!==e.pointerId||!yzResult)return;e.preventDefault();const box=$('yz-canvas').getBoundingClientRect(),view=waveView(yzResult),fraction=Math.max(0,Math.min(1,(e.clientX-box.left)/box.width));selectWavePosition(view.zMin+fraction*(view.zMax-view.zMin));});
const finishWaveDrag=e=>{if(waveDrag!==e.pointerId)return;waveDrag=null;if(waveCursor.hasPointerCapture(e.pointerId))waveCursor.releasePointerCapture(e.pointerId);endPositionGesture('wave');};
for(const event of ['pointerup','pointercancel','lostpointercapture'])waveCursor.addEventListener(event,finishWaveDrag);
setupScreenDrag($('bench'),{geometry:()=>geometry(p),currentZ,onMove:setPosition,onSelect:selectObservation,onStart:()=>viewTabs.showObservation(),compact:()=>benchEditor.compact,onDragStart(id,z){beginPositionGesture('beam',id||activeId);dragLayout={id,z,labels:Object.fromEntries([...$('bench').querySelectorAll('[data-position-marker]')].map(el=>[el.dataset.positionMarker,Number(el.dataset.labelX)]))};},onDragEnd(){dragLayout=null;endPositionGesture('beam');drawBench();}});
function syncDetailControls(){
  for(const toggle of document.querySelectorAll('[data-high-detail]'))toggle.checked=details.get(compactMedia.matches,viewTabs.keyView);
}
for(const toggle of document.querySelectorAll('[data-high-detail]'))toggle.addEventListener('change',()=>{
  details.set(compactMedia.matches,viewTabs.keyView,toggle.checked);syncDetailControls();drawScreen();setBusy();
});
compactMedia.addEventListener('change',()=>{syncDetailControls();placeInterpolationControls();if(compactMedia.matches&&!viewTabs.keyView)cancelInterpolation();});syncDetailControls();
document.addEventListener('position-view-change',()=>{
  if(compactMedia.matches&&!viewTabs.keyView)cancelInterpolation();
  placeInterpolationControls();
  syncDetailControls();

  if(!viewTabs.keyView&&benchEditor.compact&&!activePlane())activeId=planes.find(p=>p.id==='D')?.id||planes[0]?.id||null;

  syncScreen();drawScreen();drawBench();setBusy();
  // The view event precedes completion of the tab/layout update. Draw after
  // Expert becomes visible so canvas and component overlay share its size.
  requestAnimationFrame(drawYZ);
});
function deselectObservation(){if(benchEditor.compact)return;cancelInterpolation();activeId=null;refreshObservations();}
$('observation-panel').addEventListener('click',e=>{if(!e.target.closest('button,input,select,a,summary,dialog'))deselectObservation();});
$('bench').addEventListener('click',e=>{if(!e.target.closest('[data-component],[data-label],[data-observation],[data-observation-screen]'))deselectObservation();});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!document.querySelector('dialog[open]')){if(interpolationMode){cancelInterpolation();interpolateButton.focus({preventScroll:true});}else deselectObservation();}});
tuningInteraction=setupRelativeTuning($('relative-tuning'),{currentZ,maximum:()=>geometry(p).image,enabled:()=>!!activePlane(),target:()=>activePlane()?.instance,settings:()=>({slow:Number($('tuning-slow-speed').value),fast:Number($('tuning-fast-speed').value),glide:Number($('tuning-glide').value)}),onMove:setPosition,onActiveChange:active=>{if(active)beginPositionGesture('tuning');else endPositionGesture('tuning');$('bench').classList.toggle('tuning-screen',active);}});
benchEditor.start();renderInspector();renderFocus();viewTabs.adapt();placeInterpolationControls();drawBench();syncScreen();drawYZ();updatePresetInfo();restoreDefaultWave();restorePresetSlices('default');

function renderFocus(){
  $('focus-control').innerHTML='<div class="control"><label for="tuning-number"><span class="sr-only">Fine tuning offset</span><span class="number-field"><span aria-hidden="true">Δz</span><input id="tuning-number" aria-label="Fine tuning offset in micrometres" type="number" inputmode="decimal" min="-2500" max="2500" step="1" value="0"><span class="field-unit" aria-hidden="true">µm</span></span></label><input id="tuning-range" aria-label="Fine tuning" type="range" min="-2500" max="2500" step="1" value="0"></div>';
  $('tuning-number').oninput=()=>fieldEdits.offset=true;$('tuning-range').oninput=()=>setFineOffset(Number($('tuning-range').value));$('tuning-number').onchange=()=>{if($('tuning-number').value.trim()===''){syncFocus();return;}setFineOffset(Number($('tuning-number').value));};syncFocus();
}
function panelState(panel){
  if(!panel)return '';
  if(jobs.current?.job.request?.instance===panel.instance&&jobs.current.job.kind!=='yz')return panel.progress==null?'Calculating…':`${panel.progress}%`;
  if(jobs.has('screen-'+panel.id))return 'Queued';
  if(panel.error)return 'Try again';
  return sameSlice(panel.result,screenParams(),observationZ(panel,geometry(p)))?(panel.result.params.gridSize<512?'Fast':''):'Needs update';
}

// The native app stores only a small experiment description, never the large
// numerical arrays. Restored pictures must be recalculated or loaded from a
// matching bundled preset before they can be called current.
function experimentSnapshot(){
  const value=id=>$(id).value;
  return {version:1,params:p,selected,rayMode,positions:planes.map(({id,plane,base,offset})=>({id,plane,base,offset})),activeId,keyView:viewTabs.keyView,
    detail:{standard:details.standard,expert:details.expert},
    display:{brightness:value('brightness'),sourceView:value('source-view'),maskView:value('mask-view'),pupilView:value('pupil-view'),smooth:$('smooth-intensity').checked,imageScale:value('image-scale'),fixedWidth:Number(value('fixed-image-width')),scaleBars:$('show-scale-bars').checked,imageDetails:$('show-image-details').checked,fineRange:Number(value('fine-range')),compareIntensity:$('compare-intensity').checked,tuningSlow:value('tuning-slow-speed'),tuningFast:value('tuning-fast-speed'),tuningGlide:value('tuning-glide')},
    wave:{scope:value('wave-scope'),detail:value('wave-detail'),section:value('wave-section'),brightness:value('wave-brightness'),elements:$('wave-elements-toggle').checked,window:$('wave-window-toggle').checked,projectionDisplay:value('projection-display')}};
}
function restoreExperiment(saved){
  if(saved?.version!==1||!saved.params||!Array.isArray(saved.positions)||saved.positions.length<1||saved.positions.length>16)return false;
  cancelInterpolation();
  const next={...presetParams('default')};
  for(const key of Object.keys(next))if(Object.hasOwn(saved.params,key))next[key]=saved.params[key];
  try{validate({...next,...QUALITY.fine});}catch{return false;}
  const names=new Set(),g=geometry(next),allowed=new Set([...Object.keys(PLANE_NAMES)]),positions=[];
  for(const item of saved.positions){
    if(!item||typeof item.id!=='string'||!/^([A-Z]|A[A-Z])$/.test(item.id)||names.has(item.id)||!allowed.has(item.plane)||!Number.isFinite(item.base)||!Number.isFinite(item.offset))return false;
    names.add(item.id);const panel=createPlane(item.id,item.plane,Math.max(0,Math.min(g.max,item.base)));
    tuneObservation(panel,g,item.offset);positions.push(panel);
  }
  cancel(false);p=next;selected=components.some(component=>component[0]===saved.selected)?saved.selected:'pupil';
  planes=positions;activeId=names.has(saved.activeId)?saved.activeId:positions[0].id;lastPosition=observationZ(activePlane(),g);positionGestureStart=null;positionGestureSource=null;positionHistory.clear(positionSnapshot(planes,activeId,lastPosition));syncPositionHistoryButtons();
  revision++;presetTicket++;waveRequest++;waveLoading=false;result=null;screenResult=null;screenRevision=-1;yzResult=null;fixedImageSaved=null;sliceCache.clear();
  details.standard=!!saved.detail?.standard;details.expert=saved.detail?.expert!==false;
  const select=(id,choice)=>{const node=$(id);if([...node.options].some(option=>option.value===choice))node.value=choice;};
  select('brightness',saved.display?.brightness);select('source-view',saved.display?.sourceView);select('mask-view',saved.display?.maskView);select('pupil-view',saved.display?.pupilView);
  select('tuning-slow-speed',saved.display?.tuningSlow);select('tuning-fast-speed',saved.display?.tuningFast);select('tuning-glide',saved.display?.tuningGlide);
  $('smooth-intensity').checked=saved.display?.smooth!==false;
  select('image-scale',saved.display?.imageScale||(saved.display?.compareSize===false?'auto':'illumination'));
  for(const [id,key,min,max]of [['fixed-image-width','fixedWidth',.001,1000],['fine-range','fineRange',.001,100]]){const value=saved.display?.[key];if(Number.isFinite(value)&&value>=min&&value<=max)$(id).value=value;}
  $('show-scale-bars').checked=saved.display?.scaleBars!==false;$('show-image-details').checked=saved.display?.imageDetails===true;
  $('fixed-width-label').hidden=$('image-scale').value!=='fixed';document.body.classList.toggle('show-image-details',$('show-image-details').checked);
  $('compare-intensity').checked=saved.display?.compareIntensity===true;
  select('projection-display',saved.wave?.projectionDisplay||'lenses');select('wave-scope',saved.wave?.scope);select('wave-detail',saved.wave?.detail);select('wave-section',saved.wave?.section);select('wave-brightness',saved.wave?.brightness);
  $('wave-elements-toggle').checked=saved.wave?.elements!==false;$('wave-window-toggle').checked=!!saved.wave?.window;
  rayMode=['principal','many','none'].includes(saved.rayMode)?saved.rayMode:'principal';
  for(const button of document.querySelectorAll('[data-rays]')){button.classList.toggle('active',button.dataset.rays===rayMode);button.setAttribute('aria-pressed',String(button.dataset.rays===rayMode));}
  $('preset').value=matchingPreset(p)?.id||'';
  observationUI.removed(null);observationUI.render();
  if(benchEditor.compact&&saved.keyView)$('view-fixed').click();else if(benchEditor.compact)$('view-explore').click();
  renderInspector();renderFocus();syncDetailControls();drawBench();syncScreen();drawScreen();drawYZ();setBusy();updatePresetInfo();
  const presetId=matchingPreset(p)?.id;
  if(presetId){restorePresetSlices(presetId);restoreDefaultWave();}
  else status('Experiment restored · compute to update images.');
  return true;
}
window.OpticalBenchSession={snapshot:experimentSnapshot,restore:restoreExperiment};
window.dispatchEvent(new Event('optical-bench-ready'));
function screenMoved(){
  if(!$('observation-grid'))return;
  $('reference-positions').setAttribute('aria-pressed',String(atReferencePositions(planes)));
  for(const panel of planes){const button=$('slice-panel-'+panel.id);$('zoom-position-'+panel.id).disabled=!panel.result;button.setAttribute('aria-pressed',String(panel.id===activeId));button.disabled=false;$('slice-state-'+panel.id).textContent=panelState(panel);$('slice-state-'+panel.id).classList.toggle('fast-detail',panelState(panel)==='Fast');$('slice-state-'+panel.id).title=panel.error||'';const changed=panel.result&&!sameSlice(panel.result,screenParams(),observationZ(panel,geometry(p)));$('slice-target-'+panel.id).textContent=changed?`Target: ${fmt(observationZ(panel,geometry(p)),3)} mm`:'';}
  $('observation-state').textContent=panelState(activePlane());$('observation-state').classList.toggle('fast-detail',panelState(activePlane())==='Fast');$('screen-status').hidden=true;$('screen-status').textContent='';
}
function illuminationPeers(){

  return planes.filter(panel=>panel.result&&panel.result.z<panel.result.geometry.mask&&displayMode(panel)==='intensity'&&sameSlice(panel.result,screenParams(),observationZ(panel,geometry(p)))).map(panel=>panel.result);
}
function screenScale(panel){return panel?.result?comparisonScale(panel.result,illuminationPeers(),{size:$('image-scale').value==='illumination',intensity:$('compare-intensity').checked,fixedWidth:$('image-scale').value==='fixed'?Number($('fixed-image-width').value)*.001:null}):{};}
function paintScaleBar(canvas,width){
  const bar=scaleBar(width);if(!bar||!$('show-scale-bars').checked)return;
  const ctx=canvas.getContext('2d'),u=canvas.width/(canvas.clientWidth||320),x=12*u,y=canvas.height-14*u,len=bar.fraction*(canvas.width-1);
  ctx.save();ctx.font=`${11*u}px system-ui`;ctx.textAlign='left';
  ctx.fillStyle='#071624cc';ctx.fillRect(x-5*u,y-24*u,Math.max(len,ctx.measureText(bar.label).width)+10*u,32*u);
  ctx.fillStyle='#eef8ff';ctx.fillText(bar.label,x,y-8*u);ctx.strokeStyle='#eef8ff';ctx.lineWidth=1.5*u;
  ctx.beginPath();ctx.moveTo(x,y-3*u);ctx.lineTo(x,y+3*u);ctx.moveTo(x,y);ctx.lineTo(x+len,y);ctx.moveTo(x+len,y-3*u);ctx.lineTo(x+len,y+3*u);ctx.stroke();ctx.restore();
}
function windowLabel(r,half=r.screenHalf){const width=half?2*half:r.screenAxis.at(-1)-r.screenAxis[0];return `${width>=.001?fmt(width*1e3)+' mm':fmt(width*1e6)+' µm'} window${r.dark?' · no light':''}`;}
function displayMode(panel){
  return referenceDisplayMode(panel,{source:$('source-view').value,mask:$('mask-view').value,pupil:$('pupil-view').value},!!panel&&sameSlice(panel.result,screenParams(),observationZ(panel,geometry(p))));
}
function displayName(panel){const mode=displayMode(panel);return mode==='weights'?'Source distribution':mode==='mask-opening'?'Mask · Opening':mode==='aperture-opening'?'Aperture · Opening':panel?.result?.label||PLANE_NAMES[panel?.plane]||'';}
function displayWindow(panel){const r=panel?.result;if(!r)return '';const mode=displayMode(panel);return mode==='weights'?'Normalized source coordinates':mode==='mask-opening'?`${fmt(r.params.fieldSizeUm)} µm window`:mode==='aperture-opening'?'Normalized aperture coordinates':windowLabel(r,screenScale(panel).half);}
function paintScreen(canvas,panel){
  if(canvas.closest('#observation-grid')&&!visibleCards.has(canvas))return;
  const pixels=Math.min(960,Math.max(320,Math.round((canvas.clientWidth||320)*Math.min(devicePixelRatio||1,2))));if(canvas.width!==pixels){canvas.width=canvas.height=pixels;delete canvas.dataset.renderKey;}
  const r=panel?.result,mode=displayMode(panel),scale=screenScale(panel),renderKey=(panel?.resultKey||'empty')+':'+$('brightness').value+':'+(panel?.instance||0)+':'+mode+':'+$('smooth-intensity').checked+':'+scale.half+':'+scale.peak+':'+$('show-scale-bars').checked+':'+canvas.clientWidth;if(canvas.dataset.renderKey===renderKey)return;
  canvas.dataset.renderKey=renderKey;
  if(!r){const ctx=canvas.getContext('2d');ctx.fillStyle='#071624';ctx.fillRect(0,0,canvas.width,canvas.height);ctx.fillStyle='#94acbf';ctx.font='16px system-ui';ctx.textAlign='center';ctx.fillText(panel?.pending?'Calculating…':panel?'Select and compute slice':'Add a position',canvas.width/2,canvas.height/2);return;}
  if(mode==='weights'){paintImage(canvas,arrayPicture('source',r.params),128,null,'mono');return;}
  if(mode==='mask-opening'){paintImage(canvas,makeMask(r.params),r.params.gridSize,null,'mono',1);paintScaleBar(canvas,r.params.fieldSizeUm*1e-6);return;}
  if(mode==='aperture-opening'){paintImage(canvas,arrayPicture('pupil',r.params),128,null,'mono',1);return;}
  paintImage(canvas,r.screenRaw,r.screenAxis.length,r.screenAxis,lightRegion(r.z,r.geometry),scale.peak??($('brightness').value.startsWith('shared')?r.sharedPeak:null),true,scale.half,Math.abs(r.z-r.geometry.pupil)<1e-8?{params:r.params,radius:r.geometry.f2*.001*r.params.projNA}:null,r.screenAxisY||r.screenAxis);
  paintScaleBar(canvas,scale.half?2*scale.half:r.screenAxis.at(-1)-r.screenAxis[0]);
}
function drawScreen(){
  loadActiveScreen();
  for(const panel of planes){
    const r=panel.result;paintScreen($('slice-canvas-'+panel.id),panel);$('slice-label-'+panel.id).textContent=displayName(panel);$('slice-canvas-'+panel.id).setAttribute('aria-label',`${panel.id} · ${displayName(panel)} · ${displayMode(panel)==='intensity'?'Light intensity':'Reference display'}`);$('slice-position-'+panel.id).textContent=r?`z = ${fmt(r.z,3)} mm`:'Not calculated';$('slice-axis-'+panel.id).textContent=displayWindow(panel);
    $('slice-panel-'+panel.id).setAttribute('aria-label',`Select observation ${panel.id}${r?' · '+r.label+' · '+fmt(r.z,3)+' mm':''}`);
  }
  paintScreen($('observation-canvas'),activePlane());const r=screenResult;
  $('observation-label').textContent=(benchEditor.compact?'':activeId+' · ')+displayName(activePlane());$('observation-z').textContent=r?`z = ${fmt(r.z,3)} mm`:'Not calculated';$('observation-axis').textContent=displayWindow(activePlane());
  $('open-profile').disabled=(!benchEditor.compact&&!$('enable-intensity-profile').checked)||!r||displayMode(activePlane())!=='intensity';$('open-profile').title=displayMode(activePlane())==='intensity'?'':'Available for light intensity';$('open-observation-zoom').disabled=!r;screenMoved();if($('profile-dialog').open)drawProfile();if($('observation-zoom-dialog').open)drawObservationZoom();
}
function drawObservationZoom(){
  if(!screenResult)return;const r=screenResult;
  paintScreen($('observation-zoom-canvas'),activePlane());
  $('observation-zoom-position').textContent=`${benchEditor.compact?'':activeId+' · '}${displayName(activePlane())} · z = ${fmt(r.z,3)} mm${displayMode(activePlane())==='intensity'?' · '+displayWindow(activePlane()):''}`;
}


function syncWaveCursor(){
  const cursor=$('wave-cursor'),at=currentZ(),view=yzResult?waveView(yzResult):null;
  $('slice-z').title=at>geometry(p).image?'Beyond the Image plane, outside the main diagram.':'';
  const notice=$('path-range-notice');notice.hidden=!activePlane()||at<=geometry(p).image;notice.textContent=notice.hidden?'':`Observation z = ${fmt(at,3)} mm · beyond Image, outside the main diagram.`;
  cursor.hidden=!activePlane()||!view||at<view.zMin||at>view.zMax;
  $('wave-components').classList.toggle('screen-at-image',!cursor.hidden&&Math.abs(at-view.geometry.image)<1e-8);
  if(cursor.hidden)return;
  cursor.setAttribute('aria-valuemin',String(view.zMin));cursor.setAttribute('aria-valuemax',String(view.zMax));cursor.setAttribute('aria-valuenow',String(at));cursor.setAttribute('aria-valuetext',`${fmt(at,3)} millimetres`);
  cursor.style.height=`${$('yz-canvas').clientHeight}px`;
  const percent=100*(at-view.zMin)/(view.zMax-view.zMin);cursor.style.left=`${percent}%`;

}
function selectWavePosition(at){if(!activePlane())return;setPosition(at);syncWaveCursor();}
