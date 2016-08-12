# Suspend the escalation on specific ticket states

You are now able to pause the escalation of a ticket. To achieve this you just need to configure the states via SysConfig which fits to your situation/workflow.

Don't forget to add the needed entry into the crontab of the OTRS user..
This is the expected entry:

```
# every 4 min
*/4 * * * * $HOME/bin/znuny.RebuildEscalationIndexOnline.pl >> /dev/null
```

If you don't modified the crontab manually just run as the OTRS user "bin/Cron.sh start".

A typical use case is to suspend the escalation as long as you wait for a customer reply. Configure 'pending reminder' as the suspend state and you're done!
To configure the state you need to to Admin -> SysConfig -> Znuny4OTRS-EscalationSuspend -> EscalationSuspend. After the installation the states 'pending auto close+', 'pending auto close-' and 'pending reminder' are configured by default.

Example:

  * 08:00am - A ticket is created. The solution time will be 2 hours. 10am is shown a the calculated escalation time.
  * 09:00am - The agent sets the state "pending reminder" becase he didn't catched the customer. An escalation time of 10am is shown.
  * 09:30am - The ticket stays 30 minutes in the state "pending reminder". The calculated escalation time is 10:30am.
  * 10:00am - The ticket stays 60 minutes in the state "pending reminder". The calculated escalation time is 11:00am.
  * 10:05am - An e-mail reply by the customer changed the ticket into the state "open". The new escalation time will be 11:05am.
  * 10:30am - The escalation time is still 11:05am.
  * 11:00am - The escalation time is still 11:05am.
  * 11:05am - The escalation occurs.

## Performance information

Your calendar settings, workdays and configured holidyas are possibilities to have an impact on the performance of OTRS.
To keep the negative impact low there is a limit on the calculation cycles which is set to 500 by default. For over 95% of the existing systems this limit will never be reached. In the rare event that this happen this message will occur in your OTRS log:

Error: 500 SuspendEscalatedTickets iterations for Ticket with TicketID 'XXX', Calendar 'X', UpdateDiffTime 'XXX', DestinationTime 'XXX'.

In this case you should increase the limit by changing the SysConfig 'EscalationSuspendLoopProtection'. But keep an eye on the performance of your system.