# Anhalten der Eskalationsberechnung bei bestimmten Status

Mit dieser Erweiterung können Sie die Eskalationsberechnung eines Tickets "anhalten", solange es sich in einem vorher definierten Status befindet. Beim Setzen des vordefinierten-Status vorm Ablaufen der Eskalationszeit, verlängert sich die Lösungszeit um die Zeitdauer, in der es sich in diesem Status befindet.

Ein typischer Anwendungsfall ist, dass beim Warten auf einen Kunden die Eskalationsberechnung "angehalten" werden soll. Die entsprechenden Status können über die SysConfig (Gruppe: Znuny4OTRS-EscalationSuspend -> Untergruppe: EscalationSuspend) eingestellt werden. Im Standard sind die drei Status 'pending auto close+', 'pending auto close-' und 'pending reminder' eingetragen. Diese können individuell angepasst werden.

Exemplarischer Beispielfall:

* 09:00 - Das Ticket wird in den Status "pending reminder" (warten auf Erinnerung) gesetzt, da der Kunde nicht erreicht wurde. Die zu erwartende Eskalation wird für 10:00 angezeigt.
* 09:30 - Das Ticket verweilt nun 30 Min. im Status "pending reminder". Die Eskalationsberechnung wird in regelmäßigen Abständen durchgeführt. Das bedeutet, dass der Eskalationszeitpunkt um 30 min nach hinten verschoben wird. Die zu erwartende Eskalation wird für 10:30 angezeigt.
* 10:00 - Das Ticket verweilt nun 60 Min. im Status "pending reminder". Die Eskalationsberechnung wurde bereits erneut durchgeführt, da der Status noch immer im Erinnerungs-Modus steht. Die zu erwartende Eskalation wird für 11:00 angezeigt.
* 10:05 - Der Kunde Antwortet via E-Mail mit den fehlenden Informationen. Das Ticket wird in den Status "open" gesetzt. Die zu erwartende Eskalation wird für 11:05 angezeigt.
* 10:30 - Die zu erwartende Eskalation wird für 11:05 angezeigt.
* 11:00 - Die zu erwartende Eskalation wird für 11:05 angezeigt.
* 11:05 - Das Ticket ist eskaliert.
