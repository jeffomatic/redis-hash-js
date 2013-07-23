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

#### constructor(redisClient, key, opts)

  - **opts**
    - **emitErrs** (*true*) Redis errors will be emitted as `error` events

#### set(field, value, [callback])
#### set(fieldsValues, [callback])

#### get([field], callback)

#### delete(field, [callback])

#### clear([callback])

#### getFlag(field, callback)
#### getFlags(fields, callback)

#### inc(field, [delta], [callback])
#### dec(field, [delta], [callback])