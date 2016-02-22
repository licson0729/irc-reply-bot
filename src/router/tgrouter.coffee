TextRouter = require './textrouter'
Telegram = require '../tgapi'
Senter = require '../senter.js'
{UTF8LengthSplit} = require '../util.js'

class TelegramRouter extends TextRouter
  constructor: (@token, @channelPostFix = 'tg', @userPostFix = 'tg', @requireTag = false)->
    super
    @nameMap = {}
    @_selfName = null
    @_init()
    @messageBuffer = {}
    @bufferTimeout = 1000
    @bufferTimeoutId = null
    
  _init: ()->
    console.log "initing telegram with token #{@token}"
    @api = new Telegram @token
    @api.startPolling 40
    @api.getMe (err, res)=>
      return @emit err if err
      @setSelfName res.username
      
      @api.on 'message', (message)=>
        
        # console.log(message)
        
        channelId = "#" + message.chat.id.toString()
        
        if message.from.username
          @nameMap[message.from.username] = message.from.id
          
        if @channelPostFix
          channelId += "@" + @channelPostFix
        userName = message.from.username
        userName = userName || "undefined_#{message.from.id}"
        if @userPostFix
          userName += "@" + @channelPostFix
        text = message.text
        return if not text
        
        clonedRouter = {}
        
        for key, value of @
          clonedRouter[key] = value
          if 'function' is typeof value
            if not value.toString().match /\[native code\]/
              clonedRouter.key = value.bind @
              
        message_id = message.message_id
        message_ = message
        clonedRouter.output = (message, to)=>
                
          channelName = "#" + message_.chat.id.toString()
          channelName += "@" + @channelPostFix if @channelPostFix
          @output message, to, message_id, channelName
        console.log (new Date).toISOString().replace(/T/, ' ').replace(/\..+/, '') + ' ' + userName + ' => ' + channelId + ': ' + text.replace /\r?\n/g, '\r\n   | '
        @input text, userName, channelId, [], clonedRouter
      
      @on 'output', (m, target, replyId)=>
        console.log (new Date).toISOString().replace(/T/, ' ').replace(/\..+/, '') + ' ' + @getSelfName() + ' => ' + target + ': ' + m.replace /\r?\n/g, '\r\n   | '
        target = target.replace /@.*$/, ''
        
        if target.match /^#/
          # a channel id
          target = target.replace /^#/, ''
          target = parseInt target, 10
        else if @nameMap[target]
          # a user name
          target = @nameMap[target]
        else
          return console.error "unknown username #{target}"
        
        
        if replyId
          @api.sendMessage target, m, null, {
            reply_to_message_id: replyId
          }
        else
          @api.sendMessage target, m
      
    @on 'whois', (nick, cb)->
      process.nextTick ()->
        cb {account: nick}
    
  disconnect: (msg, cb)->
    @client.disconnect msg, cb
  
  getRouterIdentifier : ()->
    return @_routerIndetifier or "tg"
  
  parseArgs: (cmd)->
    temp = cmd.replace /^\//, ''
    .split /\u0020/g
    temp[0] = temp[0].replace /@.*/, ''
    temp
    
  getIdentifier : ()-> '/'
  
  input : (message, from, to, channal, router)->
    sender = new Senter from, to, message, channal
    @emit "input", message, sender, router
  
  
  output : (message, to, message_id, originalChannel, nobuffer)->
    message_id_temp = message_id
    
    if originalChannel and to isnt originalChannel
      message_id_temp = undefined
    
    if Array.isArray message
      message = message.join "\r\n"
      
    if (not nobuffer) and @bufferTimeout > 0
      if Array.isArray to
        to.forEach (to)=>
          @messageBuffer[to + '\u0000' + message_id_temp] = @messageBuffer[to + '\u0000' + message_id_temp] || []
          @messageBuffer[to + '\u0000' + message_id_temp].push message
          @bufferTimeoutId = setTimeout (@flushOutput.bind @), @bufferTimeout if not @bufferTimeoutId
      else
        @messageBuffer[to + '\u0000' + message_id_temp] = @messageBuffer[to + '\u0000' + message_id_temp] || []
        @messageBuffer[to + '\u0000' + message_id_temp].push message
        @bufferTimeoutId = setTimeout (@flushOutput.bind @), @bufferTimeout if not @bufferTimeoutId
      return
    
    if ('string' == typeof to) || not to?
      @emit "output", message, to, message_id_temp
    else
      for person in to
        @emit "output", message, person, message_id_temp
  
  flushOutput: ()->
    @bufferTimeoutId = null
    for key, value of @messageBuffer
      channel = (key.split '\u0000')[0]
      id = (key.split '\u0000')[1]
      channelTemp = parseInt channel, 10
      channel = channelTemp || channel
      id = parseInt id, 10
      if isNaN id
        id = null
      
      value = value.join "\r\n"
      @output value, channel, id, null, true
    @messageBuffer = {}
  
  toDisplayName: (str)-> "@#{str.replace /@.*/, ''}"

  isCommand: (str, sender)->
    if not str.match /^\//
      return false
    
    temp = str.replace /^\//, ''
    .split /\u0020/g
    
    if @requireTag
      
      if sender.target.match /#[^-]/
        return true
      
      if not temp[0].match /@/
        return false
      else
        return true
    else
      true

module.exports = TelegramRouter