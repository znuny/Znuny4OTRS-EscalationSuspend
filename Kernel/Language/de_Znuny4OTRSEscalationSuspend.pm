# --
# Copyright (C) 2012-2020 Znuny GmbH, http://znuny.com/
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
    $Self->{Translation}->{'This configuration defines the number of iterations that should be performed at max for calculating the WorkingTime for a Ticket. Attention: Setting this configuration to high can lead to performance issues.'} = 'Diese Konfiguration definiert die Anzahl von Iterationen, die durchgeführt werden sollen um die Arbeitszeit eines Tickets zu errechnen. Achtung: Ist diese Konfiguration auf einen zu hohen Wert gesetzt, kann es zu negativen Auswirkungen auf die Performance kommen.';
    $Self->{Translation}->{'Overloads (redefines) existing functions in Kernel::System::Ticket. Used to easily add customizations.'}
        = 'Überlädt existierende Funktionen aus Kernel::System::Ticket.';
    $Self->{Translation}->{'Rebuilds the escalation index.'} = 'Erneuert den Eskalationsindex.';

    return 1;
}

1;
