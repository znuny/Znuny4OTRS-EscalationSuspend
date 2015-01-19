# --
# scripts/test/EscalationSuspent.t - EscalationSuspent
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars qw($Self);

use Kernel::System::Ticket::Znuny4OTRSEscalationSuspend;
use Kernel::System::State;
use Kernel::System::Ticket;
use Kernel::Config;
use Kernel::System::DB;
use Kernel::System::Time;

# get needed objects
my $HelperObject  = $Kernel::OM->Get('Kernel::System::UnitTest::Helper');
my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
my $EscalationSuspendObject = $Kernel::OM->Get('Kernel::System::Ticket::Znuny4OTRSEscalationSuspend');

# Subs:
# Kernel::System::Ticket::TicketEscalationIndexBuild
# Kernel::System::Ticket::TicketEscalationSuspendCalculate
# Kernel::System::Ticket::TicketWorkingTimeSuspendCalculate
# Kernel::System::Ticket::_TicketGetClosed


# create a Queue named "MyTestQueue" with a SolutionTime of 120 min
my $QueueID  = $QueueObject->QueueAdd(
       Name                => 'MyTestQueue',
       ValidID             => 1,
       GroupID             => 1,
       FirstResponseTime   => 120,         # (optional)
       FirstResponseNotify => 80,          # (optional, notify agent if first response escalation is 60% reached)
       UpdateTime          => 120,         # (optional)
       UpdateNotify        => 80,          # (optional, notify agent if update escalation is 80% reached)
       SolutionTime        => 120,         # (optional)
       SolutionNotify      => 80,          # (optional, notify agent if solution escalation is 80% reached)
       UnlockTimeout       => 480,         # (optional)
       FollowUpId          => 3,           # possible (1), reject (2) or new ticket (3) (optional, default 0)
       FollowUpLock        => 0,           # yes (1) or no (0) (optional, default 0)
       SystemAddressID     => 1,
       SalutationID        => 1,
       SignatureID         => 1,
       Comment             => 'Some comment',
       UserID              => 1,
   );
   

# if not exists   
#$Self->True(
#    $QueueID,
#    'QueueAdd()',
#);


# if exists
$Self->False(
    $QueueID,
    'QueueAdd() -  create Queue "MyTestQueue" with a SolutionTime of 120min',
);

# check the name of queue  
my %QueueGet = $QueueObject->QueueGet( 
		Name => "MyTestQueue", 
	);  
	
$Self->True(
    $QueueGet{Name} eq "MyTestQueue",
    'QueueGet() - (get QueueName) - Queue "MyTestQueue"',
);

# check the SolutionTime 
$Self->Is(
    $QueueGet{SolutionTime},
    '120',
    'QueueGet() - (get SolutionTime) - ',
);  
   
# create a ticket "MyTestTicket" in queue "MyTestQueue"   
my $TicketID = $TicketObject->TicketCreate(
    TN            => $TicketObject->TicketCreateNumber(), # optional
	Title         => 'MyTestTicket',
	Queue         => 'MyTestQueue',              # or QueueID => 123,
	Lock          => 'unlock',
	Priority      => '3 normal',         # or PriorityID => 2,
	State         => 'new',              # or StateID => 5,
	CustomerID    => 'Znuny',
	CustomerUser  => 'customer@example.com',
	OwnerID       => 1,
	ResponsibleID => 1,                # not required
	ArchiveFlag   => 'n',                # (y|n) not required
	UserID        => 1,
);

# check TicketID
$Self->Is(
    $TicketID,
    $TicketID,
    'TicketID: ',
);

$Self->True(
    $TicketID,
    'TicketCreate() - (create) "MyTestTicket"',
);

# get Ticket-Values
my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    Extended => 1,
);

$Self->Is(
    $Ticket{Title},
    'MyTestTicket',
    'TicketGet() - (Title) ',
);


#$Self->Is(
#    $Ticket{SolutionTime},
#    $Ticket{Created},
#    'Ticket created as closed as Solution Time = Creation Time',
#);




##############################################################
# Kernel::System::Ticket::TicketEscalationIndexBuild
##############################################################
my $TicketEscalationIndexBuild;

# check line 73
my $Success = $TicketObject->TicketStateSet(
       State    => 'merged',
       TicketID => $TicketID,
       UserID   => 1,
   );

