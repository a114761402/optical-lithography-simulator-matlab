function lithography_render_plane_sizes(axesList,p,r)
items=lithography_plane_sizes(p,r);
for j=1:numel(items)
    ax=axesList(j);cla(ax);item=items(j);
    if isempty(item.thumbnail)
        % Schematic biconvex profile, not a finite physical lens aperture.
        y=linspace(.06,.94,65);bulge=.20*(1-((y-.5)/.44).^2);
        patch(ax,[.5-bulge fliplr(.5+bulge)],[y fliplr(y)],...
            [.78 .89 .97],'EdgeColor',[.15 .28 .38],'LineWidth',1.3,'Tag','LensIcon');
        axis(ax,[0 1 0 1]);daspect(ax,[1 1 1]);
    else
        imagesc(ax,item.thumbnail);axis(ax,'image');set(ax,'YDir','normal');
        colormap(ax,gray(256));if j==6,colormap(ax,parula(256));end
        caxis(ax,[0 1]);
    end
    axis(ax,'off');
    title(ax,item.name,'FontSize',9,'FontWeight','bold');
    text(ax,.5,-.18,item.caption,'Units','normalized','HorizontalAlignment','center',...
        'VerticalAlignment','top','FontSize',9,'Interpreter','none','Tag','PlaneSizeCaption');
    setappdata(ax,'planeSize',item);
end
end
