function [varargout] = histcounts(varargin)
%HISTCOUNTS overloaded for gpuArrays
%   [N,EDGES] = histcounts(X)
%   [N,EDGES] = histcounts(X,M)
%   [N,EDGES] = histcounts(X,EDGES)
%   [N,EDGES] = histcounts(...,'BinWidth',BW)
%   [N,EDGES] = histcounts(...,'BinLimits',[BMIN,BMAX])
%   [N,EDGES] = histcounts(...,'Normalization',NM)
%   [N,EDGES] = histcounts(...,'BinMethod',BM)
%   [N,EDGES,BIN] = histcounts(...)
%   
%   64-bit integers are not supported.
%   
%   Example:
%    
%       X = gpuArray(pascal(3));
%       [n, edges] = histcounts(X)
%   
%   See also HISTCOUNTS, GPUARRAY.
%   


%   Copyright 2014 The MathWorks, Inc.
set(0,'RecursionLimit',5000)
narginchk(1,inf);

try
    % Other gpuArray arguments include scalars and the bin edge vector. All of
    % these should be small in comparison to the actual data.
    otherArgs = cellfun(@gather, varargin(2:end), 'UniformOutput', false);
    
    x = varargin{1};
    
    if isa(x, 'gpuArray')
        % Sparse types are not supported.
        if any(cellfun(@issparse, varargin))
            error(message('parallel:gpu:array:SparseNotSupported'));
        end
        
        % 64-integer types are not supported.
        if any(strcmp(classUnderlying(x), {'int64', 'uint64'}))
            error(message('parallel:gpu:array:Unsupported64BitType'));
        end
        for ii = 1:numel(otherArgs)
            if isa(otherArgs{ii}, 'int64') || isa(otherArgs{ii}, 'uint64')
                error(message('parallel:gpu:array:Unsupported64BitType'));
            end
        end

        [varargout{1:nargout}] = parallel.internal.flowthrough.histcounts(x, otherArgs{:});
    else
        [varargout{1:nargout}] = histcounts(x, otherArgs{:});
    end
catch err
    throw(err);
end
