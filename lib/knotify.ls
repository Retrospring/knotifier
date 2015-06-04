require! \redis
require! './env'
module.exports = class KNotify
  (@connection) ->
    @client = @connect!
    @client.on \message, (channel, message) ~>
      if env.debug
        console.log "redis  >>>>", channel, message
      try
        @connection.send message
      catch
        unless env.quiet
          console.error e.message
          console.error e.stack.join \\n
    @auth = void
  connect: ->
    redis.create-client env.redis.port, env.redis.hostname
  subscribe: (channel) ->
    @client.subscribe channel
  unsubscribe: (channel) ->
    @client.unsubscribe channel
  store-auth: (key, id) ->
    @auth = {key: key, id: id}
  purge-auth: ->
    @auth = void
  auth-channel: ->
    return void unless @auth?
    "notifications-#{@auth.key}-#{@auth.id}"
  send: (token, success, status, reason) ->
    json = JSON.stringify do
      token:   token   or ""
      success: success or false
      status:  status  or "UNEXPECTED"
      reason:  reason  or "No reason given"
    if env.debug
      console.log "websock>>>>", json
    try
      @connection.send json
    catch
      unless env.quiet
        console.error e.message
        console.error e.stack.join \\n
  close: ->
    @client.quit!
