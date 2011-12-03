story 'Executing a Google search',
  """
  As a human 
  I want to perform a search 
  So that I can access the world's information
  """, ->

    scenario "Search for info about Node.js", (browser) ->
      browser
        .given "I am on the homepage", -> 
          browser.execute(steps.visitHomepage())
        .when "I enter search terms", ->
          browser.type('q', 'nodejs')
        .and "submit the search", ->
          browser.click('btnK')
        .then "I see search results", ->
          browser.assertTextPresent('results')
        .and "the results contain information about nodejs", ->
          browser
            .assertTextPresent('node.js')
            .assertTextPresent('nodejs.org')
            