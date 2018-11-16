# --
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
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
        RestoreSystemConfiguration => 1,
        RestoreDatabase            => 1,
    },
);

# get needed objects
my $HelperObject = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');

my $RandomID = $HelperObject->GetRandomID();

my $QueueID = $QueueObject->QueueAdd(
    Name              => 'UnitTest' . $RandomID,
    ValidID           => 1,
    GroupID           => 1,
    FirstResponseTime => 240,
    UpdateTime        => 0,
    SolutionTime      => 1440,
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
        'Wed' => [
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '16',
            '17',
            '18',
        ],
        'Thu' => [
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '16',
            '17',
            '18',
        ],
        'Tue' => [
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '16',
            '17',
            '18',
        ],
        'Mon' => [
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            '16',
            '17',
            '18',
        ],
        'Sun' => [],
        'Sat' => [],
        'Fri' => [
            '8',
            '9',
            '10',
            '11',
            '12',
            '13',
            '14',
            '15',
            ]
        }
);

my $TicketCreateTime = $TimeObject->TimeStamp2SystemTime(
    String => '2016-04-12 16:50:08',
);

$HelperObject->FixedTimeSet($TicketCreateTime);

my $TicketID = $HelperObject->TicketCreate(
    QueueID => $QueueID,
);

my $PendingStateTime = $TimeObject->TimeStamp2SystemTime(
    String => '2016-04-12 16:52:53',
);

$HelperObject->FixedTimeSet($PendingStateTime);

$TicketObject->TicketStateSet(
    State    => 'pending reminder',
    TicketID => $TicketID,
    UserID   => 1,
);

$TicketObject->TicketPendingTimeSet(
    String   => '2016-04-15 16:52:00',
    TicketID => $TicketID,
    UserID   => 1,
);

my $OpenStateTime = $TimeObject->TimeStamp2SystemTime(
    String => '2016-04-12 17:00:02',
);

$HelperObject->FixedTimeSet($OpenStateTime);

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

my $SendAnswerTime = $TimeObject->TimeStamp2SystemTime(
    String => '2016-05-31 08:37:10',
);

$HelperObject->FixedTimeSet($SendAnswerTime);

$TicketObject->TicketStateSet(
    State    => 'pending reminder',
    TicketID => $TicketID,
    UserID   => 1,
);

$TicketObject->TicketPendingTimeSet(
    String   => '2016-06-19 08:34:00',
    TicketID => $TicketID,
    UserID   => 1,
);

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
    1460700077,
    'SolutionTimeDestinationTime calculated correctly'
);

$HelperObject->FixedTimeUnset();

1;
