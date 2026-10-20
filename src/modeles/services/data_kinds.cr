# SPDX-License-Identifier: AGPL-3.0-or-later

module Modeles
  # Sortes de modèles déclarées par une extension (A-REP-1) : un modèle de
  # sorte `report` ou `listing` se remplit avec des données libres fournies
  # par l'extension qui l'a déclarée (`Modeles::Api.render_data`), et non
  # avec un document de la Facturation. Registre en mémoire, rempli au
  # chargement des extensions (`Modeles::Api.register_vocabulary`), comme
  # les sources d'immobilisations du cœur. Interne.
  module DataKinds
    # Nom d'une sorte déclarée : minuscules, chiffres, `_` (16 au plus,
    # colonne `modeles_template.kind`).
    KIND = /\A[a-z][a-z0-9_]{1,15}\z/
    # Nom d'un groupe (objet ou liste) et d'une variable de boucle.
    GROUP = /\A[a-z][a-z0-9_]{0,31}\z/

    # Données d'un rendu, au plus : valeurs, lignes répétées, caractères
    # d'une valeur.
    MAX_VALUES =  5_000
    MAX_ROWS   = 10_000
    MAX_VALUE  = 20_000
    # Erreurs de champ inconnu rendues, au plus (les suivantes sont tues).
    MAX_REPORTED = 20

    # Sorte déclarée : pièce qui la déclare (doit être active pour rendre),
    # libellé, préfixe des libellés du vocabulaire, vocabulaire, liste des
    # lignes répétées et variable de boucle proposée, données d'exemple de
    # l'aperçu.
    record Definition,
      kind : String,
      module_code : String,
      label_key : String,
      labels : String,
      lexicon : Fusion::Lexicon,
      list : String?,
      item : String?,
      sample_values : Hash(String, String),
      sample_rows : Array(Hash(String, String))

    @@definitions = {} of String => Definition

    # Enregistre (ou remplace, pour la même pièce) une sorte. Une
    # déclaration incohérente est une erreur de programmation de
    # l'extension : `ArgumentError`, au démarrage.
    def self.register(kind : String, input : Api::VocabularyInput) : Definition
      code = input.module_code.strip.upcase
      check_kind!(kind, code)
      list = input.list.strip.presence
      item = check_groups!(kind, input, list)
      lists = list ? {list => input.list_fields} : {} of String => Array(String)
      lexicon = Fusion::Lexicon.new(input.objects, lists, open: input.open)
      @@definitions[kind] = Definition.new(kind, code, input.label_key, input.labels.presence || "modeles.vocabulary",
        lexicon, list, item, input.sample_values, input.sample_rows)
    end

    # Nom de la sorte, réservée ou déjà prise par une autre pièce.
    private def self.check_kind!(kind : String, code : String) : Nil
      invalid!("sorte de modèle invalide : #{kind}") unless KIND.matches?(kind)
      invalid!("sorte réservée à la Facturation : #{kind}") if Config::KINDS.includes?(kind)
      invalid!("pièce déclarante absente pour #{kind}") if code.empty?
      if (existing = @@definitions[kind]?) && existing.module_code != code
        invalid!("sorte #{kind} déjà déclarée par #{existing.module_code}")
      end
    end

    # Noms des groupes, de la variable de boucle (rendue) et des champs.
    private def self.check_groups!(kind : String, input : Api::VocabularyInput, list : String?) : String?
      names = input.objects.keys
      names << list if list
      names.each { |name| invalid!("groupe invalide dans #{kind} : #{name}") unless group_name?(name) }
      invalid!("liste #{list} aussi objet dans #{kind}") if list && input.objects.has_key?(list)
      item = input.item.strip.presence || (list ? "item" : nil)
      if item && (!group_name?(item) || names.includes?(item))
        invalid!("variable de boucle invalide dans #{kind} : #{item}")
      end
      (input.open - names).each { |name| invalid!("groupe ouvert inconnu dans #{kind} : #{name}") }
      (input.objects.values.flatten + input.list_fields).each do |field|
        invalid!("champ invalide dans #{kind} : #{field}") unless Fusion::Lexicon::FIELD.matches?(field)
      end
      item
    end

    private def self.group_name?(name : String) : Bool
      GROUP.matches?(name) && name != "loop"
    end

    private def self.invalid!(message : String) : NoReturn
      raise ArgumentError.new(message)
    end

    def self.find(kind : String) : Definition?
      @@definitions[kind]?
    end

    def self.all : Array(Definition)
      @@definitions.values.sort_by!(&.kind)
    end

    # Vocabulaire d'une sorte : celui de la Facturation pour ses types de
    # document, celui de la déclaration pour une sorte déclarée.
    def self.lexicon(kind : String?) : Fusion::Lexicon
      kind.try { |value| find(value).try(&.lexicon) } || Fusion::Vocabulary::INVOICE
    end

    # Retire une sorte (specs).
    def self.unregister(kind : String) : Nil
      @@definitions.delete(kind)
    end

    # Erreurs des données d'un rendu : clés `groupe.champ` de `values` et
    # champs de chaque ligne de `rows` connus du vocabulaire, tailles
    # bornées. Champs d'erreur `values` et `rows`.
    def self.errors(definition : Definition, values : Hash(String, String),
                    rows : Array(Hash(String, String))) : Array(Partiduo::Api::FieldError)
      errors = [] of Partiduo::Api::FieldError
      lexicon = definition.lexicon
      if values.size > MAX_VALUES
        errors << fault("values", "too_many", {"max" => MAX_VALUES.to_s})
      end
      unknown = values.keys.reject do |key|
        group, _, field = key.partition('.')
        lexicon.object?(group) && lexicon.field?(group, field)
      end
      unknown.first(MAX_REPORTED).each { |key| errors << fault("values", "unknown_field", {"field" => key}) }
      if long = values.find { |_, value| value.size > MAX_VALUE }
        errors << fault("values", "too_long", {"field" => long[0], "max" => MAX_VALUE.to_s})
      end
      list = definition.list
      if list.nil?
        errors << fault("rows", "no_list", {"kind" => definition.kind}) unless rows.empty?
        return errors
      end
      errors << fault("rows", "too_many", {"max" => MAX_ROWS.to_s}) if rows.size > MAX_ROWS
      fields = rows.flat_map(&.keys).uniq!
      fields.reject { |field| lexicon.field?(list, field) }.first(MAX_REPORTED).each do |field|
        errors << fault("rows", "unknown_field", {"field" => "#{list}.#{field}"})
      end
      rows.each do |row|
        if long = row.find { |_, value| value.size > MAX_VALUE }
          errors << fault("rows", "too_long", {"field" => "#{list}.#{long[0]}", "max" => MAX_VALUE.to_s})
          break
        end
      end
      errors
    end

    private def self.fault(field : String, code : String, params : Hash(String, String)) : Partiduo::Api::FieldError
      Partiduo::Api::FieldError.new(field, "modeles.errors.data.#{code}", params)
    end
  end
end
