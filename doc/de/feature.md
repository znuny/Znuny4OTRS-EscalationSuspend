# Anhalten der Eskalationsberechnung bei bestimmten Status

Mit dieser Erweiterung können Sie die Eskalationsberechnung eines Tickets "anhalten" solange dieses Ticket in einem konfigurierten Status verweilt.

Ein typischer Anwendungsfall ist, dass Sie beim warten auf einen Kunden die Eskalationsberechnung "anhalten" wollen. Den verwendeten Status können Sie über die SysConfig (Gruppe: Znuny4OTRS-EscalationSuspend -> Untergruppe: EscalationSuspend) konfigurieren. Im Standard sind folgende drei Stati eingetragen 'pending auto close+', 'pending auto close-' und 'pending reminder'.

Beispiel:

  * 08:00 - Ein Ticket wird erstellt. Lösungszeit beträgt 2 Stunden. Die zu erwartende Eskalation wird für 10:00 angezeigt.
  * 09:00 - Das Ticket auf "pending reminder" gesetzt, da der Kunde nicht erreicht wurde. Die zu erwartende Eskalation wird für 10:00 angezeigt.
  * 09:30 - Das Ticket verweilt nun 30 Min. in "pending reminder". Die zu erwartende Eskalation wird für 10:30 angezeigt.
  * 10:00 - Das Ticket verweilt nun 60 Min. in "pending reminder". Die zu erwartende Eskalation wird für 11:00 angezeigt.
  * 10:05 - Der Kunde Antwortet via E-Mail mit den fehlenden Informationen. Das Ticket wird auf "open" gesetzt. Die zu erwartende Eskalation wird für 11:05 angezeigt.
  * 10:30 - Die zu erwartende Eskalation wird für 11:05 angezeigt.
  * 11:00 - Die zu erwartende Eskalation wird für 11:05 angezeigt.
  * 11:05 - Das Ticket ist eskalliert.

