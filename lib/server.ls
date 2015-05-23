require! './env'
require! 'nodejs-websocket': \ws
require! './knotify': \KNotify

server = ws.create-server (connection) ->
  knotify = new KNotify connection
  
  connection.on \text, (string) ->
    if env.debug
      console.log "<<<<websock", string
    try
      json = JSON.parse string
      return unless json.method?
      switch json.method.to-lower-case!
        case \auth
          return knotify.send json.token, false, \PARAM_ERROR, "needs auth data" unless json.key? and json.id?
          knotify.store-auth json.key, json.id
          knotify.subscribe knotify.auth-channel!
          knotify.send json.token, true, \BOUND, "bound to #{knotify.auth-channel!}"
        case \subscribe
          return knotify.send json.token, false, \PARAM_ERROR, "needs id" unless json.id?
          knotify.subscribe "user-#{json.id}"
          knotify.send json.token, true, \BOUND, "bound to user-#{json.id}"
        case \logout
          return knotify.send json.token, false, \TRESPASSING, "auth first" unless knotify.auth?
          knotify.unsubscribe knotify.auth-channel!
          knotify.purge-auth!
          knotify.send json.token, true, \BYE, "bye"
        case \unsubscribe
          return knotify.send json.token, false, \PARAM_ERROR, "needs id" unless json.id?
          knotify.unsubscribe "user-#{json.id}"
          knotify.send json.tokem true, \UNSUBSCRIBED, "unsubscribed from user-#{json.id}"
    catch e
      unless env.quiet
        console.error e.message
        console.error e.stack.join \\n

  connection.on \close, (code, reason) ->
    unless env.quiet
      console.log connection, "closed", code, reason
    knotify.close!

  connection.on \error, ->
    unless env.quiet
      console.log connection, "errored", arguments
    knotify.close!

server.listen env.ws.port, env.ws.hostname

process.on \uncaughtException, (error) ->
  return void if env.quiet
  console.error "uncaughtException:", error.message
  console.error error.stack.join \\n
