# Konfiguration

## Sicherstellung der Performance
Bei der Berechnung der Arbeitszeit kann es je nach Kalender-Einstellung, Wochenenden und Feiertagen zu Auswirkungen auf die Performance kommen. Um negativen Seiteneffekten vorzubeugen, wurde ein Limit an Berechnungszyklen von standardmäßig 500 eingestellt. Dies wird in über 95% der Fälle nie erreicht. Sollte es doch erreicht werden, kommt es zu folgenden Fehlermeldungen im Log:

Error: 100 SuspendEscalatedTickets iterations for Ticket with TicketID 'XXX', Calendar 'X', UpdateDiffTime 'XXX', DestinationTime 'XXX'.

Um diesen vorzubeugen, kann das Limit von 500 Iterationen über die SysConfig-Option 'EscalationSuspendLoopProtection' je nach Bedarfsfall erhöht werden. Hierbei sind jedoch die Auswirkungen auf die Performance zu beobachten.

![SuspendEscalatedTickets](doc/de/images/EscalationSuspendLoopProtection.png)

## Eskalations-Benachrichtigung trotz "pending"-Status
Wird der Status auf pending gesetzt, nachdem das Ticket bereits eskaliert ist, werden in OTRS weiterhin Benachrichtigungen versendet. Dies kann durch folgende Einstellung in der SysConfig abgeschaltet werden:
'SuspendEscalatedTickets' auf 'ja' setzen.

![SuspendEscalatedTickets](doc/de/images/SuspendEscalatedTickets.png)

## Eskalationen anhalten
Abschalten der gesamten Eskalation, wenn ein Ticket in einem konfigurierten Status zum Anhalten der Eskalationen verweilt. Am Ticket werden keine Eskalationswerte mehr angezeigt. Das Ticket taucht auch nicht in der Übersicht der eskallierten Tickets auf.

![SuspendEscalatedTickets](doc/de/images/EscalationSuspendCancelEscalation.png)
