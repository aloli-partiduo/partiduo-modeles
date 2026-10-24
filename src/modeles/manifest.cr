# SPDX-License-Identifier: AGPL-3.0-or-later

# Manifeste de l'extension MODELES (ADR-010, ADR-003 D2) : modèles de
# factures, devis et avoirs multiformats, et modèles des sortes déclarées
# par d'autres extensions, remplis par leurs données (A-REP-1).
#
# * Aucune dépendance déclarée (D-MOD-018) : les documents de la
#   Facturation sont lus par `Partiduo::Api::Invoicing`, qui refuse
#   (`ModuleDisabled`) quand elle est inactive ; le rendu de données libres
#   n'en a pas besoin. L'extension se rend donc utile aux dossiers sans
#   Facturation (rapports, listings).
# * Permissions (ADR-010 D7) : `modeles.read` (rendre un document avec un
#   modèle, télécharger les rendus, les modèles et les modèles de départ),
#   `modeles.admin` (déposer, activer, désigner par défaut, retirer).
# * Menu « Modèles de documents » sous « Facturation ».
# * Aucun abonnement : un rendu est demandé par l'utilisateur, jamais
#   déclenché par l'émission (le PDF légal Factur-X reste la référence,
#   ADR-010 D4).
# * Exclusion (D-MOD-023, D-AMD-042 du cœur) : jamais dans le dossier d'un
#   foyer (`incompatible_with_kind "household"`), même sans PERSO : les
#   modèles de factures, devis et avoirs sont des documents d'entreprise.
Partiduo::Modules.register do
  code "MODELES"
  name "modeles.module.name"
  version Modeles::VERSION
  requires_core "~> 0.1"
  incompatible_with_kind "household"

  permission "modeles.read"
  permission "modeles.admin"

  menu "MODELES", parent: "BILLING", order: 70, route: "modeles:index", permission: "modeles.read",
    label: "modeles.menu.templates"

  ui "bulma", path: "ui/bulma"
end
