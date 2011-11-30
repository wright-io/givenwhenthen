CoffeeScript  = require 'coffee-script'
core          = require 'open.core'
soda          = require 'soda'
util          = core.util
fsUtil        = require '../lib/fs.coffee'
acceptance    = require '../lib/acceptance.coffee'
at_tools      = require '../lib/acceptance_tools.coffee'

describe 'util/acceptance', ->
  mock = null
  
  beforeEach ->
    
    # Swallow process logging to keep test output clean
    core.util.log.silent = true
    
    # Prepare mocks and spies.
    mock =
      # Mocking methods on soda.Client (returned as `browser`).
      # These get called as a part of running a scenario.
      browser:
        chain: 
          session: ->
        testComplete: ->
        end: (err) ->
        execute: ->
          return mock.browser
    
    # The way that acceptance class gets the data files.
    spyOn(fsUtil, 'evaluateFilesSync')    
    
    # The methods we are mocking on soda.
    #
    # These methods all chain, so need to both be called on and return the browser.
    spyOn(mock.browser, 'execute').andReturn mock.browser
    spyOn(soda, 'createSauceClient').andReturn mock.browser
    spyOn(mock.browser.chain, 'session').andReturn mock.browser
    spyOn(mock.browser, 'testComplete').andReturn mock.browser
    # This method is called when the async test finishes so we need to mock it to 
    # get out callback called
    spyOn(mock.browser, 'end').andCallFake (callback) -> callback null   

    # Spying on the core.util.log functions so we can check appropriate logging.
    # NOTE: We have to save the spy and re-apply it because the `append` function
    # belongs to the `log` function, which we are also spying on.
    spyOn(util.log, 'append')
    appendSpy = util.log.append
    spyOn(util, 'log')
    util.log.append = appendSpy
  
  ###
    These are tests that need to run against multiple stories being loaded from the
    mock data files (mockDataLoading basicStoriesTestSet())
  ###
  describe 'multi-story tests', ->
    
    beforeEach ->
      mockDataLoading basicStoriesTestSet()
    
    it 'collects and runs all defined stories and scenarios against all browser configs', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      # Make sure the soda client was correctly created for each sample story supplied.
      expect(soda.createSauceClient.argsForCall[0][0]['name'])
        .toEqual 'Visiting Google: Homepage view'
      expect(soda.createSauceClient.argsForCall[0][0]['os'])
        .toEqual 'Windows 2003'
  
      expect(soda.createSauceClient.argsForCall[1][0]['name'])
        .toEqual 'Visiting Google: Homepage view'
      expect(soda.createSauceClient.argsForCall[1][0]['os'])
        .toEqual 'Linux'
        
      expect(soda.createSauceClient.argsForCall[2][0]['name'])
        .toEqual 'Visiting Google: scenario2'
      expect(soda.createSauceClient.argsForCall[2][0]['os'])
        .toEqual 'Windows 2003'
  
      expect(soda.createSauceClient.argsForCall[3][0]['name'])
        .toEqual 'Visiting Google: scenario2'
      expect(soda.createSauceClient.argsForCall[3][0]['os'])
        .toEqual 'Linux'
    
      expect(soda.createSauceClient.argsForCall[4][0]['name'])
        .toEqual 'Executing a search: Search for topic with many results'
      expect(soda.createSauceClient.argsForCall[4][0]['os'])
        .toEqual 'Windows 2003'
    
      expect(soda.createSauceClient.argsForCall[5][0]['name'])
        .toEqual 'Executing a search: Search for topic with many results'
      expect(soda.createSauceClient.argsForCall[5][0]['os'])
        .toEqual 'Linux'

    it 'prints a summary of the acceptance test suite on execution', ->
      # Call method under test.
      acceptance.runStories()
    
      # Verify.
      summary = 
        "Running 2 stories containing 3 scenarios against 2 browser/os configurations..."
      
      expect(util.log.argsForCall[0][0]).toEqual(summary)
      expect(util.log.argsForCall[0][1]).toEqual(color.blue)
  
  ###
    These are tests that need to run against a single story being loaded from the
    mock data files (mockDataLoading singleStoryTestSet())
  ###    
  describe 'single story tests', ->
    
    beforeEach ->
      mockDataLoading singleStoryTestSet()
      
    describe 'reading data files', ->
  
      it 'reads the data files from [app_root]/test/acceptance by default', ->
        # Call method under test.
        acceptance.runStories()
    
        # Verify.
        # The base directory is used 3 times to load data files
        # (for stories, steps, and config).
        # Check that eval uses the correct directory.
        baseDirectory = 'test/acceptance'
        expect(fsUtil.evaluateFilesSync.argsForCall[0][0])
          .toEqual baseDirectory
        expect(fsUtil.evaluateFilesSync.argsForCall[1][0])
          .toEqual baseDirectory
        expect(fsUtil.evaluateFilesSync.argsForCall[2][0])
          .toEqual baseDirectory
        expect(fsUtil.evaluateFilesSync.callCount).toEqual 3
  
      it 'reads the data files from the specified location if one is provided', ->
        # Call method under test.
        mock.baseDirectory = 'mock/directory'
        acceptance.runStories(directory:mock.baseDirectory)
      
        # Verify.
        # The base directory is used 3 times to load data files
        # (for stories, steps, and config).
        # Check that eval uses the correct directory.
        baseDirectory = 'test/acceptance'
        expect(fsUtil.evaluateFilesSync.argsForCall[0][0])
          .toEqual mock.baseDirectory
        expect(fsUtil.evaluateFilesSync.argsForCall[1][0])
          .toEqual mock.baseDirectory
        expect(fsUtil.evaluateFilesSync.argsForCall[2][0])
          .toEqual mock.baseDirectory
        expect(fsUtil.evaluateFilesSync.callCount).toEqual 3
    
      it 'does not read test files that don\'t end with the proper suffix', ->
        # Call method under test.
        acceptance.runStories()
    
        # Verify.
        # We know that `evaluateFilesSync` works, so just make sure it is called with
        # the right filters and only those filters.
        expect(fsUtil.evaluateFilesSync.argsForCall[0][1])
          .toEqual 'steps.coffee'
        expect(fsUtil.evaluateFilesSync.argsForCall[1][1])
          .toEqual 'config.coffee'
        expect(fsUtil.evaluateFilesSync.argsForCall[2][1])
          .toEqual 'test.coffee'
        expect(fsUtil.evaluateFilesSync.callCount).toEqual 3
  
    it 'runs test initialization prior to each scenario body', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      expect(mock.browser.chain.session.callCount).toEqual 2
  
    it 'runs test finalization after each scenario body', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      expect(mock.browser.testComplete.callCount).toEqual 2
      expect(mock.browser.end.callCount).toEqual 2
  
    it 'correctly configures the soda client', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      expect(soda.createSauceClient.argsForCall[0][0]['name'])
        .toEqual 'Executing a search: Search for topic with many results'
      expect(soda.createSauceClient.argsForCall[0][0]['url'])
        .toEqual 'http://www.google.com/'
      expect(soda.createSauceClient.argsForCall[0][0]['username'])
        .toEqual 'sauce_username'
      expect(soda.createSauceClient.argsForCall[0][0]['access-key'])
        .toEqual 'sauce_access_key'
      expect(soda.createSauceClient.argsForCall[0][0]['max-duration'])
        .toEqual '100'
      expect(soda.createSauceClient.argsForCall[0][0]['os'])
        .toEqual 'Windows 2003'
      expect(soda.createSauceClient.argsForCall[0][0]['browser'])
        .toEqual 'firefox'
      expect(soda.createSauceClient.argsForCall[0][0]['browser-version'])
        .toEqual '7'

    it 'passes the configured soda client to the scenario and executes the scenario body', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify. 
      # We are calling mock.browser.execute(steps.testStep()) in one of the sample stories
      # below, so if the method got called, the browser was passed correctly to the scenario
      # and that the body was executed.
      expect(mock.browser.execute).toHaveBeenCalled()
  
    it 'adds the given/when/then features to soda', ->
      # Prepares mocks and spies.
      spyOn(at_tools, 'addGivenWhenThenToSoda')
  
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      expect(at_tools.addGivenWhenThenToSoda).toHaveBeenCalled()
  
    describe 'success reporting', ->
      it 'reports success when all stories pass', ->
        # Call method under test.
        acceptance.runStories()
    
        # Verify.
        expect(util.log.argsForCall[1][0]).toContain("Done")
        expect(util.log.argsForCall[1][1]).toEqual(color.green)
      
      it 'prints a green dot for every successful test that is executed', ->
        # Call method under test.
        acceptance.runStories()
    
        expect(core.util.log.append.argsForCall[0][0]).toEqual('.')
        expect(core.util.log.append.argsForCall[0][1]).toEqual(color.green)
        expect(core.util.log.append.argsForCall[1][0]).toEqual('.')
        expect(core.util.log.append.argsForCall[1][1]).toEqual(color.green)
        expect(core.util.log.append.callCount).toEqual 2
    
    describe 'failure reporting', ->
    
      beforeEach ->
        # Prepare mocks and spies.
        mock.error =
          message: "Epic fail."
          storyTitle: "storyTitle"
          browserConfig:
            browser: "browser"
            'browser-version': "browser-version"
            os: "os"
        mock.browser.end.andCallFake (callback) ->
          callback mock.error
    
      it 'reports failure for each scenario that fails', ->  
        # Call method under test.
        acceptance.runStories()
      
        # Verify.
        expect(util.log.argsForCall[2][0]).toEqual(mock.error.message)
        expect(util.log.argsForCall[2][1]).toEqual(color.red)
    
        expect(util.log.argsForCall[3][0]).toContain mock.error.storyTitle
    
        expect(util.log.argsForCall[4][0])
          .toContain mock.error.browserConfig['browser']
        expect(util.log.argsForCall[4][0])
          .toContain mock.error.browserConfig['browser-version']
        expect(util.log.argsForCall[4][0])
          .toContain mock.error.browserConfig['os']
    
      it 'prints a red dot for every failed test that is executed', ->
        # Call method under test.
        acceptance.runStories()
      
        # Verify.
        expect(core.util.log.append.argsForCall[0][0]).toEqual('.')
        expect(core.util.log.append.argsForCall[0][1]).toEqual(color.red)
        expect(core.util.log.append.argsForCall[1][0]).toEqual('.')
        expect(core.util.log.append.argsForCall[1][1]).toEqual(color.red)
        expect(core.util.log.append.callCount).toEqual 2
      
      it 'throws an error on test failure if requested', ->
        # Prepare mocks and spies.
        spyOn(global, 'Error').andCallThrough()
      
        # Call method under test.
        exceptionThrown = false
        try
          acceptance.runStories(throw:true)
        catch error
          exceptionThrown = true
          
        expect(global.Error).toHaveBeenCalled()
        expect(exceptionThrown).toBeTruthy()
  
  ###
    These tests need to run against specially configured sample stories that have
    various options for selecting, ignoring, etc. (see `mockDataLoading`).
  ###
  describe 'configuration options', ->
  
      it 'runs only the specified stories if requested', ->
        mockDataLoading selectedStoriesTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Skipping or including is acheieved by decoration on
        # `story` and `scenario` method calls.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[1][0]['name'])
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(soda.createSauceClient.argsForCall[1][0]['os'])
          .toEqual 'Linux'
        
        expect(soda.createSauceClient.argsForCall[2][0]['name'])
          .toEqual 'selectedStory2Title: selectedStory2Scenario1'
        expect(soda.createSauceClient.argsForCall[2][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[3][0]['name'])
          .toEqual 'selectedStory2Title: selectedStory2Scenario1'
        expect(soda.createSauceClient.argsForCall[3][0]['os'])
          .toEqual 'Linux'
          
        expect(soda.createSauceClient.callCount).toEqual 4
      
      it 'runs only the specified scenarios if requested', ->
        mockDataLoading selectedScenariosTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[1][0]['name'])
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(soda.createSauceClient.argsForCall[1][0]['os'])
          .toEqual 'Linux'
          
        expect(soda.createSauceClient.callCount).toEqual 2
        
      it 'supports a mix of specified stories and scenarios', ->
        mockDataLoading selectedStoriesAndScenariosTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[1][0]['name'])
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(soda.createSauceClient.argsForCall[1][0]['os'])
          .toEqual 'Linux'
        
        expect(soda.createSauceClient.argsForCall[2][0]['name'])
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(soda.createSauceClient.argsForCall[2][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[3][0]['name'])
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(soda.createSauceClient.argsForCall[3][0]['os'])
          .toEqual 'Linux'
          
        expect(soda.createSauceClient.callCount).toEqual 4
        
  
      it 'runs only the specified browser/os config if requested', ->
        mockDataLoading singleStoryTestSet()
        
        # Call method under test.
        acceptance.runStories(browser:2)
        
        # Verify.
        # Expect only the specified browser to be used.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'Executing a search: Search for topic with many results'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Linux'
          
        expect(soda.createSauceClient.callCount).toEqual 1
  
      it 'ignores scenarios prefixed with "x"', ->
        mockDataLoading ignoredScenarioTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[1][0]['name'])
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(soda.createSauceClient.argsForCall[1][0]['os'])
          .toEqual 'Linux'
          
        expect(soda.createSauceClient.callCount).toEqual 2

      it 'ignores stories prefixed with "x"', ->
        mockDataLoading ignoredStoryTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'Executing a search: Search for topic with many results'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Windows 2003'
    
        expect(soda.createSauceClient.argsForCall[1][0]['name'])
          .toEqual 'Executing a search: Search for topic with many results'
        expect(soda.createSauceClient.argsForCall[1][0]['os'])
          .toEqual 'Linux'    

        expect(soda.createSauceClient.callCount).toEqual 2
        
      it 'supports a mix of ignored stories and scenarios', ->
        mockDataLoading ignoredStoriesAndScenariosTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(soda.createSauceClient.argsForCall[0][0]['name'])
          .toEqual 'Executing a search: Search for topic with many results'
        expect(soda.createSauceClient.argsForCall[0][0]['os'])
          .toEqual 'Windows 2003'
    
        expect(soda.createSauceClient.argsForCall[1][0]['name'])
          .toEqual 'Executing a search: Search for topic with many results'
        expect(soda.createSauceClient.argsForCall[1][0]['os'])
          .toEqual 'Linux'
          
        expect(soda.createSauceClient.argsForCall[2][0]['name'])
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(soda.createSauceClient.argsForCall[2][0]['os'])
          .toEqual 'Windows 2003'
  
        expect(soda.createSauceClient.argsForCall[3][0]['name'])
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(soda.createSauceClient.argsForCall[3][0]['os'])
          .toEqual 'Linux'

        expect(soda.createSauceClient.callCount).toEqual 4

