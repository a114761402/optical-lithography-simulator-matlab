function fig=lithography_plot_figure(owner,tag,varargin)
% Preserve open snapshots. Only an explicitly closed window may be recycled.
fig=[];
candidates=findall(groot,'Type','figure','Tag',tag);
for k=1:numel(candidates)
    candidate=candidates(k);
    if isequal(getappdata(candidate,'plotOwner'),owner) && ...
            isequal(getappdata(candidate,'plotClosed'),true)
        fig=candidate;clf(fig,'reset');break;
    end
end
if isempty(fig),fig=figure('Visible','off');end
set(fig,'NumberTitle','off','Color','w','MenuBar','none','ToolBar','none',...
    'Visible','on',varargin{:},'Tag',tag,'CloseRequestFcn',@closeSnapshot);
if isprop(fig,'Theme'),fig.Theme='light';end
setappdata(fig,'plotOwner',owner);setappdata(fig,'plotClosed',false);
end

function closeSnapshot(fig,~)
% Avoid destroying a native MATLAB figure during its close-button callback.
set(fig,'Visible','off');setappdata(fig,'plotClosed',true);
end
