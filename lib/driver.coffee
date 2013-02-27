rest = require 'restler'

module.exports = 
  
  ###
  Selenium 2 RemoteWebDriver focused on Sauce Labs and supporting BDD semantics.
  Supports queued, chained command execution, as well as direct command calls.
  Has special methods to structure tests with BDD "Given, When, Then" steps.
  Supports adding "subtitles" to Sauce test videos illustrating the BDD steps.
  ###
  Client: class Client
  
    ###
    Construct a new driver client.
    @option credentials.username: Sauce Labs user name.
    @option credentials['access-key']: Sauce Labs access key.
    @option desiredCapabilities: Settings for the test environment configuration and Sauce Labs.
                                 See: https://saucelabs.com/docs/ondemand/additional-config.
    @option chain: Whether to operate in chained mode. If true, Selenium commands will be 
                   queued and can be chained. The chain will begin executing when `end()` is
                   called. The callback to `end()` is called when on error or when the chain
                   of commands finishes executing. Defaults to false.
    @option subtitles: Whether to add subtitles to the Sauce Labs test video. Defaults to false.
    ###
    constructor: (opts = {}) ->
      @queue = []
      @baseSauceDriverUrl = 'http://ondemand.saucelabs.com/wd/hub/session'
      @sessionID = null
      
      @username = opts.credentials.username
      @accessKey = opts.credentials['access-key']
      @desiredCapabilities = opts.desiredCapabilities
      @chain = opts.chain ?= false
      @subtitles = opts.subtitles ?= false


    ###
    Queue a driver call for chained execution.
    Works in coordination with `end()`, which should be called at the end of the chain.
    @param fn:    Driver command to queue.
    @param args:  Args to pass to the driver command.
    @see `opts.chained` in constructor.
    ###
    enqueue: (fn, args) ->
      # Indirect callback support.
      if typeof args[args.length - 1] is 'function'
        passedCallback = args.pop()
    
      callback = (err, data) =>
        # Since we are always adding a callback, make sure the passed callback is also called.
        if !err && passedCallback?
          try
            passedCallback err, data
          catch err
            return @_done err
      
        if err?
          @_done err
        else if (@queue.length > 0)
          @queue.shift()()
        else
          @_done null
        
      args.push callback
        
      @queue.push =>
        fn.apply @, args
    
      return @


    ###
    Call at the end of a command chain in chained mode.
    Calling this method starts the execution of the command chain.
    Takes a callback to be called at the end of the chain or when an error occurs in the chain.
    @param callback: Callback.
    @see `enqueue()`
    @see `opts.chained` in constructor.
    ###
    end: (callback) ->
      self = @
    
      @_done = (err) -> callback?.call self, err
      
      @queue.shift()()


    ###
    Call a passed step.
    @param fn: Step function.
    ###
    step: (fn) ->
      fn.call @, @
      return @


    ###
    Call a step of a defined type (given, when, then, and).
    @param msg:             Message for the step (e.g. 'I visit the homepage').
    @param stepTypeString:  Type of step ('GIVEN', 'WHEN', 'THEN', 'AND') - used in subtitles.
    @param fn:              Step function.
    ###
    msgStep: (msg, stepTypeString, fn) ->
      if @subtitles then @execute subtitle "#{stepTypeString}: #{msg}"
      @step.call this, fn


    and: (msg, fn) ->
      @msgStep msg, 'AND', fn
  
  
    given: (msg, fn) ->
      @msgStep msg, 'GIVEN', fn
    
    
    when: (msg, fn) ->
      @msgStep msg, 'WHEN', fn
    
    
    then: (msg, fn) ->
      @msgStep msg, 'THEN', fn


    ###
    Convenience method to assert an element is present on the current page.
    @param value:     Element to search for.
    @param callback:  Callback.
    @option using:    Locator strategy to use. Defaults to 'id'.
    @option inverse:  Whether to inverse the result (assert element is not present).
    ###
    assertElementPresent: (value, opts={}, callback) ->
      opts.using    ?= 'id'
      opts.inverse  ?= false
    
      #TODO: All of this chain error handling stinks. Gotta be a cleaner way.
      @elementPresent value, opts, (err, data) ->
        if err? && callback?
          callback err, data
        else if data != opts.inverse
          callback? null, data
        else
          modifierString = ''
          unless opts.inverse then modifierString = ' not'
          err = new Error "Element with #{opts.using}: #{value}#{modifierString} present."
          if callback?
            callback err, data != opts.inverse
          else
            throw err


    ###
    Convenience method to assert an element is not present on the current page.
    @param value:     Element to search for.
    @param callback:  Callback.
    @option using:    Locator strategy to use. Defaults to 'id'.
    ###
    assertElementNotPresent: (value, opts={}, callback) ->
      opts.inverse = true
      @assertElementPresent value, opts, callback


    ###
    Convenience method to assert text is present on the current page.
    @param text:      Text to search for.
    @param callback:  Callback.
    @option inverse:  Whether to inverse the result (assert text is not present).
    ###
    assertTextPresent: (text, opts={}, callback) ->
      # TODO: Again, need a way to not need to pass opts.
      opts.inverse  ?= false
    
      #TODO: All of this chain error handling stinks. Gotta be a cleaner way.
      @textPresent text, (err, data) ->
        if err? && callback?
          callback err, data
        else if data != opts.inverse
          callback? null, data
        else
          modifierString = ''
          unless opts.inverse then modifierString = ' not'
          err = new Error "Text '#{text}'#{modifierString} present."
          if callback?
            callback err, data != opts.inverse
          else
            throw err


    ###
    Convenience method to assert text is not present on the current page.
    @param text:      Text to search for.
    @param callback:  Callback.
    ###
    assertTextNotPresent: (text, callback) ->
      @assertTextPresent text, inverse: true, callback


    ###
    Convenience method to assert page title value.
    @param title:     The title to assert.
    @param callback:  Callback.
    ###
    assertTitle: (title, callback) ->
      @eval 'document.title', (err, data) ->
        if err? && callback?
          callback err, data
        else if data is title
          callback? null, true
        else
          err = new Error "Expected title to be '#{title}' but found '#{data}'."
          if callback?
            callback err, false
          else
            throw err


    ###
    RemoteWebDriver: Delete session.
    Does not chain.
    @see: http://code.google.com/p/selenium/wiki/JsonWireProtocol#DELETE_/session/:sessionId.
    ###
    quit: (callback) -> 
      @_callService @_getSauceDriverUrl(), 'delete', null, (err, data, response) ->
        callback? err


    ###
    Set pass/fail on the Sauce test.
    Does not chain.
    @param callback: Callback.
    ###
    setSauceSuccess: (success, callback) ->
      # Set pass/fail on the Sauce test.
      sauceRestURL = "https://saucelabs.com/rest/v1/#{@username}/jobs/#{@sessionID}"
      data = JSON.stringify(passed: success)
    
      @_callService sauceRestURL, 'put', data, (err, data, response) ->
        callback? err


    _getSauceDriverUrl: (path) ->
      url = @baseSauceDriverUrl + '/' + @sessionID
      if path? then url += '/' + path
      return url


    ###
    Make a web service call.
    @param url:       URL of the service.
    @param method:    HTTP method to use ('get', 'post', 'put', or 'delete')
    @param data:      Data to pass as json in the request body.
    @param callback:  Callback.
    ###
    _callService: (url, method, data, callback) ->
      request = rest.request url,
        username:         @username
        password:         @accessKey
        followRedirects:  false
        method:           method
        parser:           rest.parsers.auto
        data:             data
    
      request.on 'error', (data, response) ->
        err = new Error "Response code: #{response.statusCode} - #{JSON.stringify data}"
        callback? err, data, response
      
      request.on 'success', (data, response) ->
        callback? null, data, response


    ###
    RemoteWebDriver: New session.
    @see: http://code.google.com/p/selenium/wiki/JsonWireProtocol#POST_/session.
    ###
    _driver_init: (callback) ->
      self = @
      url = @baseSauceDriverUrl
      data = JSON.stringify(desiredCapabilities: @desiredCapabilities)
    
      @_callService url, 'post', data, (err, data, response)->
        if err?
          callback? err
        else
          locationArr = response.headers.location.split "/"
          self.sessionID = locationArr[locationArr.length - 1]
          callback? null


    ###
    RemoteWebDriver: URL.
    @see: http://code.google.com/p/selenium/wiki/JsonWireProtocol#GET_/session/:sessionId/url.
    @param targetUrl: URL to navigate to.
    @param callback:  Callback.
    ###
    _driver_get: (targetUrl, callback) ->
      url = @_getSauceDriverUrl 'url'
      
      @_callService url, 'post', JSON.stringify(url: targetUrl), (err, data, response) ->
        callback? err
  
    ###
    RemoteWebDriver: Element.
    @see:
      http://code.google.com/p/selenium/wiki/JsonWireProtocol#POST_/session/:sessionId/element.
    @param value:     Element to search for.
    @param callback:  Callback.
    @options using:   Locator strategy to use. Defaults to 'id'.
    @returns: Selenium WebElement ID or null if element not found.
    ###    
    _driver_element: (value, opts={}, callback) ->
      opts.using ?= 'id'
      url = @_getSauceDriverUrl 'element'
    
      data = JSON.stringify {
        using: opts.using
        value: value
      }
      
      @_callService url, 'post', data, (err, data, response) ->
        # TODO: Check general error handling. 
        # Am I doing it right, or should we be doing more throwing and catching instead
        # of passing.
        
        # If we get a 500, that means the element wasn't found.
        if err? && response.statusCode is 500
          err = data = null
        else 
          data = data.value.ELEMENT
      
        callback? err, data

    ###
    RemoteWebDriver: Elements.
    @see:
      http://code.google.com/p/selenium/wiki/JsonWireProtocol#POST_/session/:sessionId/element.
    @param value:     Elements to search for.
    @param callback:  Callback.
    @options using:   Locator strategy to use. Defaults to 'id'.
    @returns: Selenium WebElement ID or null if element not found.
    ###    
    _driver_elements: (value, opts={}, callback) ->
      opts.using ?= 'id'
      url = @_getSauceDriverUrl 'elements'
    
      data = JSON.stringify {
        using: opts.using
        value: value
      }
      
      @_callService url, 'post', data, (err, data, response) ->
        # TODO: Check general error handling. 
        # Am I doing it right, or should we be doing more throwing and catching instead
        # of passing.
        
        # If we get a 500, that means the element wasn't found.
        if err? && response.statusCode is 500
          err = data = null
        else 
          data = data.value.ELEMENT
      
        callback? err, data


    ###
    Wrapper for RemoteWebDriver element/click that takes a locator strategy and search value.
    @see:
      http://code.google.com/p/selenium/wiki/JsonWireProtocol#POST_/session/:sessionId/element.
    @param value:     Element to search for.
    @param callback:  Callback.
    @option using:    Locator strategy to use. Defaults to 'id'.
    @returns: Selenium WebElement ID or null if element not found.
    ### 
    _driver_clickElement: (value, opts={}, callback) ->
      self = @
      opts.using ?= 'id'
    
      @_driver_element value, opts, (err, data) ->
        if err?
          callback? err, data
        else
          if data?
            url = self._getSauceDriverUrl "element/#{data}/click"
        
            self._callService url, 'post', null, (err, data, response) ->
              callback? err
          else
            # If data is null, the element wasn't found, so we can't click it.
            err = new Error "Element with #{opts.using}: #{value} not present."
            callback? err


    ###
    Wrapper for RemoteWebDriver: element/:id/value.
    @see:
      http://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/element/:id/value
    @param elementValue:  Element to search for.
    @param text:          Text to type. Can be String or Array.<string> (see RemoteWebDriver API).
    @param callback:      Callback.
    @option using:        Locator strategy to use. Defaults to 'id'.
    ###
    # TODO: Problem: can't leave out opts in caller without screwing up callback.
    _driver_typeInElement: (elementValue, text, opts={}, callback) ->
      self = @
      opts.using ?= 'id'
    
      @_driver_element elementValue, opts, (err, data) ->
        if err?
          callback? err, data
        else
          if data?
            elementID = data
            if typeof text is 'string' then text = text.split('')
            data = JSON.stringify(value: text)
      
            url = self._getSauceDriverUrl "element/#{elementID}/value"
        
            self._callService url, 'post', data, (err, data, response) ->
              callback? err
          else
            # If data is null, the element wasn't found, so we can't type into it.
            err = new Error "Element with #{opts.using}: #{elementValue} not present."
            callback? err


    ###
    RemoteWebDriver: Execute.
    NOTE: Not passing args because they can easily be passed in the script.
    @see: http://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/execute
    ###
    _driver_execute: (script, callback) ->
      url = @_getSauceDriverUrl 'execute'
      data = JSON.stringify {
        script: script
        args:   []
      }
    
      @_callService url, 'post', data, (err, data, response) ->
        callback? err, data.value


    ###
    Wrapper for RemoteWebDriver: Execute, which returns the value of the script.
    @see: http://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/execute
    @see: `_execute`
    ###
    _driver_eval: (script, callback) -> @_driver_execute "return #{script}", callback


    ###
    Convenience method to determine if an element is present on the page.
    @param value:     The element to search for.
    @param callback:  Callback.
    @option using:    Locator strategy to use. Defaults to 'id'.
    ###
    _driver_elementPresent: (value, opts={}, callback) ->
      opts.using ?= 'id'
    
      @_driver_element value, opts, (err, data) ->
        if err? && callback?
          callback err, data
        else
          callback? null, data?


    ###
    Convenience method to determine if text is present on the page.
    @param text:      Text to search for.
    @param callback:  Callback.
    ###
    _driver_textPresent: (text, callback) ->
      @_driver_elementPresent "//*[contains(.,'#{text}')]", using:'xpath', callback


    ###
    RemoteWebDriver: implicit_wait
    @see: http://code.google.com/p/selenium/wiki/JsonWireProtocol#/session/:sessionId/timeouts/implicit_wait
    ###
    _driver_setImplicitWait: (ms, callback) ->
      url = @_getSauceDriverUrl 'timeouts/implicit_wait'
      data = JSON.stringify(ms: ms)
    
      @_callService url, 'post', data, (err, data, response) ->
        callback? err, data.value


    ###
    Add public commands for ever '_driver_*' method.
    Each created method with delegate to the corresponding private method and will queue
    if `chain` is true.
    ###
    _addCommands: ->
      for key of @
        if _(key).startsWith '_driver_'
          command = _.strRight key, '_driver_'
          
          do (key, command) =>
            @[command] = (args...) ->
              if @chain
                @enqueue @[key], args
              else
                @[key].apply @, args


    do ->
      Client::_addCommands()


