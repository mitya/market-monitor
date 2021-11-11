class SyncChannel < ApplicationCable::Channel
  def subscribed
    stream_from "updates"
  end

  def unsubscribed
  end

  class << self
    def push(reason = 'updated')
      ActionCable.server.broadcast 'updates', { reason: reason }
    end
  end
end

__END__
SyncChannel.push 'prices'
