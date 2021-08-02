module ArbitragesHelper

  ARB_EXCHANGE_CODES = { N: 'NASDAQ', F: 'XFRA', T: 'Tradegate', U: 'US'}
  ARB_EXCHANGE_FLAGS = { N: 'usa', F: 'deu', T: 'deu', U: 'usa'}

  def arb_exchange_code(code)
    ARB_EXCHANGE_CODES[code.to_s.to_sym]
  end

  def arb_exchange_flag(code)
    country_flag_icon ARB_EXCHANGE_FLAGS[code.to_s.to_sym]
  end
end