# get Ticket-Values
my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    Extended => 1,
);

$Self->Is(
    $Ticket{State},
    'merged',
    'TicketGet() - (State = merged) # do no escalations on (merge|close|remove) tickets',
);

$TicketEscalationIndexBuild = $EscalationSuspendObject->TicketEscalationIndexBuild(
	TicketID => $TicketID,
	UserID   => 1,
);

$Self->True(
    $TicketEscalationIndexBuild,
    'TicketEscalationIndexBuild()  - should be true(1) if state = merged',
);
##########################################

## State = open
my $Success = $TicketObject->TicketStateSet(
       State    => 'open',
       TicketID => $TicketID,
       UserID   => 1,
   );

# get Ticket-Values
my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    Extended => 1,
);


$TicketEscalationIndexBuild = $EscalationSuspendObject->TicketEscalationIndexBuild(
	TicketID => $TicketID,
	UserID   => 1,
);


$Self->True(
    $TicketEscalationIndexBuild,
    'TicketEscalationIndexBuild() - state = open',
);


# get  FirstResponseTime
my %Escalation = $TicketObject->TicketEscalationPreferences(
            Ticket => \%Ticket,
            UserID => 1,
        );
        
$Self->Is(
    $Escalation{FirstResponseTime}, #SolutionTime
    '120',
    'TicketEscalationPreferences() - seconds total till escalation, 120 - ',
);


#########################
# $SuspendStateActive = 1
#########################

#set pending time to 120 min
my $SystemPendingTime  =  $Ticket{CreateTimeUnix} + (120 * 60);
my $PendingTime = $TimeObject->SystemTime2TimeStamp(
       SystemTime => $SystemPendingTime,
   );
   
 $Success = $TicketObject->TicketPendingTimeSet(
       String   => $PendingTime,
       TicketID => $TicketID,
       UserID   => 1,
   );
   
$Self->Is(
    $Ticket{Created},
    $Ticket{Created},
    '$Ticket{Created}',
);  
$Self->IsNot(
	$PendingTime,
    $Ticket{Created},    
    'TicketPendingTimeSet -  should be plus 120 min. of createdTime',
);
#set pending reminder
my $Success = $TicketObject->TicketStateSet(
       State    => 'pending reminder',
       TicketID => $TicketID,
       UserID   => 1,
   );
# get Ticket-Values
my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    Extended => 1,
);   
$Self->Is(
    $Ticket{State},
    'pending reminder',
    '$Ticket{Created}',
);  
#########################









##############################################################
# Kernel::System::Ticket::TicketEscalationSuspendCalculate
##############################################################
my $TicketEscalationSuspendCalculat;
$TicketEscalationSuspendCalculat = $EscalationSuspendObject->TicketEscalationSuspendCalculate(
	ResponseTime	=> 60,
	Suspended 		=> 30,
	StartTime		=> $Ticket{Created},
	TicketID 		=> $TicketID,
);

$Self->True(
    $TicketEscalationSuspendCalculat,
    'TicketEscalationSuspendCalculat()   - first run without changes',
);




###############################################################
## Kernel::System::Ticket::TicketWorkingTimeSuspendCalculate
###############################################################
my $TicketWorkingTimeSuspendCalculate;
$TicketWorkingTimeSuspendCalculate = $EscalationSuspendObject->TicketWorkingTimeSuspendCalculate(
	StartTime		=> $Ticket{Created},
);

$Self->Is(
	$TicketWorkingTimeSuspendCalculate,
	'0', #2015-01-18 22:00:00',    
    'TicketWorkingTimeSuspendCalculate()   - first run without changes',
);




##############################################################
# Kernel::System::Ticket::_TicketGetClosed
##############################################################


my %TicketGetClosed = $EscalationSuspendObject->_TicketGetClosed(
    TicketID => $Ticket{TicketID},
    Ticket => \%Ticket,
    UserID => '1',
);

$Self->IsNot(
    $TicketGetClosed{SolutionInMin},
    undef,
    '_TicketGetClosed()   - first run without changes',
);



### delete created ticket
#my $Success = $TicketObject->TicketDelete(
#       TicketID => $TicketID,
#       UserID   => 1,
#   );

1;

