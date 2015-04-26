#!/usr/bin/env coffee
redis     = require 'redis'
ws        = require 'nodejs-websocket'

KNOTIFIER_DEFAULT_PORT = 34569
KNOTIFIER_DEFAULT_HOST = '127.0.0.1'

port        = process.env.KNOTIFIER_PORT || KNOTIFIER_DEFAULT_PORT
hostname    = process.env.KNOTIFIER_HOST || KNOTIFIER_DEFAULT_HOST

class KNotify
  constructor: (@conn) ->
    @client = redis.createClient()
    @client.on "message", (chan, message) ->
      @conn.sendText JSON.stringify {channel: chan, data: JSON.parse message}
    @key = undefined
  subscribe: (channel) ->
    @client.subscribe channel
  unsubscribe: (channel) ->
    @client.unsubscribe channel
  storeAuth: (key, id) ->
    @auth = {key: key, id: id}
  close: ->
    @client.quit()

server = ws.createServer (conn) ->
  knotify = new KNotify conn
  conn.on "text", (str) ->
    try
      json = JSON.parse str
      switch json.method
        when "auth" then
          knotify.key = "notifications.#{json.key}-#{json.id}"
          knotify.subscribe knotify.key
          conn.sendText JSON.stringify {success: true, reason: "bound to notificatoins", status: "BOUND"}
        when "subscribe" then
          knotify.subscribe "user.#{json.id}"
          conn.sendText JSON.stringify {success: true, reason: "bound to target", status: "BOUND"}
        when "logout" then
          if knotify.key === undefined
            conn.sendText JSON.stringify {success: false, reason: "login first", status: "NEEDS_AUTH"}
          else
            knotify.unsubscribe knotify.key
            conn.sendText JSON.stringify {success: true, reason: "bye", status: "BYE"}
        when "unsubscribe" then
          knotify.unsubscribe "user.#{json.id}"
          conn.sendText JSON.stringify {success: true, reason: "unbound target", status: "UNBOUND"}
    catch e
      # whoops

  conn.on "close", (code, reason) ->
    knotify.close

server.listen port, hostname

# client side
# var socket = new WebSocket "ws://#{port}:#{hostname}"
# socket.onmessage = (event) ->
#   data = JSON.parse event
#   # process data, pipe it to an eventmachine, whatever.
# socket.onopen = (event) ->
#   socket.send JSON.stringify {method: "subscribe", id: viewing_user_id}
#   if user_logged_in?
#     socket.send JSON.stringify {method: "subscribe", id: current_user.id, key: current_user.websocket.key}
