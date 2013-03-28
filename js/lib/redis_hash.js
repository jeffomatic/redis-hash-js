// Generated by CoffeeScript 1.6.2
(function() {
  var RedisHash,
    __slice = [].slice;

  RedisHash = (function() {
    RedisHash.isFalsy = function(v) {
      return (v === false) || !(v != null);
    };

    function RedisHash(redis, key) {
      this.redis = redis;
      this.key = key;
    }

    RedisHash.prototype.set = function() {
      var args;

      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      switch (args.length) {
        case 2:
          return this._hashSet.apply(this, args);
        case 3:
          return this._pairSet.apply(this, args);
        default:
          throw "Invalid number of arguments: " + args.length;
      }
    };

    RedisHash.prototype._hashSet = function(keysValues, done) {
      var hdelArgs, hmsetArgs, k, v, _ref, _ref1, _ref2,
        _this = this;

      hmsetArgs = [this.key];
      hdelArgs = [this.key];
      for (k in keysValues) {
        v = keysValues[k];
        if (v != null) {
          hmsetArgs.push(k);
          hmsetArgs.push(this._encode(v));
        } else {
          hdelArgs.push(k);
        }
      }
      if (hmsetArgs.length > 1 && hdelArgs.length > 1) {
        hmsetArgs.push(function(err, results) {
          var _ref;

          if (err != null) {
            return done(err);
          } else {
            hdelArgs.push(done);
            return (_ref = _this.redis).hdel.apply(_ref, hdelArgs);
          }
        });
        return (_ref = this.redis).hmset.apply(_ref, hmsetArgs);
      } else if (hmsetArgs.length > 1) {
        hmsetArgs.push(done);
        return (_ref1 = this.redis).hmset.apply(_ref1, hmsetArgs);
      } else if (hdelArgs.length > 1) {
        hdelArgs.push(done);
        return (_ref2 = this.redis).hdel.apply(_ref2, hdelArgs);
      } else {
        return process.nextTick(done);
      }
    };

    RedisHash.prototype._pairSet = function(k, v, done) {
      if (v != null) {
        return this.redis.hset(this.key, k, this._encode(v), done);
      } else {
        return this.redis.hdel(this.key, k, done);
      }
    };

    RedisHash.prototype.get = function() {
      var args;

      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      switch (args.length) {
        case 1:
          return this.redis.hgetall(this.key, args[0]);
        case 2:
          return this.redis.hget(this.key, args[0], args[1]);
        default:
          throw "Invalid number of arguments: " + args.length;
      }
    };

    RedisHash.prototype["delete"] = function(subkey, done) {
      return this.redis.hdel(this.key, subkey, done);
    };

    RedisHash.prototype.clear = function(done) {
      return this.redis.del(this.key, done);
    };

    RedisHash.prototype.setFlag = function(subkey, trueOrFalse, done) {
      return this.redis.hset(this.key, subkey, this._encode(trueOrFalse), done);
    };

    RedisHash.prototype.getFlag = function(subkey, done) {
      var _this = this;

      return this.get(subkey, function(err, result) {
        if (err) {
          return done(err);
        }
        return done(null, _this._booleanDecode(result));
      });
    };

    RedisHash.prototype.inc = function() {
      var args, delta, done, subkey;

      subkey = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      switch (args.length) {
        case 1:
          delta = 1;
          done = args[0];
          break;
        case 2:
          delta = args[0];
          done = args[1];
          break;
        default:
          throw "Invalid argument count: " + args.length;
      }
      return this.redis.hincrby(this.key, subkey, delta, done);
    };

    RedisHash.prototype.dec = function() {
      var args, delta, done, subkey;

      subkey = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      switch (args.length) {
        case 1:
          delta = -1;
          done = args[0];
          break;
        case 2:
          delta = -args[0];
          done = args[1];
          break;
        default:
          throw "Invalid argument count: " + args.length;
      }
      return this.redis.hincrby(this.key, subkey, delta, done);
    };

    RedisHash.prototype._encode = function(trueOrFalse) {
      if (trueOrFalse === true) {
        return '1';
      } else if (trueOrFalse === false) {
        return '0';
      } else if (trueOrFalse != null) {
        return trueOrFalse.toString();
      } else {
        return trueOrFalse;
      }
    };

    RedisHash.prototype._booleanDecode = function(value) {
      switch (value) {
        case '1':
          return true;
        case '0':
          return false;
        default:
          return null;
      }
    };

    return RedisHash;

  })();

  module.exports = RedisHash;

}).call(this);
