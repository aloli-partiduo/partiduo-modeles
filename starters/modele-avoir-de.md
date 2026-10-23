# {{ facture.type }} {{ facture.numero }}

**{{ vendeur.nom }}**\
{{ vendeur.adresse }}{% if vendeur.courriel %}\
{{ vendeur.courriel }}{% endif %}

**Kunde**\
{{ client.nom }}\
{{ client.adresse }}

| | |
|:--|:--|
| Datum | {{ facture.date }} |
{% if facture.facture_origine %}| Ursprüngliche Rechnung | {{ facture.facture_origine }} |
{% endif %}{% if facture.facture_origine_date %}| Vom | {{ facture.facture_origine_date }} |
{% endif %}{% if facture.reference_acheteur %}| Ihre Referenz | {{ facture.reference_acheteur }} |
{% endif %}{% if facture.reference_commande %}| Ihre Bestellung | {{ facture.reference_commande }} |
{% endif %}
| Bezeichnung | Menge | Einheit | EP netto | USt. | Summe netto |
|:--|--:|:--|--:|--:|--:|
{% for ligne in lignes %}{% if ligne.chiffree %}| {{ ligne.designation }}{% if ligne.remise %} (Rabatt {{ ligne.remise }}){% endif %} | {{ ligne.quantite }} | {{ ligne.unite }} | {{ ligne.prix_unitaire }} | {{ ligne.taux_tva }} | {{ ligne.montant_ht }} |
{% elsif ligne.sous_total %}| *{{ ligne.designation|default:"Zwischensumme" }}* | | | | | *{{ ligne.montant_ht }}* |
{% elsif ligne.note %}| *{{ ligne.designation }}* | | | | | |
{% else %}| **{{ ligne.designation }}** | | | | | |
{% endif %}{% endfor %}
| USt.-Satz | Bemessungsgrundlage | USt.-Betrag |
|--:|--:|--:|
{% for groupe in tva %}| {{ groupe.taux }} | {{ groupe.base }} | {{ groupe.montant }} |
{% endfor %}
| | |
|:--|--:|
| Summe netto | {{ totaux.ht }} {{ facture.devise }} |
| Summe USt. | {{ totaux.tva }} {{ facture.devise }} |
| **Summe brutto** | **{{ totaux.ttc }} {{ facture.devise }}** |
{% if totaux.acompte %}| Abgezogene Anzahlungen | {{ totaux.acompte }} {{ facture.devise }} |
| **Zahlbetrag** | **{{ totaux.net_a_payer }} {{ facture.devise }}** |
{% endif %}
{% if facture.conditions_paiement %}**Zahlungsbedingungen:** {{ facture.conditions_paiement }}

{% endif %}{% if facture.origine %}{{ facture.origine }}

{% endif %}{% if facture.notes %}{{ facture.notes }}

{% endif %}**Pflichtangaben**\
{{ mentions }}