###
Mocks the job of loading and executing data files from the file system.
@param stories: Array of sample stories (as Strings) from test sets (below) to load.
###
mockDataLoading = (stories) ->
  fsUtil.evaluateFilesSync.andCallFake (dir, filter) ->
    switch filter
      when 'test.coffee'
        for story in stories
          evalCoffee story
      when 'steps.coffee'
        for steps in sampleSteps
          evalCoffee steps
      when 'config.coffee'
        evalCoffee sampleConfig

# Collection of two normal stories for basic testing.
basicStoriesTestSet = ->
  [
    sampleStories.googleHomepage,
    sampleStories.googleSearch
  ]

# A single normal story for tests that don't need to check multiple.
singleStoryTestSet = ->
  [sampleStories.googleSearch]

# To test explicit story selection functionality.  
selectedStoriesTestSet = ->
  [
    sampleStories.googleHomepage,
    sampleStories.selectedStory1,
    sampleStories.selectedStory2
  ]

# To test explicit scenario selection functionality.    
selectedScenariosTestSet = ->
  [
    sampleStories.googleHomepage,
    sampleStories.selectedScenario
  ]

# To test explicit story and scenario selection functionality mixed.
selectedStoriesAndScenariosTestSet = ->
  [
    sampleStories.googleHomepage,
    sampleStories.selectedStory1,
    sampleStories.selectedScenario
  ]

