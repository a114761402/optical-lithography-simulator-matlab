import {STARTUP_PARAMS} from './cache.js?v=20260927-illumination2';
import {QUALITY} from './quality.js?v=20260927-illumination2';
export const PRESETS=[
  {id:'default',name:'Default · Three-line imaging',description:'The original circular-source, circular-aperture, 4× reduction bench.',selected:'mask',changes:{}},
  {id:'filtering',name:'4f spatial filtering',description:'On-axis coherent illumination. A smaller circular projection aperture suppresses high grating orders. Inspired by the standard 4f spatial-filtering experiment.',selected:'pupil',changes:{sourceType:'Point',projNA:.06,gratingPitchUm:10},source:'MIT · Fourier optics and spatial filtering',url:'https://ocw.mit.edu/courses/2-71-optics-spring-2009/1f37d811580bb5d181f7d51877e4e5ea_MIT2_71S09_lec19.pdf'},
  {id:'diffraction',name:'Circular-aperture diffraction',description:'A coherent source illuminates a circular mask opening. Its Fourier-plane intensity shows the central diffraction spot and rings.',selected:'mask',changes:{sourceType:'Point',maskType:'Circular Aperture',maskSizeUm:20},source:'University of Colorado · Circular-aperture diffraction',url:'https://physicslabs.colorado.edu/demos/optics/diffraction/diffraction-around-objects/diffraction-by-a-circular-aperture/'},
  {id:'annular',name:'Annular illumination',description:'A ring-shaped illumination source with an independent circular projection aperture. Source coordinates here are normalized emitter positions, not a directly specified lithography sigma.',selected:'source',changes:{sourceType:'Annular',sourceInner:.2,sourceOuter:.3},source:'Chris Mack · Off-axis illumination',url:'https://www.lithoguru.com/scientist/litho_tutor/TUTOR42%20%28Aug%2003%29.pdf'},
  {id:'dipole',name:'Dipole illumination',description:'Two illumination lobes along x, perpendicular to the grating lines. The projection aperture remains circular.',selected:'source',changes:{sourceType:'Dipole X',sourceOuter:.08,quadSeparation:.5},source:'Chris Mack · Off-axis illumination',url:'https://www.lithoguru.com/scientist/litho_tutor/TUTOR42%20%28Aug%2003%29.pdf'}
];
export function presetDefinition(id){return PRESETS.find(p=>p.id===id)||PRESETS[0];}
export function presetParams(id){return {...STARTUP_PARAMS,...presetDefinition(id).changes,...QUALITY.fine,defocusUm:0};}
export const PRESET_CACHE_VERSION='fine-physical-illumination-v2';
export function presetCacheKey(params){return PRESET_CACHE_VERSION+JSON.stringify(Object.keys(params).sort().map(k=>[k,params[k]]));}
export function matchingPreset(params){const key=presetCacheKey({...params,...QUALITY.fine,defocusUm:0});return PRESETS.find(p=>presetCacheKey(presetParams(p.id))===key);}
