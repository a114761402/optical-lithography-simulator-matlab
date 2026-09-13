function yz=lithography_wave_yz_preview(p,r,progress)
% Wave centreline on a physical (mm) mesh. Internal sampling windows may vary,
% but their real coordinates are retained; there is no per-column display zoom.
% Extended sources use reduced quadrature ONLY in this explicitly labelled preview.
if nargin<3,progress=[];end
g=r.geometry;
q=p;q.enforceLimits=false;q.maxSourceSamples=25;
preview=lithography_run_physics(q);
z=lithography_preview_z_grid(p,g);
y=linspace(-1,1,201);raw=zeros(numel(y),numel(z));half=zeros(size(z));
physicalY=zeros(size(raw));
for j=1:numel(z)
    if z(j)<g.zField
        s=lithography_illumination_wave_slice(p,r,z(j));
    else
        s=lithography_compute_xy_slice(q,preview,z(j));
    end
    ax=s.axisM;ay=s.axisM;
    if isfield(s,'axisXM'),ax=s.axisXM;ay=s.axisYM;end
    sampleY=linspace(ay(1),ay(end),numel(y));
    if isfield(s,'displayHalfWidthM'),sampleY=y*s.displayHalfWidthM;end
    half(j)=max(abs(sampleY));physicalY(:,j)=sampleY(:)*1e3;
    % Evaluate the x=0 centreline, not the nearest non-centred FFT pixel.
    profile=interp1(ax,s.rawIntensity.',0,'linear',0).';
    raw(:,j)=interp1(ay,profile,sampleY,'linear',0);
    if ~isempty(progress),progress(j,numel(z));end
end
if strcmp(p.intensityNorm,'Local')
    intensity=raw./max(max(raw,[],1),realmin);scale=max(raw,[],1);
else
    scale=r.xyzReferencePeak;intensity=raw/scale;
end
yz=struct('zMm',z,'yNorm',y,'rawIntensity',raw,'intensity',intensity,...
    'axisHalfWidthMm',half*1e3,'yPhysicalMm',physicalY,...
    'mode','Wave preview','view','Physical transverse coordinates',...
    'normalizationMode',p.intensityNorm,'normalizationPeak',scale,...
    'sourceSampleCount',preview.sourceUsedCount,...
    'planes',struct('source',0,'condenser',g.zCondenser,'field',g.zField,...
    'projection1',g.zProjection1,'pupil',g.zPupil,'projection2',g.zProjection2,'image',g.zImage));
end
