class MarketInfo
  Moex1 = %w[AFKS AFLT ALRS CBOM CHMF CIAN DSKY ENPG FIVE FIXP GAZP GLTR HYDR IRAO LKOH MAGN MGNT MOEX MTSS NLMK NVTK OZON 
             PHOR PIKK PLZL POLY QIWI ROSN RSTI RUAL SBER SBERP SNGSP TATN TATNP TCSG VEON-RX VKCO VTBR YNDX].to_set
  Moex2 = %w[ABRD AGRO AKRN AMEZ APTK AQUA BANE BANEP BELU BLNG BSPB CHMK CNTL CNTLP DASB DVEC ENRU ETLN FEES FESH FLOT GCHE
             GEMC GMKN GRNT GTRK IRGZ IRKT ISKJ KAZT KAZTP KLSB KMAZ KRKNP KROT KZOS KZOSP LENT LIFE LNTA LNZL LNZLP LSNG 
             LSNGP LSRG MDMG MGTSP MRKC MRKP MRKS MRKU MRKV MRKY MRKZ MSNG MSRS MSST MSTT MTLR MTLRP MVID NKHP NKNC NKNCP
             NMTP NSVZ OGKB OKEY ORUP PMSB PMSBP POGR POSI PRFN RASP RBCM RENI RKKE RNFT ROLO RSTIP RTKM RTKMP RUGR SELG
             SFIN SFTL SGZH SIBN SMLT SNGS SVAV TGKA TGKB TGKBP TGKD TGKDP TGKN TORS TRMK TRNFP TTLK UNAC UNKL UPRO UWGN VRSB VSMO YAKG].to_set

  MoexIlliquid = %w[ENRU TGKDP FESH GCHE MRKP MSST BANE NMTP SELG MSNG ABRD KMAZ SVAV UWGN RENI UNAC POSI KAZT GRNT MRKC YAKG NKNC
                IRGZ LENT ROLO RSTIP LNZL LNZLP CNTLP CNTL KRKNP TGKB PMSB SFIN KAZTP LSNG MRKY TGKN MSRS BLNG GTRK KZOS NSVZ
                VRSB MGTSP PRFN DVEC MRKV TORS OKEY MRKZ KLSB IRKT TGKBP MSTT MRKS RBCM MRKU CHMK PMSBP RUGR KROT RKKE NKHP UNKL].to_set
  
  OpeningTimes = { US: '09:30', Moex1: '07:00', Moex2: '10:00' }
  ClosingTimes = { US: '16:00', Moex1: '23:50', Moex2: '18:45' }
  OpeningHourMins = OpeningTimes.transform_values { |hhmm| h, m = hhmm.split(':').map(&:to_i); { hour: h, min: m } }
  ClosingHourMins = ClosingTimes.transform_values { |hhmm| h, m = hhmm.split(':').map(&:to_i); { hour: h, min: m } }
  
  class << self
    def us_tickers = @us_tickers ||= Instrument.usd.pluck(:ticker).to_set
      
    def ticker_source_for(ticker) 
      case ticker 
        when us_tickers then :US
        when Moex1      then :Moex1
        when Moex2      then :Moex2      
      end        
    end
    
    def ticker_opening_time(ticker)     = OpeningTimes[ticker_source_for ticker]
    def ticker_closing_time(ticker)     = ClosingTimes[ticker_source_for ticker]
    def ticker_opening_hour_min(ticker) = OpeningHourMins[ticker_source_for ticker]
    def ticker_closing_hour_min(ticker) = ClosingHourMins[ticker_source_for ticker]
  end 
end
