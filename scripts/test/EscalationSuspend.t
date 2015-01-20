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


# Var
my $mySolutionTime = 120;
my $myQueueName = "MyTestQueue";
my $myTicketName = "MyTestTicket";
my $QueueID;



##############################################################
# create a queue for testing
##############################################################

# check if Queue $myTicketName exists
my %QueueGet = $QueueObject->QueueGet( 
		Name => $myQueueName, 
	); 	

# QueueID of  $myQueueName is...	
$QueueID = $QueueGet{QueueID};	
	
# if Queue exsists	   
if ($QueueID){	
	
	$Self->Is(
	    $QueueGet{Name},
	    $myQueueName,
	    "QueueGet() - Queuename",
	);
	$Self->Is(
	    $QueueID,
	    $QueueID,
	    "QueueGet() - QueueID of  $myQueueName - ",
	); 
	
	# check the SolutionTime 
	$Self->Is(
	    $QueueGet{SolutionTime},
	    '120',
	    'QueueGet() - SolutionTime - ',
	); 
}
else
{
# create a Queue named "MyTestQueue" with a SolutionTime of 120 min
$QueueID  = $QueueObject->QueueAdd(
       Name                => $myQueueName,
       ValidID             => 1,
       GroupID             => 1,
       FirstResponseTime   => $mySolutionTime,         # (optional)
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
  
	$Self->True(
	    $QueueID,
	    "QueueAdd() -  create Queue ($QueueID) $myQueueName with a SolutionTime of $mySolutionTime min",
	);
}


##############################################################
# create a ticket for testing
##############################################################

my $myTicketNr ="201501101000001";
my $TicketID = $TicketObject->TicketCheckNumber(
       Tn => $myTicketNr,
   );
   
if (!$TicketID)  { 

	# create a ticket "$myTicketName" in queue "$myQueueName"   
	$TicketID = $TicketObject->TicketCreate(
	    TN            => $myTicketNr, # $TicketObject->TicketCreateNumber(), # optional
		Title         => $myTicketName,
		Queue         => $myQueueName,              # or QueueID => 123,
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
	
	$Self->True(
	    $TicketID,
	    "TicketCreate() - create test-ticket" ,
	);
}

# check TicketID
	$Self->Is(
	    $TicketID,
	    $TicketID,
	    'TicketID: ',
	);
	
# get Ticket-Values
my %Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    Extended => 1,
);

$Self->Is(
    $Ticket{Title},
    $myTicketName,
    'Ticketname: ',
);



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
%Ticket = $TicketObject->TicketGet(
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
$Success = $TicketObject->TicketStateSet(
       State    => 'open',
       TicketID => $TicketID,
       UserID   => 1,
   );

# get Ticket-Values
%Ticket = $TicketObject->TicketGet(
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

#set pending time to 30 min
my $Pending = 30; #min
my $SystemPendingTime  =  $Ticket{CreateTimeUnix} + ($Pending * 60);
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
    "TicketPendingTimeSet -  should be plus $Pending min. of createdTime",
);
#set pending reminder
 $Success = $TicketObject->TicketStateSet(
       State    => 'pending reminder',
       TicketID => $TicketID,
       UserID   => 1,
   );
# get Ticket-Values
%Ticket = $TicketObject->TicketGet(
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

return 1;

1;

