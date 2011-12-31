core      = require 'open.core'
fsUtil    = require './fs.coffee'
driver    = require './driver'

BASE_DIR        = 'test/acceptance'
stories         = []
selectedStories = []
global.config   = browsers: []

###
Module: Given/When/Then acceptance test semantics wrapper around Sauce Labs Selenium testing.
###
module.exports =
  ###
  Execute each story against the matrix of browsers.
  @param  callback:   Invoked upon completion,
  @option throw:      If true, will throw error on failed scenarios.
  @option directory:  If provided, will be used as base directory for loading data files.
  @option browser:    Number (1-based) of the browser from config.browsers to use.
                      If provided, only selected browser will be used.
  @option subtitles:  If true, subtitles for steps will be added to test video.
  ###
  runStories: (options = {}) ->
    # Setup initial conditions.
    if options.directory? then BASE_DIR = options.directory
    loadStepsSync()
    loadConfigSync(options.browser)
    credentials = config.credentials
    settings = config.settings
    getStoriesSync()
    count = 0
    errors = []
    
    # Count the total number of scenarios so we can track completion.
    numberOfScenarios = 0
    for story in stories
      numberOfScenarios += story.scenarios.length
    
    onComplete = ->
      count += 1
      
      if count == (numberOfScenarios * config.browsers.length)
        if errors.length > 0
          log '\nCompleted with errors.\n', color.red
          for err in errors
            log err.message, color.red
            log()
            log " - Story: #{err.storyTitle}"
            log " - Browser: #{err.browserConfig['browserName']} | " +
              "#{err.browserConfig['version']} | #{err.browserConfig['platform']}"
            log()
             
          if options.throw?
            # Throw an error so that the process fails (e.g. for a CI step). 
            throw new Error("Failed with #{errors.length} errors.")
        else
          log '\nDone\n', color.green
    
    log "Running #{stories.length} stories containing #{numberOfScenarios} scenarios " +
      "against #{config.browsers.length} browser/os configurations...",
      color.blue

    # Enumerate each story, executing the scenarios against each configuration.
    for story in stories
      for scenario in story.scenarios  
        for browserConfig in config.browsers
          
          # Invoke the scenario.
          title = "#{story.title}: #{scenario.title}"
          browser = createWebDriver title, 
            credentials, settings, browserConfig, options.subtitles
          
          do (title, browser, browserConfig) ->
            
            # Invoke the scenario with the prepared browser client.
            scenario(browser)
            
            # Set up the callback for the scenario (also kicks it off).
            browser.end (err) ->
              if err?
                err.storyTitle = title
                err.browserConfig = browserConfig
                errors.push err
              
              log.append '.', if err? then color.red else color.green
              
              # Check for completion and, if complete, report success or errors.
              onComplete()


###
Global DSL: Represents a user-story - containing one or more scenarios.
@param title: The title of the story.
@param story: The description of the story.
@param fn:    The function containing the executable story.
###
global.story = (title, description, fn) ->
  # Delayed execution.  
  #   NB: Store the function for later execution.  This allows
  #   us to execute the story-function multiple times with different
  #   browser/OS configurations.
  deferStory this, title, description, fn


###
Convenience function to indicate an explicitly selected story.
If any stories are explicitly selected, only those stories will be run.
@param title: The title of the story.
@param story: The description of the story.
@param fn:    The function containing the executable story.
###
global.$story = (title, description, fn) ->
  deferStory this, title, description, fn, selected:true


###
Convenience function to indicate a disabled story (no-op).
###
global.xstory = ->


###
Convenience function to indicate a disabled scenario (no-op).
###
global.xscenario = ->


# PRIVATE --------------------------------------------------------------------------

