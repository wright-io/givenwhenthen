# Given When Then
Simple web app acceptance testing with [BDD](http://dannorth.net/introducing-bdd/)
semantics using Selenium and [Sauce Labs](http://saucelabs.com/).

Based on [Soda](https://github.com/LearnBoost/soda) from the amazing folks at
[LearnBoot](https://github.com/LearnBoost) 

Writing a story that can be easily run against multiple browsers and operating systems
is as simple as:

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
            .then "I see the correct title", ->
              browser.assertTitle('nodejs - Google Search')
            .and "I see search results", ->
              browser
                .assertTextPresent('results')
                .assertTextPresent('node.js')



## Installation

    npm install givenwhenthen
    
## Running Stories

Using _/examples_:  

1. Get a [Sauce Labs](http://saucelabs.com/) account.
2. Set the correct sauce account details in _/examples/test/acceptance/config.coffee_
3. From _/examples_, run `cake test:acceptance`

To use in your own project:

1. Create the test/acceptance directory
2. Populate it with your own stories, steps, and config
3. Execute via your own Cake task or similar (see _/examples/Cakefile_) 

## Writing a story
GivenWhenThen is a DSL for writing executable stories in the 
[Dan North format](http://dannorth.net/whats-in-a-story/)

In a .coffee file, write each story with a description:

    story 'Executing a Google search',
      """
      As a human 
      I want to perform a search 
      So that I can access the world's information
      """, ->

and one or more scenarios:

            scenario "Search for info about Node.js", (browser) ->
          browser
            .given "I am on the homepage", -> 
              browser.execute(steps.visitHomepage())
            .when "I enter search terms", ->
              browser.type('q', 'nodejs')
            .and "submit the search", ->
              browser.click('btnK')
            .then "I see the correct title", ->
              browser.assertTitle('nodejs - Google Search')
            .and "I see search results", ->
              browser
                .assertTextPresent('results')
                .assertTextPresent('node.js')
              
Each scenario has "given", "when", and "then" steps. 

* Given: Setup the initial conditions for the scenario.
* When: Take the action the scenario is testing.
* Then: Assert the conditions expected after taking the tested action.

Each step contains one or more chained calls to 
[Selenium actions](http://release.seleniumhq.org/selenium-core/1.0.1/reference.html) 
in the form of browser.someSeleneseCommand

Each step (given, when, then) can have an arbitrary number of `and` steps following it
(see above example).

## Steps
Often there are steps that are repeated throughout many scenarios 
(e.g. "visit homepage", "sign in").

This kind of functionality can be defined in steps and referred to in scenarios via 
`browser.execute()`.  (E.g. `browser.execute(steps.visitHomepage())` as in the above 
example).

Steps are defined in *_steps.coffee files. Multiple steps per file can be defined 
as follows:  
`steps.visitHomepage = -> (browser) -> browser.open '/'`

Multiple steps files can be defined to organize your steps.

## Config
_config.coffee_ contains the configuration for running the stories.

* Overall story and Sauce Labs configuration.
* Browser / OS definitions.
  * Stories will be run against each browser/os configuration defined.

## Skipping / explicitly selecting stories and scenarios
* To skip one or more stories or scenarios, prefix the story or scenario with 'x'
 * e.g. `xstory` or `xscenario`
* To select only one or more stories or scenarios, prefix the story or scenario with '$'
 * e.g. `$story` or `$scenario`

## Authors
* Doug Wright [wright-io](https://github.com/wright-io)
* Phil Cockfield [philcockfield](https://github.com/philcockfield)

## Background
In addition to being influenced, and based on [Sauce Labs](http://saucelabs.com/), 
Selenium, and [Soda](https://github.com/LearnBoost/soda), GiveWhenThen is also heavily 
indebted to the [BDD movement](http://en.wikipedia.org/wiki/Behavior_Driven_Development) 
and [Cucumber](http://cukes.info/) (and all of the efforts that BDD and Cucumber 
are indebted to - cucumbers all the way down).

## License

The [MIT License](http://www.opensource.org/licenses/mit-license.php) (MIT)  
Copyright © 2011 Phil Cockfield, Doug Wright

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.