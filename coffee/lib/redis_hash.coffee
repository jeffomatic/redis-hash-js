class RedisHash

  @isFalsy: (v) ->
    (v == false) || !(v?)

  constructor: (@redis, @key) ->

  # Two ways of calling this method:
  #
  # 1. A key/value hash. Nil, false, and undefined values will be treated as
  #    deletions.
  # @param {Object} a hash of keys/values
  # @param {Function} a completion callback
  #
  # 2. A singe key-value pair
  # @param {String} the field to modify
  # @param {String} the field's new value
  # @param {Function} a completion callback
  set: (args...) ->
    switch args.length
      when 2
        @_hashSet args...
      when 3
        @_pairSet args...
      else
        throw "Invalid number of arguments: #{args.length}"

  _hashSet: (keysValues, done) ->
    # Build list of arguments to HMSET and HDEL
    hmsetArgs = [ @key ]
    hdelArgs = [ @key ]

    # Add keys and values in series
    for k, v of keysValues
      if v?
        hmsetArgs.push k
        hmsetArgs.push @_encode(v)
      else
        hdelArgs.push k

    if hmsetArgs.length > 1 && hdelArgs.length > 1
      # Run HMSET, then HDEL
      hmsetArgs.push (err, results) =>
        if err?
          done err
        else
          hdelArgs.push done
          @redis.hdel hdelArgs...
      @redis.hmset hmsetArgs...
    else if hmsetArgs.length > 1
      hmsetArgs.push done
      @redis.hmset hmsetArgs...
    else if hdelArgs.length > 1
      hdelArgs.push done
      @redis.hdel hdelArgs...
    else
      process.nextTick done

  _pairSet: (k, v, done) ->
    if v?
      @redis.hset @key, k, @_encode(v), done
    else
      @redis.hdel @key, k, done

  # Two ways of calling this method:
  #
  # 1. Callback only. Returns the entire attribute hash.
  # @param {Function} a completion callback
  #
  # 2. A single field
  # @param {String} the field to retrieve
  # @param {Function} a completion callback
  get: (args...) ->
    switch args.length
      when 1
        @redis.hgetall @key, args[0]
      when 2
        @redis.hget @key, args[0], args[1]
      else
        throw "Invalid number of arguments: #{args.length}"

  # Delete a single value from the hash
  delete: (field, done) ->
    @redis.hdel @key, field, done

  # Clear the entire hash
  clear: (done) ->
    @redis.del @key, done

  # Set a boolean flag value in the hash
  setFlag: (field, trueOrFalse, done) ->
    @redis.hset @key, field, @_encode(trueOrFalse), done

  # Retrieve a boolean flag value from the hash
  getFlag: (field, done) ->
    @get field, (err, result) =>
      return done(err) if err
      done null, @_booleanDecode(result)

  # Retrieve a list of flags from the hash
  getFlags: (fields..., done) ->
    fields = fields[0] if Array.isArray(fields[0])
    @redis.hmget @key, fields..., (err, values) =>
      return done(err) if err
      result = {}
      result[field] = @_booleanDecode(values[i]) for field, i in fields
      done null, result

  # Increment a value in the hash
  inc: (field, args...) ->
    switch args.length
      when 1
        delta = 1
        done = args[0]
      when 2
        delta = args[0]
        done = args[1]
      else
        throw "Invalid argument count: #{args.length}"

    @redis.hincrby @key, field, delta, done

  # Decrement a value in the hash
  dec: (field, args...) ->
    switch args.length
      when 1
        delta = -1
        done = args[0]
      when 2
        delta = -args[0]
        done = args[1]
      else
        throw "Invalid argument count: #{args.length}"

    @redis.hincrby @key, field, delta, done

  _encode: (trueOrFalse) ->
    if trueOrFalse == true
      '1'
    else if trueOrFalse == false
      '0'
    else if trueOrFalse?
      trueOrFalse.toString()
    else
      trueOrFalse

  _booleanDecode: (value) ->
    switch value
      when '1' then true
      when '0' then false
      else null

module.exports = RedisHash