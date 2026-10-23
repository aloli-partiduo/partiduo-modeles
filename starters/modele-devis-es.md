# {{ facture.type }} {{ facture.numero }}

**{{ vendeur.nom }}**\
{{ vendeur.adresse }}{% if vendeur.courriel %}\
{{ vendeur.courriel }}{% endif %}

**Cliente**\
{{ client.nom }}\
{{ client.adresse }}

| | |
|:--|:--|
| Fecha | {{ facture.date }} |
{% if facture.validite %}| Válido hasta el | {{ facture.validite }} |
{% endif %}{% if facture.reference_acheteur %}| Su referencia | {{ facture.reference_acheteur }} |
{% endif %}{% if facture.reference_commande %}| Su pedido | {{ facture.reference_commande }} |
{% endif %}
| Descripción | Cant. | Unidad | P. unit. sin IVA | IVA | Total sin IVA |
|:--|--:|:--|--:|--:|--:|
{% for ligne in lignes %}{% if ligne.chiffree %}| {{ ligne.designation }}{% if ligne.remise %} (descuento {{ ligne.remise }}){% endif %} | {{ ligne.quantite }} | {{ ligne.unite }} | {{ ligne.prix_unitaire }} | {{ ligne.taux_tva }} | {{ ligne.montant_ht }} |
{% elsif ligne.sous_total %}| *{{ ligne.designation|default:"Subtotal" }}* | | | | | *{{ ligne.montant_ht }}* |
{% elsif ligne.note %}| *{{ ligne.designation }}* | | | | | |
{% else %}| **{{ ligne.designation }}** | | | | | |
{% endif %}{% endfor %}
| Tipo de IVA | Base imponible | Importe de IVA |
|--:|--:|--:|
{% for groupe in tva %}| {{ groupe.taux }} | {{ groupe.base }} | {{ groupe.montant }} |
{% endfor %}
| | |
|:--|--:|
| Total sin IVA | {{ totaux.ht }} {{ facture.devise }} |
| Total IVA | {{ totaux.tva }} {{ facture.devise }} |
| **Total IVA incluido** | **{{ totaux.ttc }} {{ facture.devise }}** |
{% if totaux.acompte %}| Anticipos deducidos | {{ totaux.acompte }} {{ facture.devise }} |
| **Neto a pagar** | **{{ totaux.net_a_payer }} {{ facture.devise }}** |
{% endif %}
{% if facture.conditions_paiement %}**Condiciones de pago:** {{ facture.conditions_paiement }}

{% endif %}{% if facture.origine %}{{ facture.origine }}

{% endif %}{% if facture.notes %}{{ facture.notes }}

{% endif %}**Menciones legales**\
{{ mentions }}
