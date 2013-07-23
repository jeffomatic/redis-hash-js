assert = require('assert')
sinon = require('sinon')

testHelper = require('./test_helper')
RedisHash = require('../lib/redis_hash')

redisClient = testHelper.getRedisClient()

describe 'RedisHash', () ->

  beforeEach (done) ->
    @attribHash = new RedisHash(redisClient, 'testKey')
    @attribHash.on 'error', (@errorSpy = sinon.spy())
    redisClient.flushdb (err, result) =>
      throw err if err?
      done()

  describe '#_redisExect', () ->

    it 'should pass arbitrary arguments', (done) ->
      @attribHash._redisExec 'hmset', 'testKey', 'a', 'apple', 'b', 'blueberry', (err) =>
        throw err if err
        redisClient.hgetall 'testKey', (err, results) =>
          throw err if err
          assert.deepEqual results, a: 'apple', b: 'blueberry'
          done()

    it 'should emit errors', (done) ->
      # Intentionally pass an insufficient number of arguments.
      @attribHash._redisExec 'hdel', (err) =>
        assert err
        assert @errorSpy.calledWith(err)
        done()

  describe '#set', () ->

    describe 'key/value hash syntax', () ->

      beforeEach (done) ->
        @initialValues =
          a: '1'
          b: '2'
          c: '3'
          d: '4'

        @attribHash.set @initialValues, (err, result) ->
          throw err if err?
          done()

      it 'should persist a hash of values in Redis', (done) ->
        redisClient.hgetall @attribHash.key, (err, result) =>
          throw err if err?
          assert.deepEqual result, @initialValues
          done()

      it 'should not clobber existing values', (done) ->
        newValues =
          e: '4'
          f: '5'

        @attribHash.set newValues, (err, result) =>
          throw err if err?
          redisClient.hgetall @attribHash.key, (err, result) =>
            throw err if err?
            assert.equal result[k], v for k, v of @initialValues
            assert.equal result[k], v for k, v of newValues
            done()

      it 'should encode boolean values', (done) ->
        values =
          e: true
          f: false

        @attribHash.set values, (err, result) =>
          throw err if err?
          redisClient.hgetall @attribHash.key, (err, result) =>
            throw err if err?
            assert.equal result.e, '1'
            assert.equal result.f, '0'
            done()

      it 'should remove non-existent values', (done) ->
        values =
          a: false # existent
          b: 0 # existent
          c: undefined # non-existent
          d: null # non-existent

        existentEncoded = {}
        for k, v of values
          existentEncoded[k] = @attribHash._encode(v) if v?

        @attribHash.set values, (err, result) =>
          throw err if err?
          redisClient.hgetall @attribHash.key, (err, result) =>
            assert.deepEqual result, existentEncoded
            done()

    describe 'key/value pair syntax', () ->

      beforeEach (done) ->
        @attribHash.set 'foo', 'bar', (err, results) =>
          throw err if err?
          done()

      it "should persist values into Redis", (done) ->
        redisClient.hget @attribHash.key, 'foo', (err, result) =>
          throw err if err?
          assert.equal result, 'bar'
          done()

      it 'should encode boolean true values', (done) ->
        @attribHash.set 'foo', true, (err, result) =>
          throw err if err?
          redisClient.hget @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            assert.equal result, '1'
            done()

      it 'should encode boolean false values', (done) ->
        @attribHash.set 'foo', false, (err, result) =>
          throw err if err?
          redisClient.hget @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            assert.equal result, '0'
            done()

      it 'should remove null values', (done) ->
        @attribHash.set 'foo', null, (err, result) =>
          throw err if err?
          redisClient.hexists @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            assert.equal result, 0
            done()

      it 'should remove undefined values', (done) ->
        @attribHash.set 'foo', undefined, (err, result) =>
          throw err if err?
          redisClient.hexists @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            assert.equal result, 0
            done()

  describe '#get', () ->

    describe 'get-everything syntax', () ->

      beforeEach (done) ->
        @attribs =
          a: 'first'
          b: 'second'
          c: 'third'

        @attribHash.set @attribs, (err, result) =>
          throw err if err?
          done()

      it 'should return the entire hash of values', (done) ->
        @attribHash.get (err, result) =>
          throw err if err?
          assert.deepEqual result, @attribs
          done()

      it 'should return null if the hash is empty', (done) ->
        redisClient.hdel @attribHash.key, Object.keys(@attribs)..., (err, result) =>
          throw err if err?
          @attribHash.get (err, result) =>
            throw err if err?
            assert !result?
            done()

    describe 'get-value syntax', () ->

      beforeEach (done) ->
        @attribHash.set 'foo', 'bar', (err, result) ->
          throw err if err?
          done()

      it 'should correctly return the name value', (done) ->
        @attribHash.get 'foo', (err, result) =>
          throw err if err?
          assert.equal result, 'bar'
          done()

      it "should return null for values that don't exist", (done) ->
        @attribHash.get 'foobar', (err, result) ->
          throw err if err?
          assert !result?
          done()

  describe '#delete', () ->

    beforeEach (done) ->
      @attribHash.set 'foo', 'bar', (err, result) ->
        throw err if err?
        done()

    it 'should delete individual values from the hash', (done) ->
      @attribHash.delete 'foo', (err, result) =>
        throw err if err?
        redisClient.hexists @attribHash.key, 'foo', (err, result) ->
          throw err if err?
          assert.equal result, 0
          done()

  describe '#clear', () ->

    beforeEach (done) ->
      @attribHash.set { a: 'first', b: 'second' }, (err, result) =>
        throw err if err?
        done()

    it 'should remove the hash from Redis', (done) ->
      @attribHash.clear (err, result) =>
        throw err if err?
        redisClient.exists @attribHash.key, (err, result) ->
          throw err if err?
          assert.equal result, 0
          done()

  describe 'flag attributes', () ->

    describe '#getFlag', () ->

      beforeEach (done) ->
        @attribHash.set 'foo', true, (err, result) =>
          throw err if err?
          @attribHash.set 'bar', false, (err, result) ->
            throw err if err?
            done()

      it 'should return true for values set with #set(true)', (done) ->
        @attribHash.getFlag 'foo', (err, result) ->
          throw err if err?
          assert.equal result, true
          done()

      it 'should return false for values set with #set(false)', (done) ->
        @attribHash.getFlag 'bar', (err, result) ->
          throw err if err?
          assert.equal result, false
          done()

      it 'should return null for non-existent values', (done) ->
        @attribHash.getFlag 'foobar', (err, result) ->
          throw err if err?
          assert !result?
          done()

    describe '#getFlags', () ->

      beforeEach (done) ->
        @attribHash.set a: '1', b: '0', c: 'not a boolean', (err) =>
          throw err if err
          done()

      it 'should return values as an object', (done) ->
        @attribHash.getFlags 'a', 'b', (err, results) =>
          throw err if err
          assert results.a
          assert results.b? && !results.b
          done()

      it 'should accept an array argument', (done) ->
        @attribHash.getFlags ['a', 'b'], (err, results) =>
          throw err if err
          assert results.a
          assert results.b? && !results.b
          done()

      it 'should return null for non-boolean encoded values', (done) ->
        @attribHash.getFlags 'a', 'b', 'c', (err, results) =>
          throw err if err
          assert results.a
          assert results.b? && !results.b
          assert !results.c?
          done()

  describe 'counter attributes', () ->

    describe '#inc', () ->

      beforeEach (done) ->
        @attribs =
          foo: 1
          bar: 'hey hey hey'
        @attribHash.set @attribs, (err, result) ->
          throw err if err?
          done()

      describe "default increment value", () ->

        it 'should return and persist the incremented value', (done) ->
          @attribHash.inc 'foo', (err, result) =>
            throw err if err?
            assert.equal result, (@attribs.foo + 1)
            @attribHash.get 'foo', (err, result) =>
              throw err if err?
              assert.equal result, (@attribs.foo + 1).toString()
              done()

        it 'should treat non-existent values as zero', (done) ->
          @attribHash.inc 'foobar', (err, result) =>
            throw err if err?
            assert.equal result, 1
            @attribHash.get 'foobar', (err, result) =>
              throw err if err?
              assert.equal result, '1'
              done()

        it 'should return errors on non-numeric values', (done) ->
          @attribHash.inc 'bar', (err, result) =>
            assert @errorSpy.calledWith(err)
            assert err.message.match /ERR hash value is not an integer/
            done()

      it 'should accept arbitrary positive increments', (done) ->
        @attribHash.inc 'foo', 5, (err, result) =>
          throw err if err?
          assert.equal result, @attribs.foo + 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            assert.equal result, (@attribs.foo + 5).toString()
            done()

      it 'should accept arbitrary negative increments', (done) ->
        @attribHash.inc 'foo', -5, (err, result) =>
          throw err if err?
          assert.equal result, @attribs.foo - 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            assert.equal result, (@attribs.foo - 5).toString()
            done()

    describe '#dec', () ->

      beforeEach (done) ->
        @attribs =
          foo: 1
          bar: 'hey hey hey'
        @attribHash.set @attribs, (err, result) ->
          throw err if err?
          done()

      describe "default decrement value", () ->

        it 'should return and persist the decremented value', (done) ->
          @attribHash.dec 'foo', (err, result) =>
            throw err if err?
            assert.equal result, (@attribs.foo - 1)
            @attribHash.get 'foo', (err, result) =>
              throw err if err?
              assert.equal result, (@attribs.foo - 1).toString()
              done()

        it 'should treat non-existent values as zero', (done) ->
          @attribHash.dec 'foobar', (err, result) =>
            throw err if err?
            assert.equal result, -1
            @attribHash.get 'foobar', (err, result) =>
              throw err if err?
              assert.equal result, '-1'
              done()

        it 'should return errors on non-numeric values', (done) ->
          @attribHash.dec 'bar', (err, result) =>
            assert @errorSpy.calledWith(err)
            assert err.message.match /ERR hash value is not an integer/
            done()

      it 'should accept arbitrary positive decrements', (done) ->
        @attribHash.dec 'foo', 5, (err, result) =>
          throw err if err?
          assert.equal result, @attribs.foo - 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            assert.equal result, (@attribs.foo - 5).toString()
            done()

      it 'should accept arbitrary negative decrements', (done) ->
        @attribHash.dec 'foo', -5, (err, result) =>
          throw err if err?
          assert.equal result, @attribs.foo + 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            assert.equal result, (@attribs.foo + 5).toString()
            done()