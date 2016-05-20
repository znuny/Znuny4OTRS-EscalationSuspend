# --
# Kernel/Language/de_Znuny4OTRSEscalationSuspend.pm - the german translation of the texts of Znuny4OTRSEscalationSuspend
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_Znuny4OTRSEscalationSuspend;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'List of states for which escalations should be suspended.'} = 'Liste von Status, für welche Eskalationen angehalten werden sollen.';
    $Self->{Translation}->{'Escalation view - Without Suspend State'}                   = 'Ansicht nach Eskalationen ohne ausg. Status';
    $Self->{Translation}->{'Overview Escalated Tickets Without Suspend State'}          = 'Übersicht über eskalierte Tickets ohne ausgesetzte Status';
    $Self->{Translation}->{'Suspend already escalated tickets.'}                        = 'Aussetzen von bereits eskalierten Tickets.';
    $Self->{Translation}->{'Ticket Escalation View Without Suspend State'}              = 'Ansicht nach Ticket-Eskalationen ohne ausgesetzte Status';
    $Self->{Translation}->{'Cancel whole escalation if ticket is in configured suspend state (EscalationSuspendStates). Ticket will not escalate at all in configured suspend state. No escalation times are shown. Ticket will not be shown in escalation view.'} = 'Abschalten der gesamten Eskalation wenn ein Ticket in einem konfigurierten Status zum anhalten der Eskalationen verweilt. Am Ticket werden keine Eskalationswerte mehr angezeigt. Das Ticket taucht auch nicht in der Übersicht der eskallierten Tickets auf.';

    return 1;
}

1;
