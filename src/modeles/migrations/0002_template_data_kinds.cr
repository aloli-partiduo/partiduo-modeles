# SPDX-License-Identifier: AGPL-3.0-or-later

# Sortes de modèles déclarées par une extension (A-REP-1, D-MOD-019) : la
# sorte d'un modèle n'est plus seulement un type de document de la
# Facturation (`invoice`, `quote`, `credit_note`) mais aussi une sorte
# déclarée (`report`, `listing`…), dont la liste n'est connue qu'au
# démarrage. La base contrôle désormais sa forme (minuscules, chiffres,
# `_`, 2 à 16 caractères) ; le contrat contrôle qu'elle est déclarée. Les
# modèles existants (types de la Facturation) satisfont la nouvelle règle :
# aucune donnée ne change.
#
# Retour arrière : l'ancienne contrainte, qui échoue tant qu'un modèle d'une
# sorte déclarée existe (il faut alors le retirer de la base d'abord).
class Migration::Modeles::V0002 < Marten::Migration
  depends_on :modeles, "0001_create_modeles"

  FORWARD = <<-SQL
    ALTER TABLE modeles_template
      DROP CONSTRAINT IF EXISTS modeles_template_kind_check,
      ADD CONSTRAINT modeles_template_kind_check CHECK (kind ~ '^[a-z][a-z0-9_]{1,15}$')
    SQL

  BACKWARD = <<-SQL
    ALTER TABLE modeles_template
      DROP CONSTRAINT IF EXISTS modeles_template_kind_check,
      ADD CONSTRAINT modeles_template_kind_check CHECK (kind IN ('invoice', 'quote', 'credit_note'))
    SQL

  def plan
    execute(FORWARD, BACKWARD)
  end
end
