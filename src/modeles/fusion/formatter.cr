# SPDX-License-Identifier: AGPL-3.0-or-later

module Modeles
  module Fusion
    # Présentation des montants, quantités, taux et dates dans la langue du
    # document (ADR-010 D2), avec les conventions du PDF légal de la
    # Facturation (`Partiduo::LocaleFormats`, D-MOD-022) : `1 234,56` (fr,
    # pt), `1,234.56` (en), `1.234,56` (nl, de, es, it) ; dates
    # `15/09/2026` (fr, es, it, pt), `2026-09-15` (en), `15-09-2026` (nl),
    # `15.09.2026` (de). Une langue inconnue suit le français.
    struct Formatter
      # Langues qui séparent le taux du signe `%` par une espace.
      SPACED_PERCENT = %w[fr de es]

      getter locale : String

      def initialize(@locale : String)
      end

      # Montant à deux décimales, groupé par milliers.
      def amount(value : BigDecimal) : String
        integer, fraction = Formatter.fixed(value, 2)
        negative = integer.starts_with?('-')
        digits = integer.lchop('-')
        grouped = digits.reverse.scan(/\d{1,3}/).map(&.[0]).join(thousands).reverse
        "#{negative ? "-" : ""}#{grouped}#{decimal}#{fraction}"
      end

      # Quantité sans zéros inutiles (`10`, `2,5`).
      def quantity(value : BigDecimal) : String
        text = Formatter.plain(value)
        text.tr(".", decimal)
      end

      # Taux en pour cent : `20 %` (fr, de, es), `20%` (en, nl, it, pt).
      def percent(value : BigDecimal) : String
        spaced = SPACED_PERCENT.includes?(locale) || !Partiduo::LocaleFormats::CONVENTIONS.has_key?(locale)
        spaced ? "#{quantity(value)} %" : "#{quantity(value)}%"
      end

      def date(value : Time?) : String
        return "" unless value
        Partiduo::LocaleFormats.date(value, locale)
      end

      private def thousands : String
        Partiduo::LocaleFormats.for(locale).thousands
      end

      private def decimal : String
        Partiduo::LocaleFormats.for(locale).decimal
      end

      # Partie entière et partie décimale sur `places` chiffres, arrondi
      # commercial (demi à l'écart de zéro).
      def self.fixed(value : BigDecimal, places : Int32) : {String, String}
        rounded = value.round(places, mode: :ties_away)
        integer, _, fraction = plain(rounded).partition('.')
        integer = "0" if integer.empty? || integer == "-"
        {integer, fraction.ljust(places, '0')[0, places]}
      end

      # Écriture décimale sans exposant ni zéro final (`12.50` → `12.5`).
      def self.plain(value : BigDecimal) : String
        text = value.to_s
        text = text.rstrip('0').rchop('.') if text.includes?('.')
        text == "-0" ? "0" : text
      end
    end
  end
end
