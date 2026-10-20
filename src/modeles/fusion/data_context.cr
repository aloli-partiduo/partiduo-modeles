# SPDX-License-Identifier: AGPL-3.0-or-later

module Modeles
  module Fusion
    # Contexte de fusion de données libres (A-REP-1) : un objet par groupe
    # du vocabulaire déclaré (`{{ declaration.titre }}`), rempli par les
    # valeurs `groupe.champ`, et la liste des lignes répétées
    # (`{% for ligne in lignes %}`). Les valeurs sont déjà présentées par
    # l'extension appelante (montants, dates dans la langue voulue) ; elles
    # sont échappées ici selon le format du modèle, comme celles d'une
    # facture (`Escaper`) : une valeur ne devient jamais de la mise en forme.
    # Une valeur vide vaut `nil` (fausse dans un `{% if %}`).
    module DataContext
      def self.build(definition : DataKinds::Definition, format : String, values : Hash(String, String),
                     rows : Array(Hash(String, String))) : Hash(String, Marten::Template::Value)
        groups = definition.lexicon.objects.keys.to_h { |name| {name, Record.new} }
        values.each do |key, value|
          group, _, field = key.partition('.')
          groups[group]?.try { |record| record[field] = text(format, value) }
        end
        context = groups.transform_values { |record| Marten::Template::Value.from(record) }
        if list = definition.list
          items = rows.map do |row|
            Record.new(row.to_h { |field, value| {field, text(format, value, inline: true).as(Record::Value)} })
          end
          context[list] = Marten::Template::Value.from(items)
        end
        context
      end

      private def self.text(format : String, value : String, inline : Bool = false) : String?
        value.strip.empty? ? nil : Escaper.escape(format, value, inline)
      end
    end
  end
end
