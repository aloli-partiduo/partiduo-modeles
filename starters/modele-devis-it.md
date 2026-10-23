# {{ facture.type }} {{ facture.numero }}

**{{ vendeur.nom }}**\
{{ vendeur.adresse }}{% if vendeur.courriel %}\
{{ vendeur.courriel }}{% endif %}

**Cliente**\
{{ client.nom }}\
{{ client.adresse }}

| | |
|:--|:--|
| Data | {{ facture.date }} |
{% if facture.validite %}| Valido fino al | {{ facture.validite }} |
{% endif %}{% if facture.reference_acheteur %}| Vostro riferimento | {{ facture.reference_acheteur }} |
{% endif %}{% if facture.reference_commande %}| Vostro ordine | {{ facture.reference_commande }} |
{% endif %}
| Descrizione | Q.tà | Unità | Prezzo unit. | IVA | Imponibile |
|:--|--:|:--|--:|--:|--:|
{% for ligne in lignes %}{% if ligne.chiffree %}| {{ ligne.designation }}{% if ligne.remise %} (sconto {{ ligne.remise }}){% endif %} | {{ ligne.quantite }} | {{ ligne.unite }} | {{ ligne.prix_unitaire }} | {{ ligne.taux_tva }} | {{ ligne.montant_ht }} |
{% elsif ligne.sous_total %}| *{{ ligne.designation|default:"Subtotale" }}* | | | | | *{{ ligne.montant_ht }}* |
{% elsif ligne.note %}| *{{ ligne.designation }}* | | | | | |
{% else %}| **{{ ligne.designation }}** | | | | | |
{% endif %}{% endfor %}
| Aliquota IVA | Imponibile | Importo IVA |
|--:|--:|--:|
{% for groupe in tva %}| {{ groupe.taux }} | {{ groupe.base }} | {{ groupe.montant }} |
{% endfor %}
| | |
|:--|--:|
| Totale imponibile | {{ totaux.ht }} {{ facture.devise }} |
| Totale IVA | {{ totaux.tva }} {{ facture.devise }} |
| **Totale IVA inclusa** | **{{ totaux.ttc }} {{ facture.devise }}** |
{% if totaux.acompte %}| Acconti dedotti | {{ totaux.acompte }} {{ facture.devise }} |
| **Netto a pagare** | **{{ totaux.net_a_payer }} {{ facture.devise }}** |
{% endif %}
{% if facture.conditions_paiement %}**Condizioni di pagamento:** {{ facture.conditions_paiement }}

{% endif %}{% if facture.origine %}{{ facture.origine }}

{% endif %}{% if facture.notes %}{{ facture.notes }}

{% endif %}**Diciture obbligatorie**\
{{ mentions }}
