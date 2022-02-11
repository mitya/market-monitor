module Const
  CurrencySigns = { USD: '$', RUB: '₽', EUR: '€', CNY: '¥', GBP: '£' }
  CurrencySignsUsed = { USD: '$', RUB: '₽', EUR: '€' }  
  
  SectorCodeTitles = {
    "commercialservices"    => ["Commercial",         'primary'],
    "communications"        => ["Communications"],
    "consumerdurables"      => ["Consumer Durables"],
    "consumernon-durables"  => ["Consumer Non-durables"],
    "consumerservices"      => ["Consumer Services"],
    "distributionservices"  => ["Distribution"],
    "electronictechnology"  => ["Electronics",        'warning'],
    "energyminerals"        => ["Energy",             'success'],
    "finance"               => ["Finance",            'dark'],
    "healthservices"        => ["Health Services",    'danger'],
    "healthtechnology"      => ["Biotech",            'danger'],
    "industrialservices"    => ["Industrial",         'success'],
    "miscellaneous"         => ["Misc"],
    "n/a"                   => ["N/A"],
    "non-energyminerals"    => ["Minerals",           'success'],
    "processindustries"     => ["Process Industries", 'success'],
    "producermanufacturing" => ["Manufactoring"],
    "retailtrade"           => ["Retail",             'primary'],
    "technologyservices"    => ["Technology",         'warning'],
    "transportation"        => ["Transportation"],
    "utilities"             => ["Utilities"],
  }

  SectorCodeOptions = SectorCodeTitles.transform_values { |val| val.first }.invert    
end