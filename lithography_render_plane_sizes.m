function lithography_render_plane_sizes(axesList,p,r)
items=lithography_plane_sizes(p,r);
for j=1:numel(items)
    ax=axesList(j);cla(ax);item=items(j);
    if isempty(item.thumbnail)
        axis(ax,[0 1 0 1]);
        text(ax,.5,.5,'\infty','Interpreter','tex','FontSize',24,'HorizontalAlignment','center');
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
