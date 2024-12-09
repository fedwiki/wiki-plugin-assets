// see http://mochajs.org/

import { assets } from '../client/assets.js'
import expect from 'expect.js'

describe('assets plugin', () => {
  describe('expand', () => {
    it('can escape html markup characters', () => {
      const result = assets.expand('try < & >')
      expect(result).to.be('try &lt; &amp; &gt;')
    })
  })
})
