class InstrumentsController < ApplicationController
  def root
    redirect_to instruments_path
  end

  def index
    @instruments = Instrument.tinkoff.abc.limit(100)
  end
end
