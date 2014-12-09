function [re] = ndgrid2vec(varargin)

tre = cell(1:nargin);
[tre{1:nargin}] = ndgrid(varargin{:});
re = [];%numel(tre{1})
for i = 1:nargin
    re = [re tre{i}(:)];
end

return;
