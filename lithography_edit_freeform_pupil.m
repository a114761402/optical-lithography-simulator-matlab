function [pupilMask, accepted] = lithography_edit_freeform_pupil(initialMask)
if nargin < 1 || isempty(initialMask)
    initialMask = lithography_default_custom_pupil();
end

[pupilMask, accepted] = lithography_edit_freeform_shape( ...
    initialMask, 'Freeform Pupil Editor', 'Freeform pupil transmission');
end
