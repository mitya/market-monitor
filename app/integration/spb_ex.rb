require 'csv'

# Source
# https://spbexchange.ru/ru/listing/securities/list/
# iconv -f CP1251 -t UTF8 db/data/spbex.csv > db/data/spbex-utf.csv
class SpbEx
  include StaticService

  # Row;s_level_name;e_full_name;e_INN_code;s_sec_type_name_dop;s_sec_form_name_full;s_RTS_code;s_ISIN_code;si_gos_reg_num;si_gos_reg_date;
  #    s_face_value;s_face_value_currency;s_quot_list_in_date;s_segment;s_date_defolt;s_date_technic_defolt
  def load_spb_instruments
    spb_types = { 'Акции' => 'Stock', 'Депозитарные расписки' => 'GDR' }

    CSV.read("db/data/spbex-utf.csv", headers: true, col_sep: ';', quote_char: nil).each do |row|
      row['e_full_name']
      row['s_RTS_code']
      row['s_ISIN_code']
      row['s_sec_type_name_dop'] # Акции 'Депозитарные расписки'
      row['s_face_value_currency'] # USD EUR RUB

      next if row['s_sec_type_name_dop'] != 'Акции'
      next if row['s_face_value_currency'] == 'RUB'
      next if Instrument.exists? ticker: row['s_RTS_code']

      puts "Adding #{row['s_RTS_code']} (#{row['e_full_name']})"

      Instrument.create!(
        ticker: row['s_RTS_code'],
        name: row['e_full_name'],
        isin: row['s_ISIN_code'],
        currency: row['s_face_value_currency'],
        type: spb_types[row['s_sec_type_name_dop']],
        flags: ['spb'],
      )
    end
  end
end

__END__

Instrument.delete_all
rr 'InstrumentLoader.load_tinkoff_instruments'
rr 'InstrumentLoader.load_spb_instruments'
Candle.where(figi: Instrument.find_by(ticker: 'AAPL').figi).where(Candle.arel_table[:time].gteq 1.day.ago.midnight).exists?
