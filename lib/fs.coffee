CoffeeScript  = require 'coffee-script'
fs            = require 'fs'
core          = require 'open.core'
fsCoreUtil    = core.util.fs

module.exports =
  
  ###
  Loads, compiles and evaluates .coffee files within the given directory.
  @param dir:             Path to the directory to process.
  @param endsWithFilter:  The end-of-file-name filter to apply.
  ###
  evaluateFilesSync: (dir, endsWithFilter) -> 
    # Read the complete set of files from the given directory.
    paths = fsCoreUtil.readDirSync dir, deep:true, dirs:false
    
    # Evaluate each test file.cd 
    for path in paths
      if _(path).endsWith endsWithFilter
        # Read the data from disk.
        data = fs.readFileSync path
        data = data.toString()
        # Compile from coffee into javascript.
        try
          js = CoffeeScript.compile(data)
        catch error
          throw "Failed to compile coffee-script in acceptance test file: " +
            "\n[#{p}].\n#{error}\n"

        # Execute the javascript.
        global.eval js