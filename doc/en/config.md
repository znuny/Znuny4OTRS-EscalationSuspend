# Configuration

## Performance information
Your calendar settings, workdays and configured holidays have an impact on the performance of OTRS.
To keep the negative impact low there is a limit on the calculation cycles which is set to 500 by default. For over 95% of the existing systems this limit will never be reached. In the rare event that this happens the following message will occur in your OTRS log:

Error: 500 SuspendEscalatedTickets iterations for Ticket with TicketID 'XXX', Calendar 'X', UpdateDiffTime 'XXX', DestinationTime 'XXX'.

In this case you should increase the limit by changing the SysConfig option 'EscalationSuspendLoopProtection'. But keep an eye on the performance of your system.

![SuspendEscalatedTickets](doc/en/images/EscalationSuspendLoopProtection.png)

## Suspending escalated tickets
If the status is set to pending after the ticket has already escalated, notifications will still be sent. This can be disabled by the following setting in the SysConfig:
Set 'SuspendEscalatedTickets' to 'yes'.

![SuspendEscalatedTickets](doc/en/images/SuspendEscalatedTickets.png)

## Cancelling escalations
Cancel the whole escalation if a ticket is in a configured suspend state (EscalationSuspendStates). The ticket will not escalate at all in the configured suspend state. No escalation times are shown. The ticket will not be shown in escalation view.

![SuspendEscalatedTickets](doc/en/images/EscalationSuspendCancelEscalation.png)
