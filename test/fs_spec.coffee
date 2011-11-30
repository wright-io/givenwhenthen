CoffeeScript  = require 'coffee-script'
core          = require 'open.core'
fsCoreUtil    = core.util.fs
fsUtil        = require '../lib/fs.coffee'
fs            = require 'fs'


describe 'util/fs', ->
  mock = null
  
  beforeEach ->
    # Prepare mocks and spies.
    mock =
      paths:  ['suffix1.coffee', 'suffix2.coffee']
      data:   ['coffee1', 'coffee2']
      js:     ['js1', 'js2']
    
    spyOn(fsCoreUtil, 'readDirSync').andReturn mock.paths
    spyOn(fs, 'readFileSync').andCallFake (path) ->
      switch path
        when mock.paths[0]
          return mock.data[0]
        when mock.paths[1]
          return mock.data[1]
          
    spyOn(CoffeeScript, 'compile').andCallFake (data) ->
      switch data
        when mock.data[0]
          return mock.js[0]
        when mock.data[1]
          return mock.js[1]
        
    spyOn(global, 'eval')
  
  it 'evaluates the all files from the specified directory', ->
    # Call method under test.
    fsUtil.evaluateFilesSync 'someDir', '.coffee'
    
    # Verify.
    expect(eval.argsForCall[0][0]).toEqual mock.js[0]
    expect(eval.argsForCall[1][0]).toEqual mock.js[1]
    
  it 'does not evaluate files that do not have the specified suffix', ->
    # Call method under test.
    fsUtil.evaluateFilesSync 'someDir', '.notcoffee'
    
    # Verify.
    expect(eval).not.toHaveBeenCalled()