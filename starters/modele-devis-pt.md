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
{% if facture.validite %}| Válido até | {{ facture.validite }} |
{% endif %}{% if facture.reference_acheteur %}| A vossa referência | {{ facture.reference_acheteur }} |
{% endif %}{% if facture.reference_commande %}| A vossa encomenda | {{ facture.reference_commande }} |
{% endif %}
| Designação | Qtd. | Unidade | PU s/ IVA | IVA | Total s/ IVA |
|:--|--:|:--|--:|--:|--:|
{% for ligne in lignes %}{% if ligne.chiffree %}| {{ ligne.designation }}{% if ligne.remise %} (desconto {{ ligne.remise }}){% endif %} | {{ ligne.quantite }} | {{ ligne.unite }} | {{ ligne.prix_unitaire }} | {{ ligne.taux_tva }} | {{ ligne.montant_ht }} |
{% elsif ligne.sous_total %}| *{{ ligne.designation|default:"Subtotal" }}* | | | | | *{{ ligne.montant_ht }}* |
{% elsif ligne.note %}| *{{ ligne.designation }}* | | | | | |
{% else %}| **{{ ligne.designation }}** | | | | | |
{% endif %}{% endfor %}
| Taxa de IVA | Base s/ IVA | Montante de IVA |
|--:|--:|--:|
{% for groupe in tva %}| {{ groupe.taux }} | {{ groupe.base }} | {{ groupe.montant }} |
{% endfor %}
| | |
|:--|--:|
| Total s/ IVA | {{ totaux.ht }} {{ facture.devise }} |
| Total IVA | {{ totaux.tva }} {{ facture.devise }} |
| **Total c/ IVA** | **{{ totaux.ttc }} {{ facture.devise }}** |
{% if totaux.acompte %}| Adiantamentos deduzidos | {{ totaux.acompte }} {{ facture.devise }} |
| **Total a pagar** | **{{ totaux.net_a_payer }} {{ facture.devise }}** |
{% endif %}
{% if facture.conditions_paiement %}**Condições de pagamento:** {{ facture.conditions_paiement }}

{% endif %}{% if facture.origine %}{{ facture.origine }}

{% endif %}{% if facture.notes %}{{ facture.notes }}

{% endif %}**Menções legais**\
{{ mentions }}
