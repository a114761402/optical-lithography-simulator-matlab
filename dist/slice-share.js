// Prepare the PNG before a share-button click so native sharing keeps user activation.
export function fileShareAvailable(file,navigatorLike=navigator){
  try{return !!(navigatorLike.share&&navigatorLike.canShare?.({files:[file]}));}catch{return false;}
}
export async function shareSliceFile(file,navigatorLike=navigator){
  if(!fileShareAvailable(file,navigatorLike))return 'unsupported';
  try{await navigatorLike.share({files:[file],title:'Optical Bench observation'});return 'shared';}
  catch(error){if(error.name==='AbortError')return 'cancelled';throw error;}
}
export function setupSliceShare(){
  const $=id=>document.getElementById(id),dialog=$('send-dialog');let file=null,url=null,ticket=0;
  function clear(){ticket++;file=null;if(url)URL.revokeObjectURL(url);url=null;}
  $('close-send').onclick=()=>dialog.close();dialog.addEventListener('close',()=>{clear();$('open-observation-zoom').focus({preventScroll:true});});
  $('save-slice').onclick=()=>{if(!file||!url)return;const a=document.createElement('a');a.href=url;a.download=file.name;document.body.append(a);a.click();a.remove();$('send-status').textContent='PNG ready to save. Check your browser downloads.';};
  $('share-slice').onclick=async()=>{
    if(!file)return;$('share-slice').disabled=true;
    try{const state=await shareSliceFile(file);if(state==='shared')dialog.close();else if(state==='unsupported')$('send-status').textContent='Save the PNG, then attach it in your email app.';}
    catch{$('send-status').textContent='Sharing is unavailable here. Save the PNG instead.';}
    finally{$('share-slice').disabled=false;}
  };
  return {open(canvas,z){
    clear();const current=ticket;dialog.showModal();$('send-status').textContent='Preparing image…';$('save-slice').disabled=true;$('share-slice').hidden=true;$('email-slice').hidden=true;
    const name=`optical-bench-z-${Number(z.toFixed(6))}mm.png`;
    canvas.toBlob(blob=>{
      if(current!==ticket||!dialog.open)return;
      if(!blob){$('send-status').textContent='Image could not be prepared. Close and try again.';return;}
      file=new File([blob],name,{type:'image/png'});url=URL.createObjectURL(blob);$('send-preview').src=url;$('save-slice').disabled=false;
      const native=fileShareAvailable(file);$('share-slice').hidden=!native;$('email-slice').hidden=native;
      $('email-slice').href='mailto:?subject='+encodeURIComponent('Optical Bench observation')+'&body='+encodeURIComponent(`Observation at z = ${Number(z.toFixed(6))} mm.\n\nAttach the saved image: ${name}`);
      $('send-status').textContent=native?'Save the image, or choose an app to share it.':'To email this image, save the PNG first and attach it to your message.';
    },'image/png');
  }};
}
