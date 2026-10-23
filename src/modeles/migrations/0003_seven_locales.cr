# SPDX-License-Identifier: AGPL-3.0-or-later

# Langues d'un document (D-MOD-022) : la Facturation accepte un document
# dans toute langue d'interface de Partiduo ; la base accepte donc les
# modèles et les rendus en fr, en, nl, de, es, it et pt. La liste est
# figée ici (une migration ne suit pas le code) ; aucune donnée ne change.
#
# Retour arrière : l'ancienne contrainte, qui échoue tant qu'un modèle ou
# un rendu dans une des nouvelles langues existe.
class Migration::Modeles::V0003 < Marten::Migration
  depends_on :modeles, "0002_template_data_kinds"

  NEW = "('fr', 'en', 'nl', 'de', 'es', 'it', 'pt')"
  OLD = "('fr', 'en', 'nl')"

  def plan
    %w[modeles_template modeles_rendition].each do |table|
      execute(constraint(table, NEW), constraint(table, OLD))
    end
  end

  private def constraint(table : String, locales : String) : String
    <<-SQL
      ALTER TABLE #{table}
        DROP CONSTRAINT IF EXISTS #{table}_locale_check,
        ADD CONSTRAINT #{table}_locale_check CHECK (locale IN #{locales})
      SQL
  end
end
