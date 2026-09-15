function lithography_render_xy_slice(fig,slice,mode)
% An independently selectable, display-only XY scale. Reuse existing data.
if nargin<3,mode='Local linear';end
setappdata(fig,'xySliceData',slice);
modes={'Local linear','Local log (dB)','XYZ linear','XYZ log (dB)'};
uicontrol(fig,'Style','text','Units','normalized','Position',[.02 .94 .23 .045],...
    'String','XY colour scale','BackgroundColor','w','HorizontalAlignment','left');
popup=uicontrol(fig,'Style','popupmenu','Units','normalized','Position',[.25 .94 .34 .05],...
    'String',modes,'Value',find(strcmp(modes,mode),1),'Tag','XYScale',...
    'TooltipString','Display only; no recalculation. Local reveals shape; XYZ compares brightness.');
ax=axes('Parent',fig,'Units','normalized','Position',[.14 .17 .68 .61],'Tag','XYAxes');
x=slice.axis;y=x;
if isfield(slice,'axisX'),x=slice.axisX;y=slice.axisY;end
im=imagesc(ax,[x(1) x(end)],[y(1) y(end)],zeros(size(slice.rawIntensity)));
axis(ax,'image');set(ax,'YDir','normal','FontSize',9,'XColor',[.1 .1 .1],'YColor',[.1 .1 .1]);
if isfield(slice,'displayHalfWidthM')
    xlim(ax,[-1 1]*slice.displayHalfWidthM*1e6);ylim(ax,[-1 1]*slice.displayHalfWidthM*1e6);
end
colormap(ax,turbo(256));
xl='normalized x';yl='normalized y';
if isfield(slice,'xlabelText'),xl=slice.xlabelText;yl=slice.ylabelText;end
xlabel(ax,xl);ylabel(ax,yl);
cb=colorbar(ax,'eastoutside');cb.FontSize=8;cb.Label.FontSize=8;
status=uicontrol(fig,'Style','text','Units','normalized','Position',[.02 .005 .96 .09],...
    'BackgroundColor','w','FontSize',9,'HorizontalAlignment','left','Tag','XYScaleNote');
set(popup,'Callback',@(~,~) repaint());
repaint();

    function repaint()
        selected=modes{get(popup,'Value')};
        view=lithography_xy_display(slice,selected);
        setappdata(fig,'xyScaleMode',selected);setappdata(fig,'xyDisplay',view);
        set(im,'CData',view.values);clim(ax,view.limits);
        cb.Ticks=view.ticks;cb.Label.String=view.label;
        model='XY intensity';
        if isfield(slice,'titleText') && ~isempty(slice.titleText),model=slice.titleText;end
        detail=sprintf('Raw peak = %.3g',view.peak);
        if ~isnan(view.relativeDb),detail=[detail sprintf(' | peak / XYZ reference = %.1f dB',view.relativeDb)];end
        title(ax,{model;detail},'FontSize',9,'Color',[.1 .1 .1],'Interpreter','none');
        notes={view.note};
        if isfield(slice,'viewNote') && ~isempty(slice.viewNote),notes{end+1}=slice.viewNote;end
        set(status,'String',notes);
    end
end
