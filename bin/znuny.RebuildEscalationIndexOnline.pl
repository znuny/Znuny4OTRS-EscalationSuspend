#!/usr/bin/perl
# --
# Copyright (C) 2001-2017 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --
## nofilter(TidyAll::Plugin::OTRS::Legal::OTRSAGCopyright)
## nofilter(TidyAll::Plugin::OTRS::Legal::AGPLValidator)

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . "/Kernel/cpan-lib";

use Getopt::Std;
use Kernel::System::ObjectManager;
use Kernel::System::VariableCheck qw(:all);

# create common objects
local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'OTRS-znuny.RebuildEscalationIndexOnline.pl',
    },
);

# get options
my %Opts = ();
getopt( 'h', \%Opts );
if ( $Opts{h} ) {
    print "znuny.RebuildEscalationIndexOnline.pl - rebuild escalation index\n";
    print "Copyright (C) 2001-2017 OTRS AG, http://otrs.com/\n";
    print "Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/\n";
    print "usage: znuny.RebuildEscalationIndexOnline.pl\n";
    exit 1;
}

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
        print "NOTICE: $Count of $#TicketIDs processed ($Percent% done).\n";
    }
}
