require "test_helper"

class InstrumentTest < ActiveSupport::TestCase
  attr :instrument

  setup do
    @instrument = Instrument.create! ticker: 'TEST', isin: 'US0000TEST', name: 'Test', currency: 'USD'
  end

  test "price selectors" do
    instrument.day_candles.create! date: '2021-01-04',           time: '2021-01-04', open: 100, high: 110, low:  90, close:  95, volume: 1_000

    instrument.day_candles.create! date: Current.yesterday, time: Current.yesterday, open: 190, high: 195, low: 175, close: 185, volume: 1_000
    instrument.day_candles.create! date: Current.today,         time: Current.today, open: 195, high: 200, low: 180, close: 190, volume: 1_000

    assert_equal 195, instrument.today_open
    assert_equal 200, instrument.today_high
    assert_equal 180, instrument.today_low
    assert_equal 190, instrument.today_close

    assert_equal 190, instrument.yesterday_open
    assert_equal 195, instrument.yesterday_high
    assert_equal 175, instrument.yesterday_low
    assert_equal 185, instrument.yesterday_close

    assert_equal 100, instrument.jan04_open
    assert_equal 110, instrument.jan04_high
    assert_equal  90, instrument.jan04_low
    assert_equal  95, instrument.jan04_close

    assert_equal   95, instrument.jan04_open_diff(:today_open)
    assert_equal 0.95, instrument.jan04_open_rel(:today_open)

    assert_equal   95, instrument.diff(:jan04_open, :today_open)
    assert_equal 0.95, instrument.rel_diff(:jan04_open, :today_open)
  end
end
