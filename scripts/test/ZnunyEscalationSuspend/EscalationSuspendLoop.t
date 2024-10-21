# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
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
my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');

# Disable transaction mode for escalation index ticket event module
my $TicketEventModulePostConfig = $ConfigObject->Get('Ticket::EventModulePost');
my $EscalationIndexName         = '9990-EscalationIndex';

$Self->True(
    $TicketEventModulePostConfig->{$EscalationIndexName},
    "Ticket::EventModulePost $EscalationIndexName exists",
);

$TicketEventModulePostConfig->{$EscalationIndexName}->{Transaction} = 0;
$ConfigObject->Set(
    Key   => 'Ticket::EventModulePost',
    Value => $TicketEventModulePostConfig,
);

$TicketEventModulePostConfig = $ConfigObject->Get('Ticket::EventModulePost');

$Self->IsDeeply(
    $TicketEventModulePostConfig->{$EscalationIndexName},
    {
        'Transaction' => 0,
        'Event' =>
            '\\A(TicketSLAUpdate|TicketQueueUpdate|TicketStateUpdate|TicketCreate|ArticleCreate|TicketDynamicFieldUpdate_.+|TicketTypeUpdate|TicketServiceUpdate|TicketCustomerUpdate|TicketPriorityUpdate|TicketMerge)\\z',
        'Module' => 'Kernel::System::Ticket::Event::TicketEscalationIndex'
    },
    "Disable transaction mode for $EscalationIndexName Ticket::EventModulePost",
);

my $RandomID = $HelperObject->GetRandomID();

my $QueueID = $QueueObject->QueueAdd(
    Name              => 'UnitTest' . $RandomID,
    ValidID           => 1,
    GroupID           => 1,
    FirstResponseTime => 4 * 60,                   # 4h
    UpdateTime        => 0,
    SolutionTime      => 24 * 60,                  # 24h
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
        'Mon' => [ 8 .. 18 ],    # 11 h
        'Tue' => [ 8 .. 18 ],
        'Wed' => [ 8 .. 18 ],
        'Thu' => [ 8 .. 18 ],
        'Fri' => [ 8 .. 15 ],    # 8 h
        'Sat' => [],
        'Sun' => [],
    },
);

# Ticket creation
# solution time is then 2016-04-14 18:50:08
$HelperObject->FixedTimeSetByTimeStamp('2016-04-12 16:50:08');    # Tuesday
my $TicketID = $HelperObject->TicketCreate(
    QueueID => $QueueID,
);

# Set pending reminder
# TicketEscalationSuspendCalculate will add 4 minutes to prevent escalation
# pending reminder is configured as suspend state
# solution time is then 2016-04-14 18:54:08
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
# This leads to +3:09 minutes because 16:52:53 from above + 4 minutes (see above)
# = 16:56:53 and 17:00:02 - 16:56:53 = 3:09
# open is not configured as suspend state, meaning, the new solution time
# solution time is then 2016-04-14 18:57:17
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
# this adds another 4 minutes to the solution time
# new solution time: 2016-04-15 08:01:17
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

# Solution time is 2016-04-15 08:01:17
my $SolutionTime = $TimeObject->TimeStamp2SystemTime( String => '2016-04-15 08:01:17' );

$Self->Is(
    $Ticket{SolutionTimeDestinationTime},
    $SolutionTime,
    'SolutionTimeDestinationTime calculated correctly'
);

$HelperObject->FixedTimeUnset();

1;
