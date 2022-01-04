# --
# Copyright (C) 2001-2022 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/
# --
# $origin: znuny - 012b2cb0daf8519ff314f751ad03b62219f63331 - Kernel/System/Console/Command/Maint/Ticket/EscalationIndexRebuild.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

# ---
# Znuny-EscalationSuspend
# ---
## nofilter(TidyAll::Plugin::OTRS::Perl::Pod::Validator)
# ---
package Kernel::System::Console::Command::Maint::Ticket::EscalationIndexRebuild;

use strict;
use warnings;

use Time::HiRes();

use parent qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;
# ---
# Znuny-EscalationSuspend
# ---
#     $Self->Description('Completely rebuild the ticket escalation index.');
    my $Description = "RebuildEscalationIndexOnline - Rebuild Escalation Index\n";
    $Description .= "Copyright (C) 2001-2022 OTRS AG, https://otrs.com/";
    $Description .= "Copyright (C) 2012-2022 Znuny GmbH, http://znuny.com/";

    $Self->Description($Description);
# ---
    $Self->AddOption(
        Name        => 'micro-sleep',
        Description => "Specify microseconds to sleep after every ticket to reduce system load (e.g. 1000).",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/^\d+$/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Rebuilding ticket escalation index...</yellow>\n");

    # disable ticket events
    $Kernel::OM->Get('Kernel::Config')->{'Ticket::EventModulePost'} = {};

    # get all tickets
    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(
        Result     => 'ARRAY',
# ---
# Znuny-EscalationSuspend
# ---
        States => $Kernel::OM->Get('Kernel::Config')->Get('EscalationSuspendStates'),
# ---
        Limit      => 100_000_000,
        UserID     => 1,
        Permission => 'ro',
    );

    my $Count      = 0;
    my $MicroSleep = $Self->GetOption('micro-sleep');

    TICKETID:
    for my $TicketID (@TicketIDs) {

        $Count++;

        $Kernel::OM->Get('Kernel::System::Ticket')->TicketEscalationIndexBuild(
            TicketID => $TicketID,
# ---
# Znuny-EscalationSuspend
# ---
            Suspend  => 1,
# ---
            UserID   => 1,
        );

        if ( $Count % 2000 == 0 ) {
            my $Percent = int( $Count / ( $#TicketIDs / 100 ) );
            $Self->Print(
                "<yellow>$Count</yellow> of <yellow>$#TicketIDs</yellow> processed (<yellow>$Percent %</yellow> done).\n"
            );
        }

        Time::HiRes::usleep($MicroSleep) if $MicroSleep;
    }

    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;
