require 'pp'
require 'nokogiri'
require 'open-uri'

class Immo24Calculator

  # https://de.wikipedia.org/wiki/Solidarit%C3%A4tszuschlag
  TAXING = {
    'notar' => 1.5,
    'registration_fee' => 1,
    'Solidaritätszuschlag' => 5.5
  }

  # https://de.wikipedia.org/wiki/Grunderwerbsteuer_(Deutschland)
  LAND_TAX = {
    'Baden-Württemberg'      => 5,
    'Bayern'                 => 3.5,
    'Berlin'                 => 6,
    'Brandenburg'            => 6.5,
    'Bremen'                 => 5,
    'Hamburg'                => 4.5,
    'Hessen'                 => 6,
    'Mecklenburg-Vorpommern' => 5,
    'Niedersachsen'          => 4.5,
    'Nordrhein-Westfalen'    => 6.5,
    'Rheinland-Pfalz'        => 5,
    'Saarland'               => 6.5,
    'Sachsen'                => 3.5,
    'Sachsen-Anhalt'         => 4.5,
    'Schleswig-Holstein'     => 6.5,
    'Thüringen'              => 5
  }

  def self.calc(immo24_id)
    page = Nokogiri::HTML(open("https://www.immobilienscout24.de/expose/#{immo24_id}"))

    apt = {
      price: page.css('.is24qa-kaufpreis').text.strip.gsub('.','').to_f,
      provision: page.css('.is24qa-provision').text.strip.split.map{ |x| x.gsub(',','.').to_f }.find{ |x| x > 0 } || 0,
      rooms: page.css('.is24qa-zimmer').text.strip,
      district: page.css('.breadcrumb__link.margin-horizontal-xs').last.text.strip,
      sqm: page.css('.is24qa-wohnflaeche-ca').first.text.strip.gsub(',','.').to_f,
      liability: page.css('.is24qa-hausgeld').text.to_f,
      monthly_rental_income: page.css('.is24qa-mieteinnahmen-pro-monat').text.to_f,
      city: page.css('#is24-main > div.font-s.margin-vertical-s.padding-vertical-s.border-bottom.flex.flex--wrap.flex--space-between > div.palm--flex__order--1.flex-item--center.palm-hide > a:nth-child(3)').text,
      region: page.css('#is24-main > div.font-s.margin-vertical-s.padding-vertical-s.border-bottom.flex.flex--wrap.flex--space-between > div.palm--flex__order--1.flex-item--center.palm-hide > a:nth-child(4)').text,
      land: page.css('#is24-main > div.font-s.margin-vertical-s.padding-vertical-s.border-bottom.flex.flex--wrap.flex--space-between > div.palm--flex__order--1.flex-item--center.palm-hide > a:nth-child(2)').text,
    }

    apt[:price_per_sqm] = apt[:price] / apt[:sqm]

    # When Hausgeld or Mieteinnahme is specified as "1.005 €" it means 1005 €, not 1 €
    if apt[:liability] < 10 && apt[:liability] != 0
      apt[:liability] = apt[:liability].to_s.gsub('.','').to_f / 12 # it is probably in a fucking year
    end

    apt[:monthly_profit] = apt[:monthly_rental_income] - apt[:liability]
    apt[:total_tax] = 1 + (TAXING.values.reduce(:+) + apt[:provision] + LAND_TAX[apt[:land]]) / 100

    apt[:roi] = apt[:monthly_profit] * 12 / apt[:price] * 100
    apt[:full_price] = apt[:price] * apt[:total_tax]
    apt[:full_roi] = apt[:monthly_profit] * 12 / apt[:full_price] * 100

    apt.each do |k, v|
      puts "#{k}: #{v}"
    end
  end
end

Immo24Calculator.calc(ARGV[0])
