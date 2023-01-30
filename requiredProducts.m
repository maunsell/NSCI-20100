function requiredProducts

  required = [];
  folderContents = dir;
  for f = 1:length(folderContents)
    if folderContents(f).isdir
      if folderContents(f).name(1) == '.'
        continue;
      end
      cd(folderContents(f).name);
      subContents = dir;
      for s = 1:length(subContents)
        if contains(subContents(s).name, '.mlapp')
          [~, pList] = matlab.codetools.requiredFilesAndProducts(subContents(s).name);
          required = [required, pList]; %#ok<AGROW> 
        end
      end
      cd('..');
      fprintf('%s\n', folderContents(f).name);
    end
  end
  products = cell(1, length(required));
  for r = 1:length(required)
    products{r} = required(r).Name;
  end
  products = unique(products);
  fprintf('\nRequired Matlab Products:\n');
  for r = 1:length(products)
    fprintf('   %s\n', products{r});
  end
end