function [sourceMask, accepted] = lithography_edit_freeform_source(initialMask)
if nargin < 1 || isempty(initialMask)
    initialMask = lithography_default_custom_source();
end

[sourceMask, accepted] = lithography_edit_freeform_shape( ...
    initialMask, 'Freeform Source Editor', 'Freeform source weight');
end
