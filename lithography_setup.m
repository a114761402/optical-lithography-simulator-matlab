function projectRoot = lithography_setup()
% Add the simulator's code folders to this MATLAB session.
% Run once before calling helpers/tests directly. The GUI calls this itself.
% Uses this file's location, so the current working folder need not be root.
projectRoot=fileparts(mfilename('fullpath'));
folders={'src/config','src/optics','src/ui','tests','tests/fixtures','tools'};
paths=cellfun(@(folder)fullfile(projectRoot,folder),folders,'UniformOutput',false);
addpath(projectRoot,paths{:});
end
