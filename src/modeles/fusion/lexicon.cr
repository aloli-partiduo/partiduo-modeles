# SPDX-License-Identifier: AGPL-3.0-or-later

module Modeles
  module Fusion
    # Vocabulaire d'une sorte de modèle, lu par l'analyse (`Analyzer`) et
    # par la présentation à l'écran : objets (`{{ groupe.champ }}`), listes
    # parcourues par une boucle, listes imprimables telles quelles, et
    # groupes *ouverts* dont les champs ne sont pas connus d'avance (codes
    # des lignes d'un rapport, par exemple) : tout nom de champ
    # (`FIELD`) y est admis.
    #
    # Le vocabulaire des documents de la Facturation est `Vocabulary::INVOICE` ;
    # ceux des sortes déclarées par une extension sont bâtis par
    # `Modeles::Api.register_vocabulary` (A-REP-1).
    class Lexicon
      # Nom d'un champ d'un groupe ouvert (et d'une clé de données libres).
      FIELD = /\A[A-Za-z][A-Za-z0-9_]{0,39}\z/

      getter objects : Hash(String, Array(String))
      getter lists : Hash(String, Array(String))
      getter printable_lists : Array(String)
      getter open : Set(String)

      def initialize(@objects : Hash(String, Array(String)), @lists : Hash(String, Array(String)),
                     @printable_lists = [] of String, open : Enumerable(String) = [] of String)
        @open = open.to_set
      end

      def object?(name : String) : Bool
        @objects.has_key?(name)
      end

      def list?(name : String) : Bool
        @lists.has_key?(name)
      end

      def group?(name : String) : Bool
        object?(name) || list?(name)
      end

      def open?(group : String) : Bool
        @open.includes?(group)
      end

      # Le champ `field` du groupe `group` est-il admis ?
      def field?(group : String, field : String) : Bool
        fields = @objects[group]? || @lists[group]? || return false
        fields.includes?(field) || (open?(group) && FIELD.matches?(field))
      end

      # Tous les champs nommés, sous la forme `groupe.champ` (documentation).
      def paths : Array(String)
        @objects.flat_map { |group, fields| fields.map { |field| "#{group}.#{field}" } } +
          @lists.flat_map { |group, fields| fields.map { |field| "#{group}.#{field}" } }
      end
    end
  end
end
