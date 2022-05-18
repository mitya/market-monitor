# Docs: https://core.telegram.org/bots/api#getme
#
# curl -s https://api.telegram.org/bot5390070120:AAHWFrEPERuip6AvPCsLjrJPlu-dq83Qsqc/getMe | jq
# curl -s https://api.telegram.org/bot5390070120:AAHWFrEPERuip6AvPCsLjrJPlu-dq83Qsqc/getUpdates | jq#
# curl -s 'https://api.telegram.org/bot5390070120:AAHWFrEPERuip6AvPCsLjrJPlu-dq83Qsqc/sendMessage?text=_Hello_&chat_id=72120729&parse_mode=MarkdownV2' | jq
#
# disable_notification
#
# To get the user id call 'getUpdates' once.
#
#
class TelegramGateway
  include StaticService

  API_BASE = "https://api.telegram.org/bot5390070120:AAHWFrEPERuip6AvPCsLjrJPlu-dq83Qsqc"
  MY_CHAT_ID = 72120729

  def push(text = "Hello")
    RestClient.post API_BASE + "/sendMessage", chat_id: 72120729, text: text, parse_mode: 'HTML'
  rescue
    puts "#{$!}: #{$!.response.body}".red
  end
end

__END__
