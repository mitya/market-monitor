class InstrumentsController < ApplicationController
  def index
    @instruments = Instrument.tinkoff.abc.limit(100)
  end
end
