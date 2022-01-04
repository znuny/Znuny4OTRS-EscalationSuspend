# Funktionalität

Mit dieser Erweiterung kann die Eskalationsberechnung eines Tickets "angehalten" werden, solange es sich in einem vorher definierten Status befindet. Beim Setzen des vordefinierten Status vor Ablauf der Eskalationszeit verlängert sich die Lösungszeit um die Dauer, in der es sich in diesem Status befindet.

Ein typischer Anwendungsfall ist, dass beim Warten auf einen Kunden die Eskalationsberechnung "angehalten" werden soll. Die entsprechenden Status können über die SysConfig eingestellt werden. Standardmäßig sind die drei Status 'pending auto close+', 'pending auto close-' und 'pending reminder' eingetragen. Diese können individuell angepasst werden.

![SuspendEscalatedTickets](doc/de/images/EscalationSuspendStates.png)

Beispielfall:

  * 08:00 - Ein Ticket wird erstellt. Die Lösungszeit beträgt 2 Stunden. Die zu erwartende Eskalation wird für 10:00 angezeigt.
  * 09:00 - Das Ticket wird in den Status "pending reminder" gesetzt, da der Kunde nicht erreicht wurde. Die zu erwartende Eskalation wird für 10:00 angezeigt.
  * 09:30 - Das Ticket verweilt nun 30 Min. im Status "pending reminder". Die zu erwartende Eskalation wird für 10:30 angezeigt.
  * 10:00 - Das Ticket verweilt nun 60 Min. im Status "pending reminder". Die zu erwartende Eskalation wird für 11:00 angezeigt.
  * 10:05 - Der Kunde Antwortet via E-Mail mit den fehlenden Informationen. Das Ticket wird in den Status "open" gesetzt. Die zu erwartende Eskalation wird für 11:05 angezeigt.
  * 10:30 - Die zu erwartende Eskalation wird für 11:05 angezeigt.
  * 11:00 - Die zu erwartende Eskalation wird für 11:05 angezeigt.
  * 11:05 - Das Ticket eskaliert.
