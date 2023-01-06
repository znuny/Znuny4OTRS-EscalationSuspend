# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_ZnunyEscalationSuspend;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'List of states for which escalations should be suspended.'} = 'Liste von Status, für die Eskalationen angehalten werden sollen.';
    $Self->{Translation}->{'Escalation view - Without Suspend State'}                   = 'Ansicht nach Eskalationen ohne ausg. Status';
    $Self->{Translation}->{'Overview Escalated Tickets Without Suspend State'}          = 'Übersicht über eskalierte Tickets ohne ausgesetzte Status';
    $Self->{Translation}->{'Suspend already escalated tickets.'}                        = 'Aussetzen von bereits eskalierten Tickets.';
    $Self->{Translation}->{'Ticket Escalation View Without Suspend State'}              = 'Ansicht nach Ticket-Eskalationen ohne ausgesetzte Status';
    $Self->{Translation}->{'Cancel whole escalation if ticket is in configured suspend state (EscalationSuspendStates). Ticket will not escalate at all in configured suspend state. No escalation times are shown. Ticket will not be shown in escalation view.'} = 'Abschalten der gesamten Eskalation, wenn ein Ticket in einem konfigurierten Status zum Anhalten der Eskalationen verweilt. Am Ticket werden keine Eskalationswerte mehr angezeigt. Das Ticket taucht auch nicht in der Übersicht der eskallierten Tickets auf.';
    $Self->{Translation}->{'Maximum number of iterations for calculating the WorkingTime for a ticket. Attention: Setting this too high can lead to performance issues.'} = 'Maximale Anzahl von Iterationen zur Berechnung der Arbeitszeit eines Tickets. Achtung: Wird der Wert zu hoch gesetzt, kann es zu negativen Auswirkungen auf die Performance kommen.';
    $Self->{Translation}->{'Overloads (redefines) existing functions in Kernel::System::Ticket. Used to easily add customizations.'}
        = 'Überschreibt existierende Funktionen aus Kernel::System::Ticket.';
    $Self->{Translation}->{'Rebuilds the escalation index.'} = 'Erneuert den Eskalationsindex.';

    return 1;
}

1;
