# --
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Znuny::RebuildEscalationIndexOnline;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::System::Log',
    'Kernel::System::Ticket',
);

sub Configure {
    my ( $Self, %Param ) = @_;
    my $Description = "RebuildEscalationIndexOnline - Rebuild Escalation Index\n";
    $Description .= "Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/";

    $Self->Description($Description);

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("\nRebuildEscalationIndexOnline\n");
    $Self->Print("\nCopyright (C) 2012-2016 Znuny GmbH, http://znuny.com/\n");
    $Self->Print("<yellow>Rebuilding escalation index...</yellow>\n\n");

    # get all tickets
    my @TicketIDs = $Kernel::OM->Get('Kernel::System::Ticket')->TicketSearch(

        # result (required)
        Result => 'ARRAY',

        States => $Kernel::OM->Get('Kernel::Config')->Get('EscalationSuspendStates'),

        # result limit
        Limit      => 100_000_000,
        UserID     => 1,
        Permission => 'ro',
    );

    my $Count = 0;
    for my $TicketID (@TicketIDs) {
        $Count++;
        $Kernel::OM->Get('Kernel::System::Ticket')->TicketEscalationIndexBuild(
            TicketID => $TicketID,
            Suspend  => 1,
            UserID   => 1,
        );
        if ( ( $Count / 2000 ) == int( $Count / 2000 ) ) {
            my $Percent = int( $Count / ( $#TicketIDs / 100 ) );
            print "<yellow>  $Count of $#TicketIDs processed ($Percent% done).</yellow>\n";
        }
    }

    $Self->Print("\n<green>Done (Escalation index rebuilt).</green>\n");

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
