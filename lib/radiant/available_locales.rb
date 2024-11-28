module Radiant::AvailableLocales

  # Returns the list of available locale files in options_for_select format.
  #
  def self.locales
    locales = I18n.available_locales.map do | symbol |
      [
        I18n::Language::Mapping.language_mapping_list().dig(symbol.to_s, 'nativeName') || symbol.to_s,
        symbol
      ]
    end

    locales.sort_by { | pair | pair[0] }
  end

end