# PRIVATE -----

###
Create HTML for a subtitle div.
@param text: Text to display in the subtitle HTML.
###
createSubtitleMarkup = (text) -> 
  toStyle = (def) -> 
    style = ''
    for key of def
      style += key + ':' + def[key] + '; '
    style
    
  css = toStyle
    'position':       'absolute'
    'bottom':         '0px'
    'left':           '0px'
    'right':          '0px'
    'padding':        '15px'
    'color':          '#333'
    'font-size':      '11pt'
    'font-family':    'Lucida Grande, Helvetica Neue, Tahoma, Arial'
    'border-top':     'solid 1px #4d4d4d'
    'background':     '#f5f5f5'
    'box-shadow':     '0px -3px 10px 0px rgba(0,0,0,0.06)'
    
  html =  "<div class='gwt_step' style='" + css  + "'>"
  html += text
  html += "</div>"
  html


###
Return JavaScript to insert subtitle HTML into a div into a page.
@param html: HTML to place in the injected div.
###
createSubtitleJs = (html) -> 
  js =  'var el = document.createElement("div");'
  js += 'el.innerHTML = "' + html + '";'
  js += 'document.body.appendChild(el);'
  js


###
Convenience method for creating subtitle div javascript for the given text.
@param text: Text to display in the subtitle HTML.
###
subtitle = (text) ->
  return createSubtitleJs createSubtitleMarkup(text)

