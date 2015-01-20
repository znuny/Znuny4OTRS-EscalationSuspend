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
my $Pending = 5; #min
my $QueueID;
my $Success;
my $TicketEscalationIndexBuild;
my $TicketEscalationSuspendCalculat;
my $TicketWorkingTimeSuspendCalculate;
my %TicketGetClosed;
my $SuspendStateActive;

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
my $ArticleID;
my %Article = $TicketObject->ArticleLastCustomerArticle(
       TicketID => $TicketID,
   );
$ArticleID = $Article{ArticleID};

if (!$Article{ArticleID})  { 
	# we need a article to check SenderType (agent|customer)
	 $ArticleID = $TicketObject->ArticleCreate(
	       TicketID         => $TicketID,
	       ArticleType      => 'note-internal',                        # email-external|email-internal|phone|fax|...
	       SenderType       => 'customer',                                # agent|system|customer
	       From             => 'Some Agent <email@example.com>',       # not required but useful
	       Subject          => 'some short description',               # required
	       Body             => 'the message text',                     # required
	       ContentType      => 'text/plain; charset=ISO-8859-15',      # or optional Charset & MimeType
	       HistoryType      => 'OwnerUpdate',                          # EmailCustomer|Move|AddNote|PriorityUpdate|WebRequestCustomer|...
	       HistoryComment   => 'Some free text!',
	       UserID           => 1,
	       NoAgentNotify    => 0,                                      # if you don't want to send agent notifications
	   );
	$Self->True(
		$ArticleID,
    	"create article: $ArticleID",
	);
	   
}
else
{
$Self->Is(
    $ArticleID,
    $ArticleID,
    "ArticleID: ",
);} 



   

##############################################################
# Kernel::System::Ticket::TicketEscalationIndexBuild
##############################################################
# check line 73
$Success = $TicketObject->TicketStateSet(
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





#Ein Ticket wird erstellt. Die Lösungszeit beträgt 2 Stunden. Die zu erwartende Eskalation wird für 10:00 angezeigt.
#########################
# $SuspendStateActive = 1
#########################

#set pending time to 30 min

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




my $SystemTime = $TimeObject->SystemTime();

# if systemTime is greater SystemPendingTime Create CustomerArticle..
# Der Kunde Antwortet via E-Mail mit den fehlenden Informationen. Das Ticket wird in den Status "open" 

if ($SystemTime gt  $SystemPendingTime )   { 
	
	 $ArticleID = $TicketObject->ArticleCreate(
	       TicketID         => $TicketID,
	       ArticleType      => 'note-internal',                        # email-external|email-internal|phone|fax|...
	       SenderType       => 'customer',                                # agent|system|customer
	       From             => 'Some Agent <email@example.com>',       # not required but useful
	       Subject          => 'some short description',               # required
	       Body             => 'the message text',                     # required
	       ContentType      => 'text/plain; charset=ISO-8859-15',      # or optional Charset & MimeType
	       HistoryType      => 'OwnerUpdate',                          # EmailCustomer|Move|AddNote|PriorityUpdate|WebRequestCustomer|...
	       HistoryComment   => 'Some free text!',
	       UserID           => 1,
	       NoAgentNotify    => 0,                                      # if you don't want to send agent notifications
	   );
	$Self->True(
		$ArticleID,
    	"create a new article: $ArticleID",
	);
	
	# change state to open (follow up via customer)
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
	
	
	   
}


$TicketEscalationIndexBuild = $EscalationSuspendObject->TicketEscalationIndexBuild(
	TicketID => $TicketID,
	UserID   => 1,
);

$Self->True(
    $TicketEscalationIndexBuild,
    'TicketEscalationIndexBuild() - set pending time and customer article',
);




##############################################################
# Kernel::System::Ticket::TicketEscalationSuspendCalculate
##############################################################
#

%Ticket = $TicketObject->TicketGet(
    TicketID => $TicketID,
    Extended => 1,
);
   
# get escalation properties
%Escalation = $TicketObject->TicketEscalationPreferences(
	Ticket => \%Ticket,
	UserID => 1,
);

$SuspendStateActive = 1;

#return  $DestinationTime = $StartTime + $ResponseTime - $EscalatedTime;
$TicketEscalationSuspendCalculat = $EscalationSuspendObject->TicketEscalationSuspendCalculate(
	StartTime		=> $Ticket{Created},
	TicketID 		=> $TicketID,
    ResponseTime 	=> $Escalation{SolutionTime},
    Calendar     	=> $Escalation{Calendar},     # 
    Suspended    	=> $SuspendStateActive,       # should be 1
);

my $TimeStamp = $TimeObject->SystemTime2TimeStamp(
       SystemTime => $TicketEscalationSuspendCalculat,
   );

$Self->IsNot(
    $TimeStamp,
    "",
    'TicketEscalationSuspendCalculat()   - return new DestinationTime ',
);







return 1;


# delete created ticket
$Success = $TicketObject->TicketDelete(
       TicketID => $TicketID,
       UserID   => 1,
   );



###############################################################
## Kernel::System::Ticket::TicketWorkingTimeSuspendCalculate
###############################################################
#return $WorkingTimeUnsuspended
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


%TicketGetClosed = $EscalationSuspendObject->_TicketGetClosed(
    TicketID => $Ticket{TicketID},
    Ticket => \%Ticket,
    UserID => '1',
);

$Self->IsNot(
    $TicketGetClosed{SolutionInMin},
    undef,
    '_TicketGetClosed()   - first run without changes',
);


return 1;
# delete created ticket
$Success = $TicketObject->TicketDelete(
       TicketID => $TicketID,
       UserID   => 1,
   );



1;

