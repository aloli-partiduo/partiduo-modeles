# SPDX-License-Identifier: AGPL-3.0-or-later

require "../spec_helper"

# Traductions des écrans de l'extension (ADR-005 D7) : chaque route de
# `/ext/MODELES/` servie en `GET` (liste tirée du routeur de Marten),
# obtenue en fr, en et nl par un administrateur, avec des convertisseurs
# de substitution : modèle Markdown par défaut, modèle DOCX en service
# avec une deuxième version à activer, modèle retiré, facture émise rendue,
# devis émis, facture brouillon. Les sortes de modèles propres aux specs
# (`SpecSupport::DATA_KINDS`, libellés non traduits) sont retirées le temps
# de l'exploration : les écrans sont ceux de la production.
# Contrôle de l'interface (`PartiduoUi::Translations`) : ni marqueur de
# traduction absente, ni clé brute, ni interpolation non résolue, et toute
# route atteinte par les liens des pages.

private alias S = Modeles::SpecSupport
private alias Api = Modeles::Api

describe "Traductions des écrans MODELES (fr, en, nl)" do
  it "rend chaque écran dans chaque langue, sans clé absente, brute ni interpolation non résolue" do
    S.books
    browser = PartiduoUi::Accounts.signed_in
    S.fake_converters
    S.template
    house = S.template(format: "docx", name: "Modèle maison", default: false)
    Api.upload(S.actor, Api::UploadInput.new(filename: "modele.docx", content: Modeles::Starters.file("invoice", "fr", "docx"),
      template_id: house.id)).value!
    retired = S.template(kind: "quote", format: "odt", name: "Ancien devis", default: false)
    Api.retire(S.actor, retired.id).value!
    invoice = S.issue
    Api.render(S.actor, invoice.id).value!
    S.issue("quote")
    S.draft

    explorer = PartiduoUi::Translations::Explorer.new(&.name.starts_with?("modeles:"))
    # Les requêtes laissent active la dernière langue obtenue (nl) : la
    # langue d'avant est rendue aux exemples suivants.
    locale = I18n.locale
    begin
      S.without_data_kinds { explorer.crawl(browser, "MODELES") }
    ensure
      I18n.activate(locale)
    end
    puts "\nTraductions de MODELES : #{explorer.report}"
    (explorer.failures + explorer.unreached.map { |route| "route jamais atteinte : #{route}" }).should eq([] of String)
  end
end
