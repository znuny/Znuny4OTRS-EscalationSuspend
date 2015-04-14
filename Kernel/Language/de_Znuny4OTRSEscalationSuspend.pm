# --
# Kernel/Language/de_Znuny4OTRSEscalationSuspend.pm - provides xx Kernel/Modules/*.pm module language translation
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

package Kernel::Language::de_Znuny4OTRSEscalationSuspend;

use strict;
use warnings;

sub Data {
    my $Self = shift;

    $Self->{Translation} = {
        %{$Self->{Translation}},
        'List of states for which escalations should be suspended.' => 'Liste von Status, für welche Eskalationen angehalten werden sollen.',
        'Escalation view - Without Suspend State' => 'Ansicht nach Eskalationen ohne ausg. Status',
        'Overview Escalated Tickets Without Suspend State' => 'Übersicht über eskalierte Tickets ohne ausgesetzte Status',
        'Suspend already escalated tickets.' => 'Aussetzen von bereits eskalierten Tickets.',
        'Ticket Escalation View Without Suspend State' => 'Ansicht nach Ticket-Eskalationen ohne ausgesetzte Status',
        'Cancel whole escalation if ticket is in configured suspend state (EscalationSuspendStates). Ticket will not escalate at all in configured suspend state. No escalation times are shown. Ticket will not be shown in escalation view.' => 'Abschalten der gesamten Eskalation wenn ein Ticket in einem konfigurierten Status zum anhalten der Eskalationen verweilt. Am Ticket werden keine Eskalationswerte mehr angezeigt. Das Ticket taucht auch nicht in der Übersicht der eskallierten Tickets auf.',
    };

    return 1;
}

1;
