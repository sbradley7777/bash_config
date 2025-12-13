################################################################################
    # Example size
    # $ du -sh /var/lib/mysql/test/
    # 396M /var/lib/mysql/test/
    # numOfCols = 1000
    # numOfRows = 100000

    # 1 table 1.9GB and 23 tables 44.3 GiB
    #numOfCols = 1000
    #numOfRows = 500000
    #statusInterval = 10000
    #numOfTables = 23

    
    """
    Only for local
    import os
    dir = "/var/lib/mysql/test/"
    dir_size = 0
    for (path, dirs, files) in os.walk(dir):
        for file in files:
            filename = os.path.join(path, file)
            dir_size += os.path.getsize(filename)

    print "%s = %0.1f MB in size." % (dir, dir_size/(1024*1024.0))
    """
    sys.exit()
################################################################################
