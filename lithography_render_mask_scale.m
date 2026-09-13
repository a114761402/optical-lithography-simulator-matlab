function lithography_render_mask_scale(fig,p,r)
% Mechanical scale context, NOT a full-plate optical calculation.
if isprop(fig,'Theme'),fig.Theme='light';end
set(fig,'Color','w');
ax=axes(fig,'Position',[.08 .24 .36 .61]);
side=p.maskPlateSizeMm;
rectangle(ax,'Position',[-side/2 -side/2 side side],'FaceColor',[.88 .91 .95],'EdgeColor',[.2 .2 .2]);
hold(ax,'on');
roi=p.fieldSizeUm/1000;
rectangle(ax,'Position',[-roi/2 -roi/2 roi roi],'EdgeColor',[.9 .15 .1],'LineWidth',1);
text(ax,.03*side,.03*side,'ROI at centre','Color',[.8 .1 .1],'FontSize',10);
axis(ax,'equal');axis(ax,[-.55 .55 -.55 .55]*side);grid(ax,'on');
xlabel(ax,'x (mm)');ylabel(ax,'y (mm)');
title(ax,{sprintf('Plate outline: %.3g x %.3g mm',side,side);'Context only; other patterns excluded'},'FontSize',10);
ax=axes(fig,'Position',[.58 .24 .35 .61]);
x=r.objectAxisM*1e6;imagesc(ax,x,x,r.mask);axis(ax,'image');set(ax,'YDir','normal');
colormap(ax,gray(256));clim(ax,[0 1]);xlabel(ax,'x (um)');ylabel(ax,'y (um)');
title(ax,{sprintf('Computed local window: %.3g um',p.fieldSizeUm);...
    sprintf('Pattern envelope: %.3g um',p.maskSizeUm)},'FontSize',10);
uicontrol(fig,'Style','text','Units','normalized','Position',[.04 .015 .92 .12],...
    'BackgroundColor','w','FontSize',10,'String',...
    {sprintf('Plate width / local window = %.0f. The right panel is a separate enlarged view.',side*1000/p.fieldSizeUm);...
    'Only this isolated pattern is propagated; no other transmitted features are included.';...
    'Plate-edge diffraction and substrate/material effects are not simulated.'});
end