###
Returns a story object with metadata and a function which can be executed later.
@param    self:         The context to execute the function containing the story.
@param    storyTitle:   The title of the story.
@param    description:  The description of the story.
@param    fnStory:      The function containing the executable story
@options  selected:     If true, the story will be marked as explicitly selected.
###
deferStory = (self, storyTitle, description, fnStory, options={}) -> 
  story = 
    title:              storyTitle
    description:        description
    scenarios:          []
    selectedScenarios:  []

  ###
  Represents a scenario.
  Will be passed a configured client and executed.
  @param scenarioTitle: The title of the scenario.
  @param fnScenario:    The function containing the executable scenario.
  ###
  global.scenario = (scenarioTitle, fnScenario) ->
    story.scenarios.push deferScenario self, scenarioTitle, storyTitle, fnScenario
    
  ###
  Convenience function to indicate an explicitly selected scenario.
  If any scenario are explicitly selected, only those scenario will be run.
  @param scenarioTitle: The title of the scenario.
  @param fnScenario:    The function containing the executable scenario.
  ###
  global.$scenario = (scenarioTitle, fnScenario) ->
    story.selectedScenarios.push deferScenario self, scenarioTitle, storyTitle, fnScenario

  ###
  Execute the story.
  This will store all of the scenarios in the stories scenarios arrays using the
  functions defined inline above.
  ###
  fnStory.call(self, self)
  
  ###
  Check for explicitly selected scenarios.
  If any are found, only those scenarios will be executed.
  ### 
  if story.selectedScenarios.length > 0
    story.scenarios = story.selectedScenarios
    options.selected = true

  if options.selected? then selectedStories.push story else stories.push story


###
Returns a scenario object with metadata and a function which can be executed later.
@param self:           The context to execute the function containing the scenario.
@param scenarioTitle:  The title of the scenario.
@param storyTitle:     The title of the story to which the scenario belongs.
@param fnScenario:     The function containing the executable scenario.
###
deferScenario = (self, scenarioTitle, storyTitle, fnScenario) ->
  fn = (browser) -> fnScenario.call(self, browser)

  fn.title      = scenarioTitle
  fn.storyTitle = storyTitle

  return fn


###
Returns a Client (Selenium 2 RemoteWebDriver) that is used to run a scenario.
@param title:         Title for the test.
@param credentials:   Sauce credentials.
@param settings:      Sauce settings.
@param browserConfig: Sauce browser/os configuration.
@param subtitiles:    Whether to display subtitles for steps.
###  
createWebDriver = (title, credentials, settings, browserConfig, subtitles) ->
  settings.name = title
  
  opts = 
    credentials:          credentials
    desiredCapabilities:  _(settings).extend browserConfig
    chain:                true
    subtitles:            subtitles
    
  browser = new driver.Client clone(opts)
  browser.init()
  return browser


###
TODO: Fix this in jasmine?
Only doing this because jasmine argsForCall holds onto args and values get overwritten
  so that it's always the same value for all calls after exectution is over.
###  
clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  newInstance = new obj.constructor()

  for key of obj
    newInstance[key] = clone obj[key]

  return newInstance


###
Evaluates each story file and returns the set of test functions.  
###
getStoriesSync = -> 
  # Reset the cache of story functions.
  stories = []
  selectedStories = []

  # Load the story files. Each story will put itself into one of the `stories` arrays.
  fsUtil.evaluateFilesSync BASE_DIR, 'test.coffee'

  filterForSelectedStories()


###
Loads the set of step files.
###
loadStepsSync = -> 
  # Each step file adds one or more a functions as properties to this object.
  steps ?= {}
  fsUtil.evaluateFilesSync BASE_DIR, 'steps.coffee'


###
Loads the configuration file.
###
loadConfigSync = (browser=null)-> 
  config ?= {}
  fsUtil.evaluateFilesSync BASE_DIR, 'config.coffee'
  
  if browser? then config.browsers = [config.browsers[browser - 1]]


###
Check for explicitly selected stories.
If any are found, only those stories will be executed.
### 
filterForSelectedStories = ->
  if selectedStories.length > 0 then stories = selectedStories


###
Wrapper for core.util.log
@param message: Message to write.
@param color: Color to write with.
###
log = (message, color) ->
  core.util.log message, color


###
Wrapper for core.util.log
@param message: Message to write.
@param color: Color to write with.
###  
log.append = (message, color) ->
  core.util.log.append message, color

