function path = createFolderIfNotExist(path)
    if (exist(path) == 0)
        % does not exist, create
        mkdir(path);
    end
end