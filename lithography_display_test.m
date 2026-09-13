function lithography_display_test(outputFile)
% Small scientific preview; no changes to a user's running GUI or workspace.
if nargin<1,outputFile=fullfile(tempdir,'lithography-display-validation.png');end
p=lithography_check_settings(lithography_reference_params());r=lithography_run_physics(p);
fig=figure('Visible','off','Color','w','Position',[50,50,1300,650]);cleanup=onCleanup(@()delete(fig));
if isprop(fig,'Theme'),set(fig,'Theme','light');end
layout=tiledlayout(fig,2,3,'Padding','compact','TileSpacing','compact');
s=lithography_compute_xy_slice(p,r,0);ax=nexttile(layout);
imagesc(ax,s.axis,s.axis,s.intensity);axis(ax,'image');axis(ax,'xy');
title(ax,'Circular incoherent-emitter source (wave)');xlabel(ax,'x (um)');ylabel(ax,'y (um)');colorbar(ax);clim(ax,[0,1]);
for k=1:3
    z=[0,.001,.1];s=lithography_compute_xy_slice(p,r,r.geometry.zField+z(k));
    ax=nexttile(layout);imagesc(ax,s.axis,s.axis,s.intensity);axis(ax,'image');axis(ax,'xy');colorbar(ax);clim(ax,[0,1]);
    title(ax,{sprintf('After mask: %g um; shared scale',z(k)*1000),sprintf('Actual peak: %.4g',max(s.rawIntensity(:)))});
    xlabel(ax,'x (um)');ylabel(ax,'y (um)');
end
p.intensityNorm='Local';s=lithography_compute_xy_slice(p,r,r.geometry.zField+.1);
ax=nexttile(layout);imagesc(ax,s.axis,s.axis,s.intensity);axis(ax,'image');axis(ax,'xy');colorbar(ax);clim(ax,[0,1]);
title(ax,{'100 um; local scale for shape ONLY','Cropped ROI, not the whole beam'});xlabel(ax,'x (um)');ylabel(ax,'y (um)');
ax=nexttile(layout);plot(ax,s.axis,s.rawIntensity(ceil(end/2),:));grid(ax,'on');
title(ax,'100 um; unnormalized centre line');xlabel(ax,'x (um)');ylabel(ax,'Intensity / unit source power (m^{-2})');
set(findall(fig,'Type','axes'),'XColor','k','YColor','k');
drawnow;exportgraphics(fig,outputFile,'Resolution',130);
fprintf('Display comparison saved: %s\n',outputFile);
end
