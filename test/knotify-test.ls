require! '../lib/knotify.ls': \KNotify
require! 'chai'
describe = require 'mocha' .describe
_it = require 'mocha' .it
assert = chai.assert
expect = chai.expect

class ConnectionMock
  (@callback = ->) ->
  send-text: (text) ->
    @callback text
    text

describe 'knotify' ->

  _it 'should do token exchanges', ->
    mock = new ConnectionMock
    knotify = new KNotify mock
    test = knotify.send "abc", true, \TEST, "this is a test"
    expect test .to.equal '{"token":"abc","success":true,"status":"TEST","reason":"this is a test"}'
    knotify.close!

  _it 'should get a redis message', (done) ->
    mock = new ConnectionMock (message) ->
      expect message .to.equal "test"
      knotify.close!
      redis.quit!
      done!
    knotify = new KNotify mock
    redis = knotify.connect!
    knotify.subscribe "user--1"
    redis.publish "user--1", "test"

  _it 'should store auth', ->
    mock = new ConnectionMock
    knotify = new KNotify mock
    expect knotify.auth .to.not.exist
    knotify.store-auth "foo", "bar"
    expect knotify.auth .to.exist
    knotify.close!

  _it 'should purge auth', ->
    mock = new ConnectionMock
    knotify = new KNotify mock
    knotify.store-auth "foo", "bar"
    expect knotify.auth .to.exist
    knotify.purge-auth!
    expect knotify.auth .to.not.exist
    knotify.close!

  _it 'should return a valid auth channel', ->
    mock = new ConnectionMock
    knotify = new KNotify mock
    knotify.store-auth "foo", "bar"
    expect knotify.auth .to.exist
    expect knotify.auth-channel! .to.equal "notifications-foo-bar"
    knotify.close!

  void
