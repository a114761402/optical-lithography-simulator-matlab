function lithography_full_path_display_test(outputDir)
% Scientific figures from the actual full-path computation, no GUI session touched.
if nargin<1,outputDir=fullfile(tempdir,'lithography-full-path-validation');end
if ~exist(outputDir,'dir'),mkdir(outputDir);end
p=lithography_check_settings(lithography_reference_params());r=lithography_run_physics(p);g=r.geometry;
p.intensityNorm='Local';
fig=figure('Visible','off','Color','w','Position',[30,30,1500,760]);cleanup=onCleanup(@()delete(fig));
if isprop(fig,'Theme'),set(fig,'Theme','light');end
t=tiledlayout(fig,2,4,'Padding','compact','TileSpacing','compact');
positions=[0,.001,g.zCondenser-1e-6,g.zCondenser,g.zField,g.zField+.001,g.zPupil,g.zImage];
labels={'Source plane','1 um after source','Condenser entrance','Condenser exit',...
    'Mask exit','1 um after mask','Pupil exit','Detector'};
for j=1:numel(positions)
    s=lithography_compute_xy_slice(p,r,positions(j));ax=nexttile(t);
    x=s.axis;y=s.axis;
    if isfield(s,'axisX'),x=s.axisX;y=s.axisY;end
    unit='um';
    if max(abs(x))>1000,x=x/1000;y=y/1000;unit='mm';end
    imagesc(ax,x,y,s.intensity);axis(ax,'image');axis(ax,'xy');colormap(ax,turbo(256));clim(ax,[0,1]);
    if isfield(s,'displayHalfWidthM')
        half=s.displayHalfWidthM*1e6;if strcmp(unit,'mm'),half=half/1000;end
        xlim(ax,[-half,half]);ylim(ax,[-half,half]);
    end
    title(ax,{labels{j},sprintf('z = %.6f mm',positions(j)),sprintf('Raw peak %.4g',max(s.rawIntensity(:)))},'FontSize',10);
    xlabel(ax,['x (' unit ')']);ylabel(ax,['y (' unit ')']);colorbar(ax);
end
title(t,'Connected full-path wave calculation | local scale for shape ONLY | Gaussian condenser, not hard aperture');
exportgraphics(fig,fullfile(outputDir,'full-path-xy.png'),'Resolution',140);
clf(fig);
yz=lithography_compute_yz_intensity(p,r);ax=axes(fig,'Position',[.08,.2,.78,.6]);
lithography_render_yz_panel(ax,yz);
assert(all(isfinite(yz.rawIntensity(:))) && any(yz.rawIntensity(:)>0));
exportgraphics(fig,fullfile(outputDir,'full-path-preview.png'),'Resolution',140);
save(fullfile(outputDir,'full-path-result.mat'),'p','r','yz');
fprintf('Full-path figures and physical raw data: %s\n',outputDir);
end
