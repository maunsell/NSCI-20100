function partners

clc;
wedNames = {'Chan', 'Culjat', 'Del Cioppo Vasques', 'Denson', 'Fung', 'Garon', 'Hoke', 'Lee', 'Mcdonald', 'Navarro'...
    'Needham', 'Palla', 'Pan', 'Psahoulias', 'Ramaprasad', 'Saieed', 'Sampson', 'Steele', 'von Riesemann', 'Zvyagin'};

wed = [
      0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN;
    NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN,   0, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1;
    NaN, NaN, NaN, NaN,   1, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN, NaN;
    NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN,   0, NaN, NaN;
      1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0, NaN;
    NaN, NaN, NaN, NaN, NaN, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN,   0;
];

friNames = {'Cabaj', 'Felix', 'Fried', 'Havlik', 'Klein', 'Knight', 'Kochheiser', 'Lopez Trujillo', 'Ma', 'Malik',...
    'Malkami', 'Osei-Kankam' 'Patel', 'Payne', 'Preddy', 'Rogers', 'Ruona', 'Srikumal', 'Terian', 'Vann-Adibe',...
    'Vargas', 'Vogel', 'Yi', 'XXXXX'};

fri = [
      0, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, 0, NaN,   1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN;
      NaN, NaN,   1, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN;
      1, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN, NaN;
      NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN, NaN;
      NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN, NaN;
      NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 1, NaN, NaN, NaN, NaN, NaN, NaN, 0, NaN;
      NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, 0;
];

doOneSection('Wednesday', wedNames, wed);
doOneSection('Friday', friNames, fri);
end

function doOneSection(dayName, names, a)
students = size(a, 1);
if students ~= length(names)
    fprintf('Matrix does not match length of name vector');
end
if mod(students, 2) ~= 0
    fprintf('You must have an even number of students\n');
    return;
end

rng(2019);
for lab = 1:8
    jammed = true;
    backup = a;
    while jammed
        a = backup;
        [a, jammed] = loadAssignments(a, lab);
    end
end

fileID = fopen([dayName '.txt'], 'w');
for r = 1:students
    fprintf(fileID, '\t%s', names{r});
end
fprintf(fileID, '\n');

for r = 1:students
    fprintf(fileID, '%s', names{r});
    for c = 1:students
        if isnan(a(r, c)) 
            fprintf(fileID, '\t');
        else
            fprintf(fileID, '\t%d', a(r, c));
        end
    end
	fprintf(fileID, '\n');
end
fclose(fileID);

end

function [a, jammed] = loadAssignments(a, lab)

    jammed = false;
    students = size(a, 1);
    for row = 1:students - 1;
        col = row;
        if sum(ismember(a(row, :), lab)) > 0        % already got an assignment for this row?
            continue;
        end
        tryCount = 0;
        while ~isnan(a(row, col)) || sum(ismember(a(:, col), lab)) > 0
            col = randi(students);
            tryCount = tryCount + 1;
            if tryCount > 100
                jammed = true;
                break;
            end
        end
        if ~jammed
            a(row, col) = lab;
            a(col, row) = lab;
        else
%             fprintf('jammed\n');
            break;
        end
    end
end
