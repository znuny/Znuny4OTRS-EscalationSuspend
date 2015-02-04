#!/usr/bin/perl -w
# --
# znuny.RebuildEscalationIndexOnline.pl - rebuild escalation index
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);
use lib dirname($RealBin) . "/Kernel/cpan-lib";

use Getopt::Std;
use Kernel::Config;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::Encode;
use Kernel::System::DB;
use Kernel::System::Main;
use Kernel::System::Ticket;
use Kernel::System::ObjectManager;
use Kernel::System::Time;

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
    print "Copyright (C) 2015 Znuny GmbH, http://znuny.com/\n";
    print "usage: znuny.RebuildEscalationIndexOnline.pl\n";
    exit 1;
}

# create common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = $Kernel::OM->Get('Kernel::Config');
$CommonObject{LogObject}    = $Kernel::OM->Get('Kernel::System::Log');

$CommonObject{MainObject}   = $Kernel::OM->Get('Kernel::System::Main');
$CommonObject{EncodeObject} = $Kernel::OM->Get('Kernel::System::Encode');
$CommonObject{TimeObject}   = $Kernel::OM->Get('Kernel::System::Time');
$CommonObject{TimeObject2}   = Kernel::System::Time->new( %CommonObject,TimeZone => -24*365);

# create needed objects
$CommonObject{DBObject}     = $Kernel::OM->Get('Kernel::System::DB');
$CommonObject{TicketObject} = $Kernel::OM->Get('Kernel::System::Ticket');

# get all tickets
my @TicketIDs = $CommonObject{TicketObject}->TicketSearch(

    # result (required)
    Result => 'ARRAY',

    States => $CommonObject{ConfigObject}->Get('EscalationSuspendStates'),

    # result limit
    Limit      => 100_000_000,
    UserID     => 1,
    Permission => 'ro',
);

my $Count = 0;
for my $TicketID (@TicketIDs) {
    $Count++;
    $CommonObject{TicketObject}->TicketEscalationIndexBuild(
        TicketID => $TicketID,
        UserID   => 1,
    );
    if ( ( $Count / 2000 ) == int( $Count / 2000 ) ) {
        my $Percent = int( $Count / ( $#TicketIDs / 100 ) );
        print "NOTICE: $Count of $#TicketIDs processed ($Percent% done).\n";
    }
}