# To test scenario ignore functionality.
ignoredScenarioTestSet = ->
  [sampleStories.ignoredScenario]

# To test story ignore functionality.  
ignoredStoryTestSet = ->
  [
    sampleStories.googleSearch,
    sampleStories.ignoredStory
  ]

# To test story and scenario ignore functionality mixed.
ignoredStoriesAndScenariosTestSet = ->
  [
    sampleStories.googleSearch,
    sampleStories.ignoredScenario,
    sampleStories.ignoredStory
  ]

evalCoffee = (coffee) ->
      eval CoffeeScript.compile coffee

## Sample data to simulate loading from file system. ##

sampleStories = 
  googleHomepage:
    """
    story 'Visiting Google',
      '''
      As a google user  
      I want to visit google.com  
      So that I can see my search and other options
      ''', ->

        scenario 'Homepage view', (browser) ->
          ###
          browser
            .given 'Nothing', -> 
               return
             .when 'I visit the homepage', ->
               browser.execute(steps.visitHomepage())
             .then 'I see the correct title', ->
               browser.assertTitle('Google')
          ###
          
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
          
        scenario 'scenario2', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
    """

  googleSearch:
    """
    story 'Executing a search',
      '''
      As a google user  
      I want to perform a search  
      So that I can access the world\'s information
      ''', ->

        scenario 'Search for topic with many results', (browser) ->
           ###
           browser
             .given 'I am on the homepage', -> 
               #browser.execute(steps.visitHomepage())
             .when 'I enter search terms', ->
               #browser.type('q', 'nodejs')
             .and 'submit the search', ->
               #browser.clickAndWait('btnK')
             .then 'I see the correct title', ->
               #browser.assertTitle('nodejs - Google Search')
             .and 'I see search results', ->
               #browser.assertTextPresent('results')
           ###
           
           # Insert a test call so that tests can verify that the
           # scenario body was executed and the browser object was passed.
           browser.execute(steps.testStep())
    """
    
  selectedStory1:
    """
    $story 'selectedStory1Title',
      '''
      selectedStory1Description
      ''', ->

        scenario 'selectedStory1Scenario1', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser

    """
    
  selectedStory2:
    """
    $story 'selectedStory2Title',
      '''
      selectedStory2Description
      ''', ->

        scenario 'selectedStory2Scenario1', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
    """
    
  selectedScenario:
    """
    story 'selectedScenarioStoryTitle',
      '''
      selectedScenarioDescription
      ''', ->

        $scenario 'selectedScenario', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
          
        scenario 'notSelectedScenario', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
    """
    
  ignoredScenario:
    """
    story 'ignoredScenarioStoryTitle',
      '''
      ignoredScenarioDescription
      ''', ->

        xscenario 'ignoredScenario', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
          
        scenario 'notIgnoredScenario', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
    """
    
  ignoredStory:
    """
    xstory 'ignoredStoryTitle',
      '''
      ignoredStoryDescription
      ''', ->

        scenario 'ignoredStoryScenario1', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
          
        scenario 'ignoredStoryScenario2', (browser) ->
          # Return the browser for testing. 
          # Normally happens automatically from the soda client methods.
          browser
    """

sampleSteps = [
  stepDef1 =
    """
    steps.visitHomepage = -> (browser) -> browser.open '/'
    """
    
  stepDef2 =
    """
    steps.testStep = -> (browser) -> return browser
    """
]
    
sampleConfig =
  """
  config.sauceLabs =
    'url':          'http://www.google.com/'
    'username':     'sauce_username'
    'access-key':   'sauce_access_key'
    'max-duration': "100"

  config.browsers = [
    {
      'os':               'Windows 2003'
      'browser':          'firefox'
      'browser-version':  '7'
    }
    {
        'os':               'Linux'
        'browser':          'firefox'
        'browser-version':  '7'
    }
  ]
  """

