
bhs                   = require 'keybase-http-server'
{Handler,GET,POST}    = bhs.base
{api_route}           = require '../lib/urls'
challenge             = require '../lib/challenge'
mm                    = bhs.mod.mgr
{checkers}            = require 'keybase-bjson-core'
{make_esc}            = require 'iced-error'
idcheckers            = require('keybase-messenger-core').id.checkers

#=============================================================================

class GetSessionChallengeHandler extends Handler

  params : () ->
    out = {}
    out[k] = v for k,v of mm.config.security.challenge
    out.less_than = new Buffer out.less_than, 'hex'
    return out

  _handle : (cb) ->
    await challenge.generate defer err, token
    unless err?
      cfg = mm.config.security.challenge
      @pub { 
        challenge : { 
          token : token,
          params : @params()
        }
      }
    cb err

#=============================================================================

class SessionInitHandler extends Handler

  input_template : -> {
    challenge : {
      token : [ checkers.value(1), idcheckers.sct ]
      solution : checkers.buffer(1)
    }
  }

  #-------------------------

  _handle : (cb) ->
    esc = make_esc cb, "SessionInitHandler::_handle"
    await challenge.check @input.challenge, esc defer token
    @pub { session_id : token.id }
    cb null

#=============================================================================

exports.bind_to_app = (app) ->
  GetSessionChallengeHandler.bind app, api_route("session/challenge"), GET
  SessionInitHandler.bind         app, api_route("session/init"), POST

#=============================================================================

