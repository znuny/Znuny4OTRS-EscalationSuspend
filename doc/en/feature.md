# Suspend the escalation on specific ticket states

You are now able to pause the escalation of a ticket. To achieve this you just need to configure the states via SysConfig which fits to your situation/workflow.

A typical use case is to suspend the escalation as long as you wait for a customer reply. Configure 'pending reminder' as the suspend state and you're done!
To configure the state you need to Admin -> SysConfig -> Znuny4OTRS-EscalationSuspend -> EscalationSuspend. After the installation the states 'pending auto close+', 'pending auto close-' and 'pending reminder' are configured by default.

![SuspendEscalatedTickets](doc/en/images/EscalationSuspendStates.png)

Example:

  * 08:00 am - A ticket is created. The solution time will be 2 hours. 10 am is shown as the calculated escalation time.
  * 09:00 am - The agent sets the state "pending reminder" becase he didn't catched the customer. An escalation time of 10 am is shown.
  * 09:30 am - The ticket stays 30 minutes in the state "pending reminder". The calculated escalation time is 10:30 am.
  * 10:00 am - The ticket stays 60 minutes in the state "pending reminder". The calculated escalation time is 11:00 am.
  * 10:05 am - An e-mail reply by the customer changed the ticket into the state "open". The new escalation time will be 11:05 am.
  * 10:30 am - The escalation time is still 11:05 am.
  * 11:00 am - The escalation time is still 11:05 am.
  * 11:05 am - The escalation occurs.

## SysConfig

SysConfig (Group: Znuny4OTRS-EscalationSuspend -> SupGroup: EscalationSuspend)


#### Suspend escalated Tickets

If the status is set to pending after the ticket has already escalated, notifications are still sent in the default. This can be disabled by the following setting in the SysConfig:

-> SuspendEscalatedTickets to 'yes'

![SuspendEscalatedTickets](doc/en/images/SuspendEscalatedTickets.png)


#### Cancel Escalation

Cancel whole escalation if ticket is in configured suspend state (EscalationSuspendStates). Ticket will not escalate at all in configured suspend state. No escalation times are shown. Ticket will not be shown in escalation view.

![SuspendEscalatedTickets](doc/en/images/EscalationSuspendCancelEscalation.png)
