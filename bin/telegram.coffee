process = require 'process'
path = require 'path'
MTProto = require '@mtproto/core'

api = new MTProto(
  api_id: '7106194',
  api_hash: '19be0989ec8f7b070a30495fbb6673c7',
  storageOptions: { path: path.resolve(__dirname, './config/telegram.json') },
)

commandArguments = process.argv.slice(2)
[command, channelCode, ...] = commandArguments

channelIds = {
  US:   { id: 1490544969, access_hash: '4807356510742790131' },
  TG:   { id: 1219736125, access_hash: '8462398626162394157' },
  XFRA: { id: 1483214782, access_hash: '5419462402634631275' },
  NSDQ: { id: 1273412762, access_hash: '6877101497188606477' },
  NEWS: { id: 1205911857, access_hash: '1091215937709403298' },
}

do ->
  try
    # result = await api.call('messages.getAllChats', except_ids: []) # WORKS - gets all channel ids / access hashes
    # result = await api.call('messages.getFullChat', chat_id: 377702731) # WORKS
    # result = await api.call('messages.getChats', id: [377702731]) # WORKS
    # result = await api.call('messages.getHistory', peer: { chat_id: 377702731, _: 'inputPeerChat' }) # WORKS
    # result = await api.call('contacts.getContacts', hash: 0)
    # result = await api.call('help.getNearestDc')
    # result = await api.call 'auth.sendCode', phone_number: '79214261515', settings: { _: 'codeSettings' } # WORKS
    # result = await api.call 'auth.signIn', phone_number: '79214261515', phone_code: '79461', phone_code_hash: 'ecc1c89c571798015d' # WORKS
    # result = await api.call 'users.getFullUser', id: { _: 'inputUserSelf' } # WORKS

    switch command
      when 'allChats'
        result = await api.call('messages.getAllChats', except_ids: [])
        console.log result
      when 'messages'
        channel_id  = channelIds[channelCode]?.id
        access_hash = channelIds[channelCode]?.access_hash
        return console.warn "Bad channel code: #{channelCode}" unless channel_id
        response = await api.call 'messages.getHistory', peer: { channel_id, access_hash, _: 'inputPeerChannel' }, limit: 100 # WORKS min_id: 144730

        results = for message in response.messages
          id: message.id
          text: message.message
          date: message.date
          url: message.media?.webpage?.url

        # console.log results
        console.log JSON.stringify results

      when 'last-message'
        channel_id  = channelIds[channelCode]?.id
        access_hash = channelIds[channelCode]?.access_hash
        return console.warn "Bad channel code: #{channelCode}" unless channel_id
        result = await api.call 'messages.getHistory', peer: { channel_id, access_hash, _: 'inputPeerChannel' } # WORKS
        text = result.messages[1].message
        console.log(text)

    process.exit()
  catch err
    console.warn "ERROR"
    console.warn err

  # dialogs = await api.call('messages.getDialogs', limit: 50)

# phone_hash ecc1c89c571798015d phone_code 79461
# access_hash 9463499563469815876

# coffee bin/telegram.coffee messages NEWS
