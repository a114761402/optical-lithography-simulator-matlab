% Independent MATLAB centreline fixtures at real browser resolutions.
root=fileparts(fileparts(fileparts(mfilename('fullpath'))));addpath(root);lithography_setup;
p=lithography_default_params();p.gridSize=256;p.sourceGridSize=201;p.maxSourceSamples=25;p.propagationPadding=2;p.enforceLimits=false;
cases={};
for k=1:5
 q=p;
 switch k
  case 1, name='point grating 256';q.sourceType='Point';zs=[200,200.001,200.05,200.1,200.2,350,400,410,450];
  case 2, name='circular source 256';zs=[200.001,200.1,450];
  case 3, name='off-axis point';q.sourceType='Point';q.pointSourceU=.25;q.pointSourceV=-.12;zs=[0,60,100,200.001,450];
  case 4, name='fine slit pupil';q.gridSize=512;q.sourceType='Point';q.lensType='Horizontal Slit';q.lensInner=.3;zs=[200.1,400,450];
  case 5, name='annular defocus';q.sourceType='Point';q.lensType='Annular';q.lensInner=.6;q.defocusUm=10;zs=[450.01];
 end
 r=lithography_run_physics(q);cols={};
 for z=zs
  a=lithography_compute_xy_slice(q,r,z);x=a.axisM;y=x;if isfield(a,'axisYM'),y=a.axisYM;end
  xz=interp1(y(:),a.rawIntensity,0,'linear',0);yz=interp1(x(:),a.rawIntensity.',0,'linear',0);
  cols{end+1}=struct('z',z,'x',x,'y',y,'xz',xz,'yz',yz);
 end
 cases{end+1}=struct('name',name,'params',q,'columns',{cols},'sharedPeak',r.xyzReferencePeak);
end
fid=fopen(fullfile(fileparts(mfilename('fullpath')),'matlab-wave-reference.json'),'w');fprintf(fid,'%s',jsonencode(cases));fclose(fid);
fprintf('Exported %d wave scenarios.\n',numel(cases));
