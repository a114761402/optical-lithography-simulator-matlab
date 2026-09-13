function outputFile = lithography_export_documentation(p,r)
% Reproduce the README figure from the actual startup model, not a sketch.
% Optionally reuse outputs from lithography_practical_defaults_test.
if nargin==0
    p=lithography_check_settings(lithography_default_params());
    r=lithography_run_physics(p);
elseif nargin~=2
    error('Lithography:Documentation','Supply both parameters and results, or neither.');
end
outputDir=fullfile(fileparts(mfilename('fullpath')),'docs','assets');
if ~isfolder(outputDir),mkdir(outputDir);end
outputFile=fullfile(outputDir,'default-imaging.png');
fig=figure('Visible','off','Color','w','Position',[40 40 1380 480]);
if isprop(fig,'Theme'),fig.Theme='light';end
cleanup=onCleanup(@()delete(fig));
t=tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
ax=nexttile(t);imagesc(ax,r.objectAxisM*1e6,r.objectAxisM*1e6,r.mask);
axis(ax,'image');set(ax,'YDir','normal');clim(ax,[0 1]);colormap(ax,gray(256));
xlabel(ax,'x (um)');ylabel(ax,'y (um)');title(ax,{'Mask amplitude',sprintf('Pattern envelope: %g x %g um',p.maskSizeUm,p.maskSizeUm)});
ax=nexttile(t);imagesc(ax,r.imageAxisM*1e6,r.imageAxisM*1e6,r.image);
axis(ax,'image');set(ax,'YDir','normal');clim(ax,[0 1]);colormap(ax,parula(256));
half=p.fieldSizeUm/(2*p.reduction);xlim(ax,[-half half]);ylim(ax,[-half half]);
xlabel(ax,'x (um)');ylabel(ax,'y (um)');
title(ax,{'Image intensity (local scale)',sprintf('%gx reduction | z = %g mm',p.reduction,r.geometry.zImage)});
cb=colorbar(ax);cb.Label.String='I / local peak';
ax=nexttile(t);[~,iy]=min(abs(r.imageAxisM));x=r.imageAxisM*1e6;
plot(ax,x,r.image(iy,:),'LineWidth',2,'Color',[.08 .35 .68]);
xlim(ax,[-half half]);ylim(ax,[0 1.08]);grid(ax,'on');
xlabel(ax,'Image x (um)');ylabel(ax,'I / local peak');
title(ax,{'Image centreline: y = 0',sprintf('Nominal pitch: %g um',p.gratingPitchUm/p.reduction)});
set(findall(fig,'Type','axes'),'FontSize',12);
title(t,sprintf('%g nm | image NA %.2f | isolated local pattern, not a full-plate simulation',p.wavelengthNm,p.projNA),'FontSize',16);
exportgraphics(t,outputFile,'Resolution',150);
fprintf('Documentation figure: %s\n',outputFile);
end
