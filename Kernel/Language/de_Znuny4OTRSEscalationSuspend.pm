# --
# Kernel/Language/de_Znuny4OTRSEscalationSuspend.pm - the german translation of the texts of Znuny4OTRSEscalationSuspend
# Copyright (C) 2015 Znuny GmbH, http://znuny.com/
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

    return 1;
}

1;
