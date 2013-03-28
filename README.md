# redis-hash-js

This module provides `RedisHash`, a class that adds some basic syntactic sugar around Redis hash commands like `HMGET`, `HMSET`, `HINCRBY`, among others. Supported operations include:

- Bulk setting and getting
- Boolean flags
- Counters

## Example

```js
redis = require('redis');
RedisHash = require('redis-hash-js');

hash = new RedisHash(redis.createClient(), 'hashKey');

hash.set('x', 'y');
hash.get('x', function(err, result) {
  console.log("x is " + result);
});

hash.set({
  a: '1',
  b: '2'
});

hash.get(function(err, result) {
  for (k in result) {
    console.log(k + ": " + result[k]);
  }
});
```

## Installation

    npm install redis-hash

## Class reference

#### constructor(redisClient, key)

#### set(subkey, value, [callback])
#### set(subkeysValues, [callback])

#### get([subkey], callback)

#### delete(subkey, [callback])

#### clear([callback])

#### setFlag(subkey, trueOrFalse, [callback])

#### getFlag(subkey, callback)

#### inc(subkey, [delta], [callback])

#### dec(subkey, [delta], [callback])