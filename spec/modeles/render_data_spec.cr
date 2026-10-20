# SPDX-License-Identifier: AGPL-3.0-or-later

require "../spec_helper"

private alias S = Modeles::SpecSupport
private alias Api = Modeles::Api

# Modèle Markdown d'une sorte déclarée : objets, groupe ouvert, lignes.
private MARKDOWN = <<-MD
  # {{ entete.titre }}

  Période : {{ entete.periode }}{% if entete.note %} — {{ entete.note }}{% endif %}

  CA : {{ montants.CA }} ; VA : {{ montants.VA_N1|default:"néant" }}

  | Code | Libellé | Montant |
  |---|---|---|
  {% for ligne in lignes %}| {{ ligne.code }} | {{ ligne.libelle }} | {{ ligne.montant }} |
  {% endfor %}
  MD

private def data_template(kind : String = "essai", content : String = MARKDOWN, format : String = "markdown",
                          default : Bool = true, locale : String = "fr") : Api::TemplateView
  S.template(kind: kind, format: format, content: content.to_slice, name: "Modèle #{kind}", default: default,
    locale: locale)
end

private def values : Hash(String, String)
  {"entete.titre" => "Soldes *intermédiaires*", "entete.periode" => "2026", "entete.note" => "",
   "montants.CA" => "1 234,50", "montants.VA_N1" => ""}
end

private def rows : Array(Hash(String, String))
  [{"code" => "CA", "libelle" => "Ventes | services", "montant" => "1 234,50"},
   {"code" => "VA", "libelle" => "Valeur ajoutée", "montant" => "800,00", "N1" => "700,00"}]
end

