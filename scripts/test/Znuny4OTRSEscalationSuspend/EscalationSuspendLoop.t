# --
# Copyright (C) 2012-2017 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));
use Kernel::System::VariableCheck qw(:all);

$Kernel::OM->ObjectParamAdd(
    'Kernel::System::UnitTest::Helper' => {
        RestoreDatabase => 1,
    },
);

my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
my $TimeObject   = $Kernel::OM->Get('Kernel::System::ZnunyTime');

# Disable transaction mode for escalation index ticket event module
my $TicketEventModulePostConfig = $ConfigObject->Get('Ticket::EventModulePost');
$TicketEventModulePostConfig->{'6000-EscalationIndex'}->{Transaction} = 0;
$ConfigObject->Set(
    Key   => 'Ticket::EventModulePost',
    Value => $TicketEventModulePostConfig,
);

my $RandomID = $HelperObject->GetRandomID();

my $QueueID = $QueueObject->QueueAdd(
    Name              => 'UnitTest' . $RandomID,
    ValidID           => 1,
    GroupID           => 1,
    FirstResponseTime => 240,                      # 4h
    UpdateTime        => 0,
    SolutionTime      => 1440,                     # 24h
    UnlockTimeout     => 0,
    FollowUpId        => 1,
    FollowUpLock      => 1,
    SystemAddressID   => 1,
    SalutationID      => 1,
    SignatureID       => 1,
    Comment           => 'UnitTest' . $RandomID,
    UserID            => 1,
);

$ConfigObject->Set(
    Key   => 'TimeWorkingHours',
    Value => {
        'Mon' => [ 8 .. 18 ],
        'Tue' => [ 8 .. 18 ],
        'Wed' => [ 8 .. 18 ],
        'Thu' => [ 8 .. 18 ],
        'Fri' => [ 8 .. 15 ],
        'Sat' => [],
        'Sun' => [],
    },
);

# Ticket creation
$HelperObject->FixedTimeSetByTimeStamp('2016-04-12 16:50:08');    # Tuesday
my $TicketID = $HelperObject->TicketCreate(
    QueueID => $QueueID,
);

# Set pending reminder
$HelperObject->FixedTimeSetByTimeStamp('2016-04-12 16:52:53');    # Tuesday
$TicketObject->TicketStateSet(
    State    => 'pending reminder',
    TicketID => $TicketID,
    UserID   => 1,
);
$TicketObject->TicketPendingTimeSet(
    String   => '2016-04-15 16:52:00',                            # Friday
    TicketID => $TicketID,
    UserID   => 1,
);

# Set status "open"
$HelperObject->FixedTimeSetByTimeStamp('2016-04-12 17:00:02');    # Tuesday
$TicketObject->TicketStateSet(
    State    => 'open',
    TicketID => $TicketID,
    UserID   => 1,
);
$TicketObject->TicketPendingTimeSet(
    String   => '0000-00-00 00:00:00',
    TicketID => $TicketID,
    UserID   => 1,
);

# Set pending reminder
$HelperObject->FixedTimeSetByTimeStamp('2016-05-31 08:37:10');    # Tuesday
$TicketObject->TicketStateSet(
    State    => 'pending reminder',
    TicketID => $TicketID,
    UserID   => 1,
);
$TicketObject->TicketPendingTimeSet(
    String   => '2016-06-19 08:34:00',                            # Sunday
    TicketID => $TicketID,
    UserID   => 1,
);

# Rebuild escalation index and test result
$TicketObject->TicketEscalationIndexBuild(
    TicketID => $TicketID,
    Suspend  => 1,
    UserID   => 1,
);

my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    UserID   => 1,
);

$Self->Is(
    $Ticket{SolutionTimeDestinationTime},
    1460700077,    # UTC 15.04.2016 06:01:17
    'SolutionTimeDestinationTime calculated correctly'
);

$HelperObject->FixedTimeUnset();

1;
