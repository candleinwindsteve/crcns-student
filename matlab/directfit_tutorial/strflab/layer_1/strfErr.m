function [strf,varargout]=strfErr(strf,datIdx)
%function [strf,varargout]=strfErr(strf,datIdx)
%
% Evaluate strf error function at current weights in strf structure
% for generic optimizers
%
% INPUT:	
%	   [strf] = strf model structure
%    [datIdx] = a vector containing indices of the samples to be used in the 
%               fitting.
%
% OUTPUT:
%      [strf] = strf model structure
% [varargout] = The value of the error function evaluated at the current
%               weights in strf and any other output generated by the STRF's fwd
%		        function (ex. response before output nonlinearity)
%
%
%(Some code modified from NETLAB)


errstr = [strf.type, 'Err'];
[s{1:nargout}]=feval(errstr, strf, datIdx);
strf = s{1};

if nargout > 1
  for i = 2:nargout
    varargout{i-1} = s{i};
  end
end
