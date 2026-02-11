class CountryCurrencyInference
  COUNTRY_TO_CURRENCY = {
    'US' => 'USD',
    'GB' => 'GBP',
    'IE' => 'EUR',
    'DE' => 'EUR',
    'FR' => 'EUR',
    'ES' => 'EUR',
    'IT' => 'EUR',
    'NL' => 'EUR',
    'BE' => 'EUR',
    'AT' => 'EUR',
    'PT' => 'EUR',
    'GR' => 'EUR',
    'FI' => 'EUR',
    'EE' => 'EUR',
    'LV' => 'EUR',
    'LT' => 'EUR',
    'LU' => 'EUR',
    'MT' => 'EUR',
    'CY' => 'EUR',
    'SI' => 'EUR',
    'SK' => 'EUR',

    'CH' => 'CHF',
    'SE' => 'SEK',
    'NO' => 'NOK',
    'DK' => 'DKK',

    'CA' => 'CAD',
    'AU' => 'AUD',
    'NZ' => 'NZD',
    'JP' => 'JPY',
    'CN' => 'CNY',
    'IN' => 'INR',
    'SG' => 'SGD',
    'KR' => 'KRW',

    'HU' => 'HUF',
    'PL' => 'PLN',
    'CZ' => 'CZK',
    'RO' => 'RON',
    'BG' => 'BGN',
    'HR' => 'EUR',
  }.freeze

  def infer(country_code)
    code = country_code.to_s.strip.upcase
    return nil if code.blank?

    COUNTRY_TO_CURRENCY[code]
  end
end
