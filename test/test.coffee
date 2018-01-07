# build time tests for assets plugin
# see http://mochajs.org/

assets = require '../client/assets'
expect = require 'expect.js'

describe 'assets plugin', ->

  describe 'expand', ->

    # it 'can make itallic', ->
    #   result = assets.expand 'hello *world*'
    #   expect(result).to.be 'hello <i>world</i>'
