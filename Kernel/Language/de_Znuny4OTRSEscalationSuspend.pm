# --
# Kernel/Language/de_OTRSEscalationSuspend.pm - provides xx Kernel/Modules/*.pm module language translation
# Copyright (C) 2003-2012 OTRS AG, http://otrs.com/
# Copyright (C) 2013 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.
# --

package Kernel::Language::de_OTRSEscalationSuspend;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.6 $) [1];

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