describe "Rendu d'un modèle avec des données libres (A-REP-1)" do
  it "propose les sortes déclarées par une pièce active, après celles de la Facturation" do
    S.books
    kinds = Api.kinds(S.reader)
    kinds.map(&.code).should eq(%w[invoice quote credit_note essai fiche_seule])
    kinds.find!(&.code.==("essai")).module_code.should eq("MODELES")
    kinds.find!(&.code.==("essai")).invoicing.should be_false
    Api.kind_label_key("essai").should eq("modeles.kinds.invoice")
    Api.kind_label_key("inconnue").should eq("inconnue")
  end

  it "refuse une déclaration incohérente au chargement" do
    input = Api::VocabularyInput.new(module_code: "MODELES", label_key: "x", objects: {"a" => %w[b]})
    expect_raises(ArgumentError) { Api.register_vocabulary("invoice", input) }
    expect_raises(ArgumentError) { Api.register_vocabulary("Rapport", input) }
    expect_raises(ArgumentError) { Api.register_vocabulary("essai", input.copy_with(module_code: "AUTRE")) }
    expect_raises(ArgumentError) { Api.register_vocabulary("neuve", input.copy_with(objects: {"a" => ["b-c"]})) }
    expect_raises(ArgumentError) { Api.register_vocabulary("neuve", input.copy_with(open: ["z"])) }
    expect_raises(ArgumentError) { Api.register_vocabulary("neuve", input.copy_with(list: "a")) }
    Modeles::DataKinds.find("neuve").should be_nil
  end

  it "contrôle un modèle déposé avec le vocabulaire de sa sorte, sans mentions obligatoires" do
    S.books
    check = Api.check(S.actor, Api::UploadInput.new("r.md", MARKDOWN.to_slice, name: "r", kind: "essai", locale: "fr"))
    check.errors.should be_empty
    check.fields.should contain("montants.CA")
    check.fields.should contain("lignes.libelle")
    bad = "{{ entete.inconnu }} {{ facture.numero }} {% for x in entete %}{% endfor %}"
    errors = Api.check(S.actor, Api::UploadInput.new("r.md", bad.to_slice, name: "r", kind: "essai", locale: "fr")).errors
    errors.compact_map(&.params["field"]?).should contain("entete.inconnu")
    errors.compact_map(&.params["field"]?).should contain("facture.numero")
    errors.map(&.key).should contain("modeles.check.not_a_list")
    # Le vocabulaire d'une sorte ne vaut pas pour une facture.
    invoice = Api.check(S.actor, Api::UploadInput.new("f.md", MARKDOWN.to_slice, name: "f", kind: "invoice", locale: "fr"))
    invoice.errors.map(&.key).should contain("modeles.check.unknown_field")
  end

  it "refuse au dépôt une sorte inconnue ou déclarée par une pièce inactive" do
    S.books
    %w[inconnue compta].each do |kind|
      result = Api.upload(S.actor, Api::UploadInput.new("r.md", "{{ compte.numero }}".to_slice, name: "r", kind: kind, locale: "fr"))
      result.errors.map(&.key).should contain("modeles.errors.kind.invalid")
    end
  end

  it "rend les valeurs et les lignes répétées, échappées selon le format" do
    S.books
    template = data_template
    result = Api.render_data(S.reader, nil, "essai", values, rows, name: "SIG 2026").value!
    text = S.text(result.file.content)
    text.should contain("# Soldes \\*intermédiaires\\*")
    text.should contain("Période : 2026\n")
    text.should_not contain(" — ")
    text.should contain("CA : 1 234,50 ; VA : néant")
    text.should contain("| CA | Ventes \\| services | 1 234,50 |")
    text.should contain("| VA | Valeur ajoutée | 800,00 |")
    result.file.filename.should eq("sig-2026-modele-essai-v#{template.active_version}.md")
    result.file.content_type.should eq("text/markdown")
    result.rendition.should be_nil
    result.draft.should be_false
    result.pdf.should be_nil
    result.pdf_error.should be_nil
    Api.renditions(S.reader).should be_empty
  end

  it "rend un modèle ODT avec un tableau de lignes répétées" do
    S.books
    o = S::OfficeFiles
    body = o.tp("{{ entete.titre }}") +
           o.table(o.row(o.tp("{% for ligne in lignes %}{{ ligne.code }}"), o.tp("{{ ligne.libelle }}"),
             o.tp("{{ ligne.montant }}{% endfor %}")))
    template = S.template(kind: "essai", format: "odt", content: o.odt(body), name: "ODT", default: false)
    result = Api.render_data(S.reader, template.id, "essai", values, rows).value!
    xml = o.part(result.file.content, "content.xml")
    text = o.visible(xml)
    text.should contain("Soldes *intermédiaires*")
    text.should contain("Ventes | services")
    xml.scan("<table:table-row>").size.should eq(2)
    result.file.filename.should end_with(".odt")
  end

  it "rend une sorte sans lignes et refuse des lignes pour elle" do
    S.books
    S.template(kind: "fiche_seule", format: "markdown", content: "{{ fiche.nom }} — {{ fiche.ville }}".to_slice)
    Api.render_data(S.reader, nil, "fiche_seule", {"fiche.nom" => "Durand & Fils"}).value!.file.content
      .should eq("Durand \\& Fils — ".to_slice)
    failure = Api.render_data(S.reader, nil, "fiche_seule", {} of String => String, [{"x" => "y"}])
    failure.errors.map(&.key).should eq(["modeles.errors.data.no_list"])
  end

  it "refuse une sorte inconnue, une donnée hors vocabulaire, des données trop longues" do
    S.books
    data_template
    Api.render_data(S.reader, nil, "inconnue", values).errors.map(&.key).should eq(["modeles.errors.kind.unregistered"])
    unknown = Api.render_data(S.reader, nil, "essai", {"entete.auteur" => "x", "autre.champ" => "y", "titre" => "z"})
    unknown.errors.map(&.field).uniq!.should eq(["values"])
    unknown.errors.map(&.params["field"]).should eq(["entete.auteur", "autre.champ", "titre"])
    bad_rows = Api.render_data(S.reader, nil, "essai", values, [{"code-x" => "1"}])
    bad_rows.errors.map { |error| {error.field, error.key} }.should eq([{"rows", "modeles.errors.data.unknown_field"}])
    long = Api.render_data(S.reader, nil, "essai", {"entete.titre" => "x" * (Modeles::DataKinds::MAX_VALUE + 1)})
    long.errors.map(&.key).should eq(["modeles.errors.data.too_long"])
  end

  it "refuse un modèle absent, hors service ou d'une autre sorte" do
    S.books
    Api.render_data(S.reader, nil, "essai", values).errors.map(&.key).should eq(["modeles.errors.template.none"])
    invoice = S.template
    Api.render_data(S.reader, invoice.id, "essai", values).errors.map(&.key).should eq(["modeles.errors.template.kind_mismatch"])
    pending = Api.upload(S.actor, Api::UploadInput.new("r.md", MARKDOWN.to_slice, name: "r", kind: "essai", locale: "fr")).value!
    Api.render_data(S.reader, pending.id, "essai", values).errors.map(&.key).should eq(["modeles.errors.template.not_active"])
    # Le modèle par défaut est celui de la langue demandée.
    data_template(locale: "en")
    Api.render_data(S.reader, nil, "essai", values, locale: "fr").errors.map(&.key).should eq(["modeles.errors.template.none"])
    Api.render_data(S.reader, nil, "essai", values, locale: "en").success?.should be_true
  end

  it "rend le fichier et signale l'absence de convertisseur PDF ; convertit quand il est déclaré" do
    S.books
    data_template
    without = Api.render_data(S.reader, nil, "essai", values, rows, pdf: true).value!
    without.pdf.should be_nil
    without.pdf_error.should eq("modeles.errors.pdf.unavailable")
    without.file.content.size.should be > 0
    S.fake_converters
    converted = Api.render_data(S.reader, nil, "essai", values, rows, pdf: true).value!
    pdf = converted.pdf || raise "PDF absent"
    pdf.content_type.should eq("application/pdf")
    pdf.filename.should end_with(".pdf")
    converted.pdf_error.should be_nil
    S.fake_converters("failing-convert")
    failed = Api.render_data(S.reader, nil, "essai", values, rows, pdf: true).value!
    failed.pdf.should be_nil
    failed.pdf_error.should eq("modeles.errors.pdf.failed")
  end

  it "exige modeles.read et la pièce déclarante active" do
    S.books
    data_template
    expect_raises(Partiduo::Api::Forbidden) { Api.render_data(S.actor(["invoicing.invoice.read"]), nil, "essai", values) }
    expect_raises(Partiduo::Api::ModuleDisabled) { Api.render_data(S.reader, nil, "compta", {"compte.numero" => "411"}) }
  end

  it "prévisualise un modèle de sorte déclarée avec ses données d'exemple" do
    S.books
    template = data_template
    preview = Api.preview(S.reader, template.id).value!
    text = S.text(preview.file.content)
    text.should contain("**Exemple — sans valeur**")
    text.should contain("Titre d'exemple")
    text.should contain("| CA | Chiffre d'affaires | 1 000,00 |")
    preview.draft.should be_true
  end

  it "décrit le vocabulaire d'une sorte déclarée" do
    S.books
    groups = Api.vocabulary(S.reader, "essai")
    groups.map(&.name).should eq(%w[entete montants lignes])
    groups.find!(&.name.==("montants")).open.should be_true
    groups.find!(&.name.==("lignes")).item.should eq("ligne")
    groups.find!(&.name.==("lignes")).list.should be_true
    Api.vocabulary(S.reader, "inconnue").should be_empty
    Api.vocabulary(S.reader).map(&.name).should contain("facture")
  end
end
