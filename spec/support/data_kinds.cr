# SPDX-License-Identifier: AGPL-3.0-or-later

module Modeles
  module SpecSupport
    # Sortes de modèles déclarées pour les specs du rendu de données libres
    # (A-REP-1), comme le ferait une extension à son chargement : `essai`
    # (objets, groupe ouvert, lignes répétées), `fiche_seule` (sans lignes),
    # déclarées par MODELES elle-même ; `compta`, par la Comptabilité,
    # inactive dans ces specs. Libellés de leur vocabulaire sous
    # `modeles_specs.vocabulary`, dans `spec/support/locales` (chargé par les
    # specs seules, comme l'extension qui déclare une sorte fournit les siens).
    LABELS = "modeles_specs.vocabulary"

    DATA_KINDS = {
      "essai" => Modeles::Api::VocabularyInput.new(
        module_code: "MODELES", label_key: "modeles.kinds.invoice", labels: LABELS,
        objects: {"entete" => %w[titre periode note], "montants" => [] of String},
        open: %w[montants lignes], list: "lignes", item: "ligne", list_fields: %w[code libelle montant],
        sample_values: {"entete.titre" => "Titre d'exemple", "montants.CA" => "1 000,00"},
        sample_rows: [{"code" => "CA", "libelle" => "Chiffre d'affaires", "montant" => "1 000,00"}]),
      "fiche_seule" => Modeles::Api::VocabularyInput.new(
        module_code: "MODELES", label_key: "modeles.kinds.quote", labels: LABELS,
        objects: {"fiche" => %w[nom ville]}),
      "compta" => Modeles::Api::VocabularyInput.new(
        module_code: "ACCOUNTING", label_key: "modeles.kinds.credit_note", labels: LABELS,
        objects: {"compte" => %w[numero]}),
    }

    def self.register_data_kinds : Nil
      DATA_KINDS.each { |kind, input| Modeles::Api.register_vocabulary(kind, input) }
    end

    # Exécute le bloc sans les sortes propres aux specs (écrans tels qu'en
    # production), puis les déclare de nouveau.
    def self.without_data_kinds(&) : Nil
      DATA_KINDS.each_key { |kind| Modeles::DataKinds.unregister(kind) }
      yield
    ensure
      register_data_kinds
    end
  end
end

# Avant `Marten.setup` (début de suite), qui lit les traductions.
I18n.config.loaders << I18n::Loader::YAML.new(File.join(__DIR__, "locales"))
Modeles::SpecSupport.register_data_kinds
