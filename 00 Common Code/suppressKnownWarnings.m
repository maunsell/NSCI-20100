
function suppressKnownWarnings()

  warning('off','MATLAB:class:DestructorError');
  % s = warning('query','MATLAB:class:DestructorError');
  % disp(s.state)
  warning('off', 'MATLAB:callback:error');
  % s = warning('query','MATLAB:callback:error');
  % disp(s.state)

end