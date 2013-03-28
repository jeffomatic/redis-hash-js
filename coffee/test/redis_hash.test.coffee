testHelper = require('./test_helper')
RedisHash = require('../lib/redis_hash')
should = require('should')

redisClient = testHelper.getRedisClient()

describe 'RedisHash', () ->

  beforeEach (done) ->
    @attribHash = new RedisHash(redisClient, 'testKey')
    redisClient.flushdb (err, result) =>
      throw err if err?
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
          result.should.eql @initialValues
          done()

      it 'should not clobber existing values', (done) ->
        newValues =
          e: '4'
          f: '5'

        @attribHash.set newValues, (err, result) =>
          throw err if err?
          redisClient.hgetall @attribHash.key, (err, result) =>
            throw err if err?
            result[k].should == v for k, v of @initialValues
            result[k].should == v for k, v of newValues
            done()

      it 'should encode boolean values', (done) ->
        values =
          e: true
          f: false

        @attribHash.set values, (err, result) =>
          throw err if err?
          redisClient.hgetall @attribHash.key, (err, result) =>
            throw err if err?
            result.e.should.eql '1'
            result.f.should.eql '0'
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
            result.should.eql existentEncoded
            done()

    describe 'key/value pair syntax', () ->

      beforeEach (done) ->
        @attribHash.set 'foo', 'bar', (err, results) =>
          throw err if err?
          done()

      it "should persist values into Redis", (done) ->
        redisClient.hget @attribHash.key, 'foo', (err, result) =>
          throw err if err?
          result.should.eql 'bar'
          done()

      it 'should encode boolean true values', (done) ->
        @attribHash.set 'foo', true, (err, result) =>
          throw err if err?
          redisClient.hget @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            result.should.eql '1'
            done()

      it 'should encode boolean false values', (done) ->
        @attribHash.set 'foo', false, (err, result) =>
          throw err if err?
          redisClient.hget @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            result.should.eql '0'
            done()

      it 'should remove null values', (done) ->
        @attribHash.set 'foo', null, (err, result) =>
          throw err if err?
          redisClient.hexists @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            result.should.eql 0
            done()

      it 'should remove undefined values', (done) ->
        @attribHash.set 'foo', undefined, (err, result) =>
          throw err if err?
          redisClient.hexists @attribHash.key, 'foo', (err, result) =>
            throw err if err?
            result.should.eql 0
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
          result.should.eql @attribs
          done()

      it 'should return null if the hash is empty', (done) ->
        redisClient.hdel @attribHash.key, Object.keys(@attribs)..., (err, result) =>
          throw err if err?
          @attribHash.get (err, result) =>
            throw err if err?
            should.not.exist result
            done()

    describe 'get-value syntax', () ->

      beforeEach (done) ->
        @attribHash.set 'foo', 'bar', (err, result) ->
          throw err if err?
          done()

      it 'should correctly return the name value', (done) ->
        @attribHash.get 'foo', (err, result) =>
          throw err if err?
          result.should.eql 'bar'
          done()

      it "should return null for values that don't exist", (done) ->
        @attribHash.get 'foobar', (err, result) ->
          throw err if err?
          should.not.exist result
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
          result.should.eql 0
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
          result.should.eql 0
          done()

  describe 'flag attributes', () ->

    describe '#setFlag', () ->

      beforeEach (done) ->
        @attribHash.setFlag 'foo', true, (err, result) ->
          throw err if err?
          done()

      describe "true flags", () ->

        it "should persist '1' to Redis", (done) ->
          redisClient.hget @attribHash.key, 'foo', (err, result) ->
            throw err if err?
            result.should.eql '1'
            done()

      describe "false flags", () ->

        beforeEach (done) ->
          @attribHash.setFlag 'foo', false, (err, result) ->
            throw err if err?
            done()

        it "should persist '0' to redis", (done) ->
          redisClient.hget @attribHash.key, 'foo', (err, result) ->
            throw err if err?
            result.should.eql '0'
            done()

    describe '#getFlag', () ->

      beforeEach (done) ->
        @attribHash.setFlag 'foo', true, (err, result) =>
          throw err if err?
          @attribHash.setFlag 'bar', false, (err, result) ->
            throw err if err?
            done()

      it 'should return true for values set with #setFlag(true)', (done) ->
        @attribHash.getFlag 'foo', (err, result) ->
          throw err if err?
          result.should.eql true
          done()

      it 'should return false for values set with #setFlag(false)', (done) ->
        @attribHash.getFlag 'bar', (err, result) ->
          throw err if err?
          result.should.eql false
          done()

      it 'should return null for non-existent values', (done) ->
        @attribHash.getFlag 'foobar', (err, result) ->
          throw err if err?
          should.not.exist result
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
            result.should.eql (@attribs.foo + 1)
            @attribHash.get 'foo', (err, result) =>
              throw err if err?
              result.should.eql (@attribs.foo + 1).toString()
              done()

        it 'should treat non-existent values as zero', (done) ->
          @attribHash.inc 'foobar', (err, result) =>
            throw err if err?
            result.should.eql 1
            @attribHash.get 'foobar', (err, result) =>
              throw err if err?
              result.should.eql '1'
              done()

        it 'should raise errors on non-numeric values', (done) ->
          @attribHash.inc 'bar', (err, result) =>
            err.message.should.match /ERR hash value is not an integer/
            done()

      it 'should accept arbitrary positive increments', (done) ->
        @attribHash.inc 'foo', 5, (err, result) =>
          throw err if err?
          result.should.eql @attribs.foo + 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            result.should.eql (@attribs.foo + 5).toString()
            done()

      it 'should accept arbitrary negative increments', (done) ->
        @attribHash.inc 'foo', -5, (err, result) =>
          throw err if err?
          result.should.eql @attribs.foo - 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            result.should.eql (@attribs.foo - 5).toString()
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
            result.should.eql (@attribs.foo - 1)
            @attribHash.get 'foo', (err, result) =>
              throw err if err?
              result.should.eql (@attribs.foo - 1).toString()
              done()

        it 'should treat non-existent values as zero', (done) ->
          @attribHash.dec 'foobar', (err, result) =>
            throw err if err?
            result.should.eql -1
            @attribHash.get 'foobar', (err, result) =>
              throw err if err?
              result.should.eql '-1'
              done()

        it 'should raise errors on non-numeric values', (done) ->
          @attribHash.dec 'bar', (err, result) =>
            err.message.should.match /ERR hash value is not an integer/
            done()

      it 'should accept arbitrary positive decrements', (done) ->
        @attribHash.dec 'foo', 5, (err, result) =>
          throw err if err?
          result.should.eql @attribs.foo - 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            result.should.eql (@attribs.foo - 5).toString()
            done()

      it 'should accept arbitrary negative decrements', (done) ->
        @attribHash.dec 'foo', -5, (err, result) =>
          throw err if err?
          result.should.eql @attribs.foo + 5
          @attribHash.get 'foo', (err, result) =>
            throw err if err?
            result.should.eql (@attribs.foo + 5).toString()
            done()