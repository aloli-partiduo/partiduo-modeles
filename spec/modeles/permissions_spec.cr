# SPDX-License-Identifier: AGPL-3.0-or-later

require "../spec_helper"

private alias S = Modeles::SpecSupport
private alias Api = Modeles::Api

describe "Droits (ADR-010 D7)" do
  it "déclare modeles.read et modeles.admin, sans dépendre de la Facturation (D-MOD-018)" do
    manifest = Partiduo::Modules[Modeles::CODE]
    manifest.permissions.should eq(%w[modeles.read modeles.admin])
    manifest.depends_on.should be_empty
  end

  it "reste active sans la Facturation, dont les documents sont alors refusés" do
    S.books
    S.template
    invoice = S.issue
    Partiduo::Api::Modules.deactivate(S::SYSTEM, "INVOICING").value!
    Api.templates(S.actor).size.should eq(1)
    Api.kinds(S.actor).map(&.code).should_not contain("invoice")
    expect_raises(Partiduo::Api::ModuleDisabled) { Api.render(S.reader, invoice.id) }
    result = Api.upload(S.actor, Api::UploadInput.new("f.md", Modeles::Starters.file("invoice", "fr", "markdown"),
      name: "x", kind: "invoice", locale: "fr"))
    result.errors.map(&.key).should contain("modeles.errors.kind.invalid")
    Partiduo::Api::Modules.activate(S::SYSTEM, "INVOICING").value!
    Api.render(S.reader, invoice.id).success?.should be_true
  end

  it "réserve le dépôt, l'activation, le défaut et le retrait à modeles.admin" do
    S.books
    view = S.template
    input = Api::UploadInput.new("f.md", Modeles::Starters.file("invoice", "fr", "markdown"), name: "x", kind: "invoice", locale: "fr")
    expect_raises(Partiduo::Api::Forbidden) { Api.upload(S.reader, input) }
    expect_raises(Partiduo::Api::Forbidden) { Api.check(S.reader, input) }
    expect_raises(Partiduo::Api::Forbidden) { Api.activate(S.reader, view.id) }
    expect_raises(Partiduo::Api::Forbidden) { Api.set_default(S.reader, view.id) }
    expect_raises(Partiduo::Api::Forbidden) { Api.retire(S.reader, view.id) }
    Api.templates(S.reader).size.should eq(1)
    Api.render(S.reader, S.issue.id).success?.should be_true
  end

  it "exige modeles.read pour rendre et télécharger, et la lecture des factures" do
    S.books
    S.template
    invoice = S.issue
    nobody = S.actor(["invoicing.invoice.read"])
    expect_raises(Partiduo::Api::Forbidden) { Api.render(nobody, invoice.id) }
    expect_raises(Partiduo::Api::Forbidden) { Api.templates(nobody) }
    expect_raises(Partiduo::Api::Forbidden) { Api.starter_file(nobody, "invoice", "fr", "odt") }
    expect_raises(Partiduo::Api::Forbidden) { Api.render(S.actor([Api::READ]), invoice.id) }
  end

  it "n'existe pas tant que l'extension est inactive" do
    S.books(activate: false)
    expect_raises(Partiduo::Api::ModuleDisabled) { Api.templates(S.actor) }
  end
end
