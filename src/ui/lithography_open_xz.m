function fig=lithography_open_xz(params,owner)
% Actual y=0 intensity section, unlike the ray-density overview.
if nargin<2,owner=[];end
p=lithography_check_settings(params);
% Keep the approved spatial grid; only source quadrature is reduced for preview.
p.enforceLimits=false;p.maxSourceSamples=min(params.maxSourceSamples,25);
r=lithography_run_physics(p);
zUm=linspace(0,200,61);
data=zeros(p.gridSize,numel(zUm));
dx=p.fieldSizeUm*1e-6/p.gridSize;
for k=1:numel(r.sourceWeights)
    if r.sourceWeights(k)==0,continue;end
    fields=lithography_coherent_fields(p,r,r.sourceSamplesU(k),r.sourceSamplesV(k));
    for j=1:numel(zUm)
        field=lithography_wave_propagate(fields.mask,p.wavelengthNm*1e-9,dx,zUm(j)*1e-6,4);
        data(:,j)=data(:,j)+r.sourceWeights(k)*abs(field(floor(p.gridSize/2)+1,:)).'.^2;
    end
end
visibility='on';if isgraphics(owner,'figure'),visibility=get(owner,'Visible');end
fig=lithography_plot_figure(owner,'LithographyXZPreview',...
    'Name','XZ diffraction near mask','Visible',visibility);
ax=axes('Parent',fig);
imagesc(ax,zUm,r.objectAxisM*1e6,data);axis(ax,'xy');colormap(ax,'hot');colorbar(ax);
xlabel('Distance AFTER mask (um)');ylabel('x (um), y = 0');
title({sprintf('PREVIEW: %d pixels, %d source samples; cropped ROI',p.gridSize,r.sourceUsedCount),...
    'Source-reduced preview only; use XY slices for full source quadrature'});
end
