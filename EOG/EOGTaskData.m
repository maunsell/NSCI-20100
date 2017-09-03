classdef EOGTaskData < handle
    % saccades
    %   Support for processing eye traces and detecting saccades
    
    properties
        counter = 123;
    end
    
    methods
        
        %% clearAll
        function clearAll(obj)
            obj.counter = 0;
        end
    end
    
    
end

