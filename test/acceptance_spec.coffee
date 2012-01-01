CoffeeScript  = require 'coffee-script'
core          = require 'open.core'
util          = core.util
fsUtil        = require '../lib/fs'
acceptance    = require '../lib/acceptance'
driver        = require '../lib/driver'

describe 'acceptance', ->
  mock = null
  
  beforeEach ->
    
    # Swallow process logging to keep test output clean
    core.util.log.silent = true
    
    # Prepare mocks and spies.
    mock =
      # Mocking methods on Client (returned as `browser`).
      # These get called as a part of running a scenario.
      browser:
        init: ->
        end: (err) ->
        quit: ->
        setSauceSuccess: ->
        step: ->
          return mock.browser
    
    # The way that acceptance class gets the data files.
    spyOn(fsUtil, 'evaluateFilesSync')    
    
    # The methods we are mocking on the client.
    #
    # Some of these methods chain, so need to both be called on and return the browser.
    spyOn(mock.browser, 'init')
    spyOn(mock.browser, 'step').andReturn mock.browser
    spyOn(driver, 'Client').andReturn mock.browser
    
    spyOn(mock.browser, 'setSauceSuccess').andCallFake (success, callback) -> callback()
    spyOn(mock.browser, 'quit').andCallFake (callback) -> callback()
    
    # This method is called when the async test finishes so we need to mock it to 
    # get our callback called.
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
      # Make sure the client was correctly created for each sample story supplied.
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
        .toEqual 'Visiting Google: Homepage view'
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
        .toEqual 'VISTA'
  
      expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
        .toEqual 'Visiting Google: Homepage view'
      expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
        .toEqual 'LINUX'
        
      expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].name)
        .toEqual 'Visiting Google: scenario2'
      expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].platform)
        .toEqual 'VISTA'
        
      expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].name)
        .toEqual 'Visiting Google: scenario2'
      expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].platform)
        .toEqual 'LINUX'
          
      expect(driver.Client.argsForCall[4][0]['desiredCapabilities'].name)
        .toEqual 'Executing a search: Search for topic with many results'
      expect(driver.Client.argsForCall[4][0]['desiredCapabilities'].platform)
        .toEqual 'VISTA'
          
      expect(driver.Client.argsForCall[5][0]['desiredCapabilities'].name)
        .toEqual 'Executing a search: Search for topic with many results'
      expect(driver.Client.argsForCall[5][0]['desiredCapabilities'].platform)
        .toEqual 'LINUX'


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
      expect(mock.browser.init.callCount).toEqual 2


    it 'runs test finalization after each scenario body', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      expect(mock.browser.end.callCount).toEqual 2
      expect(mock.browser.quit.callCount).toEqual 2
      expect(mock.browser.setSauceSuccess.callCount).toEqual 2


    it 'correctly configures the client', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify.
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
        .toEqual 'Executing a search: Search for topic with many results'
      expect(driver.Client.argsForCall[0][0]['credentials'].username)
        .toEqual 'sauce_username'
      expect(driver.Client.argsForCall[0][0]['credentials']['access-key'])
        .toEqual 'sauce_access_key'
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities']['max-duration'])
        .toEqual '100'
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
        .toEqual 'VISTA'
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].browserName)
        .toEqual 'firefox'
      expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].version)
        .toEqual '7'
      expect(driver.Client.argsForCall[0][0]['chain']).toBeTruthy()


    it 'passes the configured client to the scenario and executes the scenario body', ->
      # Call method under test.
      acceptance.runStories()
  
      # Verify. 
      # We are calling mock.browser.step(steps.testStep) in one of the sample stories
      # below, so if the method got called, the browser was passed correctly to the scenario
      # and the body was executed.
      expect(mock.browser.step).toHaveBeenCalled()


    describe 'success reporting', ->
      beforeEach ->
        # Call method under test.
        acceptance.runStories()
      
      it 'reports success when all stories pass', ->
        # Verify.
        expect(util.log.argsForCall[1][0]).toContain("Done")
        expect(util.log.argsForCall[1][1]).toEqual(color.green)


      it 'prints a green dot for every successful test that is executed', ->
        # Verify.
        expect(core.util.log.append.argsForCall[0][0]).toEqual('.')
        expect(core.util.log.append.argsForCall[0][1]).toEqual(color.green)
        expect(core.util.log.append.argsForCall[1][0]).toEqual('.')
        expect(core.util.log.append.argsForCall[1][1]).toEqual(color.green)
        expect(core.util.log.append.callCount).toEqual 2


      it 'sets success on the sauce test', ->
        # Verify.
        expect(mock.browser.setSauceSuccess.argsForCall[0][0]).toEqual true


    describe 'failure reporting', ->
    
      beforeEach ->
        # Prepare mocks and spies.
        mock.error =
          message: "Epic fail."
          storyTitle: "storyTitle"
          browserConfig:
            browserName: "browserName"
            version: "version"
            platform: "platform"
        mock.browser.end.andCallFake (callback) ->
          callback mock.error


      it 'reports failure for each scenario that fails', ->  
        # Call method under test.
        acceptance.runStories()
      
        # Verify.
        expect(util.log.argsForCall[2][0]).toEqual(mock.error.message)
        expect(util.log.argsForCall[2][1]).toEqual(color.red)
    
        expect(util.log.argsForCall[4][0]).toContain mock.error.storyTitle
    
        expect(util.log.argsForCall[5][0])
          .toContain mock.error.browserConfig['browserName']
        expect(util.log.argsForCall[5][0])
          .toContain mock.error.browserConfig['version']
        expect(util.log.argsForCall[5][0])
          .toContain mock.error.browserConfig['platform']


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

      it 'sets failure on the sauce test', ->
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        expect(mock.browser.setSauceSuccess.argsForCall[0][0]).toEqual false

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
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
        
        expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].name)
          .toEqual 'selectedStory2Title: selectedStory2Scenario1'
        expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].name)
          .toEqual 'selectedStory2Title: selectedStory2Scenario1'
        expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
          
        expect(driver.Client.callCount).toEqual 4


      it 'runs only the specified scenarios if requested', ->
        mockDataLoading selectedScenariosTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
          
        expect(driver.Client.callCount).toEqual 2


      it 'supports a mix of specified stories and scenarios', ->
        mockDataLoading selectedStoriesAndScenariosTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
          .toEqual 'selectedStory1Title: selectedStory1Scenario1'
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
        
        expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].name)
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].name)
          .toEqual 'selectedScenarioStoryTitle: selectedScenario'
        expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
          
        expect(driver.Client.callCount).toEqual 4


      it 'runs only the specified browser/os config if requested', ->
        mockDataLoading singleStoryTestSet()
        
        # Call method under test.
        acceptance.runStories(browser:2)
        
        # Verify.
        # Expect only the specified browser to be used.
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'Executing a search: Search for topic with many results'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
          
        expect(driver.Client.callCount).toEqual 1


      it 'configures the client to add subtitles if requested', ->
        mockDataLoading singleStoryTestSet()
        
        # Call method under test.
        acceptance.runStories(subtitles:true)
        
        # Verify.
        expect(driver.Client.argsForCall[0][0]['subtitles']).toBeTruthy()


      it 'ignores scenarios prefixed with "x"', ->
        mockDataLoading ignoredScenarioTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
          
        expect(driver.Client.callCount).toEqual 2


      it 'ignores stories prefixed with "x"', ->
        mockDataLoading ignoredStoryTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'Executing a search: Search for topic with many results'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
    
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
          .toEqual 'Executing a search: Search for topic with many results'
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'    

        expect(driver.Client.callCount).toEqual 2


      it 'supports a mix of ignored stories and scenarios', ->
        mockDataLoading ignoredStoriesAndScenariosTestSet()
        
        # Call method under test.
        acceptance.runStories()
        
        # Verify.
        # Because of the selected set of stories used, expect specific scenarios
        # to be run, and only those scenarios.
        # Some of the decoration on `story` and `scenario` method calls affects this.
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].name)
          .toEqual 'Executing a search: Search for topic with many results'
        expect(driver.Client.argsForCall[0][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
    
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].name)
          .toEqual 'Executing a search: Search for topic with many results'
        expect(driver.Client.argsForCall[1][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'
          
        expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].name)
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(driver.Client.argsForCall[2][0]['desiredCapabilities'].platform)
          .toEqual 'VISTA'
  
        expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].name)
          .toEqual 'ignoredScenarioStoryTitle: notIgnoredScenario'
        expect(driver.Client.argsForCall[3][0]['desiredCapabilities'].platform)
          .toEqual 'LINUX'

        expect(driver.Client.callCount).toEqual 4

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
               browser.step(steps.visitHomepage)
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
               #browser.step(steps.visitHomepage)
             .when 'I enter search terms', ->
               #browser.typeInElement('q', 'nodejs', using:'name')
             .and 'submit the search', ->
               #browser.clickElement('btnG', using:'name')
             .then 'I see the correct title', ->
               #browser.assertTitle('nodejs - Google Search')
             .and 'I see search results', ->
               #browser.assertTextPresent('results')
           ###
           
           # Insert a test call so that tests can verify that the
           # scenario body was executed and the browser object was passed.
           browser.step(steps.testStep)
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
    steps.visitHomepage = (browser) -> browser.get 'http://www.google.com'
    """
    
  stepDef2 =
    """
    steps.testStep = (browser) -> return browser
    """
]
    
sampleConfig =
  """
  config.credentials =
    'username':             'sauce_username'
    'access-key':           'sauce_access_key'
  
  config.settings =
    'max-duration':         '100'

  config.browsers = [
    {
      'platform':     'VISTA'
      'browserName':  'firefox'
      'version':      '7'
    }
    {
      'platform':     'LINUX'
      'browserName':  'firefox'
      'version':      '7'
    }
  ]
  """

