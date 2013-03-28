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
  # @param {String} the subkey of the attribute
  # @param {String} the value to set
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
  # 2. A single key
  # @param {String} the subkey of the attribute
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
  delete: (subkey, done) ->
    @redis.hdel @key, subkey, done

  # Clear the entire hash
  clear: (done) ->
    @redis.del @key, done

  # Set a boolean flag value in the hash
  setFlag: (subkey, trueOrFalse, done) ->
    @redis.hset @key, subkey, @_encode(trueOrFalse), done

  # Retrieve a boolean flag value from the hash
  getFlag: (subkey, done) ->
    @get subkey, (err, result) =>
      return done(err) if err
      done null, @_booleanDecode(result)

  # Increment a value in the hash
  inc: (subkey, args...) ->
    switch args.length
      when 1
        delta = 1
        done = args[0]
      when 2
        delta = args[0]
        done = args[1]
      else
        throw "Invalid argument count: #{args.length}"

    @redis.hincrby @key, subkey, delta, done

  # Decrement a value in the hash
  dec: (subkey, args...) ->
    switch args.length
      when 1
        delta = -1
        done = args[0]
      when 2
        delta = -args[0]
        done = args[1]
      else
        throw "Invalid argument count: #{args.length}"

    @redis.hincrby @key, subkey, delta, done

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