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
    };

    return 1;
}

1;
