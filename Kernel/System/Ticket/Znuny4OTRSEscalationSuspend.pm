# --
# Kernel/System/Ticket/Znuny4OTRSEscalationSuspend.pm - custom ticket changes
# Copyright (C) 2014 Znuny GmbH, http://znuny.com/
# --

package Kernel::System::Ticket::Znuny4OTRSEscalationSuspend;

use strict;
use warnings;

# disable redefine warnings in this scope
{
    no warnings 'redefine';

    # redefine TicketEscalationIndexBuild() of Kernel::System::Ticket
    sub Kernel::System::Ticket::TicketEscalationIndexBuild {
        my ( $Self, %Param ) = @_;

        # check needed stuff
        for my $Needed (qw(TicketID UserID)) {
            if ( !defined $Param{$Needed} ) {
                $Self->{LogObject}->Log( Priority => 'error', Message => "Need $Needed!" );
                return;
            }
        }

        my %Ticket = $Self->TicketGet(
            TicketID => $Param{TicketID},
            UserID   => $Param{UserID},
        );

        # get states in which to suspend escalations
        my @SuspendStates      = @{ $Self->{ConfigObject}->Get('EscalationSuspendStates') };
        my $SuspendStateActive = 0;
        for my $State (@SuspendStates) {
            if ( $Ticket{State} eq $State ) {
                $SuspendStateActive = 1;
                last;
            }
        }

        # do no escalations on (merge|close|remove) tickets
        if ( $Ticket{StateType} =~ /^(merge|close|remove)/i ) {

            # update escalation times with 0
            my %EscalationTimes = (
                EscalationTime         => 'escalation_time',
                EscalationResponseTime => 'escalation_response_time',
                EscalationUpdateTime   => 'escalation_update_time',
                EscalationSolutionTime => 'escalation_solution_time',
            );

            KEY:
            for my $Key ( keys %EscalationTimes ) {

                # check if table update is needed
                next KEY if !$Ticket{$Key};

                # update ticket table
                $Self->{DBObject}->Do(
                    SQL  => "UPDATE ticket SET $EscalationTimes{$Key} = 0 WHERE id = ?",
                    Bind => [ \$Ticket{TicketID}, ]
                );
            }

            # clear ticket cache
            delete $Self->{ 'Cache::GetTicket' . $Param{TicketID} };
            if ($Self->can('_TicketCacheClear')) {
                $Self->_TicketCacheClear( TicketID => $Param{TicketID} );
            }
            return 1;
        }

        # get escalation properties
        my %Escalation = $Self->TicketEscalationPreferences(
            Ticket => \%Ticket,
            UserID => $Param{UserID},
        );

        # find escalation times
        my $EscalationTime = 0;

        # update first response (if not responded till now)
        if ( !$Escalation{FirstResponseTime} ) {
            $Self->{DBObject}->Do(
                SQL  => 'UPDATE ticket SET escalation_response_time = 0 WHERE id = ?',
                Bind => [ \$Ticket{TicketID}, ]
            );
        }
        else {

            # check if first response is already done
            my %FirstResponseDone = $Self->_TicketGetFirstResponse(
                TicketID => $Ticket{TicketID},
                Ticket   => \%Ticket,
            );

            # update first response time to 0
            if (%FirstResponseDone) {
                $Self->{DBObject}->Do(
                    SQL  => 'UPDATE ticket SET escalation_response_time = 0 WHERE id = ?',
                    Bind => [ \$Ticket{TicketID}, ]
                );
            }

            # update first response time to expected escalation destination time
            else {
                my $DestinationTime = $Self->TicketEscalationSuspendCalculate(
                    TicketID     => $Ticket{TicketID},
                    StartTime    => $Ticket{Created},
                    ResponseTime => $Escalation{FirstResponseTime},
                    Calendar     => $Escalation{Calendar},
                    Suspended    => $SuspendStateActive,
                );

                # update first response time to $DestinationTime
                $Self->{DBObject}->Do(
                    SQL => 'UPDATE ticket SET escalation_response_time = ? WHERE id = ?',
                    Bind => [ \$DestinationTime, \$Ticket{TicketID}, ]
                );

                # remember escalation time
                $EscalationTime = $DestinationTime;
            }
        }

        # update update && do not escalate in "pending auto" for escalation update time
        if ( !$Escalation{UpdateTime} || $Ticket{StateType} =~ /^(pending)/i ) {
            $Self->{DBObject}->Do(
                SQL  => 'UPDATE ticket SET escalation_update_time = 0 WHERE id = ?',
                Bind => [ \$Ticket{TicketID}, ]
            );
        }
        else {

            # check if update escalation should be set
            my @SenderHistory;
            return if !$Self->{DBObject}->Prepare(
                SQL => 'SELECT article_sender_type_id, article_type_id, create_time FROM '
                    . 'article WHERE ticket_id = ? ORDER BY create_time ASC',
                Bind => [ \$Param{TicketID} ],
            );
            while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
                push @SenderHistory, {
                    SenderTypeID  => $Row[0],
                    ArticleTypeID => $Row[1],
                    Created       => $Row[2],
                };
            }

            # fill up lookups
            for my $Row (@SenderHistory) {

                # get sender type
                $Row->{SenderType} = $Self->ArticleSenderTypeLookup(
                    SenderTypeID => $Row->{SenderTypeID},
                );

                # get article type
                $Row->{ArticleType} = $Self->ArticleTypeLookup(
                    ArticleTypeID => $Row->{ArticleTypeID},
                );
            }

            # get latest customer contact time
            my $LastSenderTime;
            my $LastSenderType = '';

            ROWSENDERHISTORY:
            for my $Row ( reverse @SenderHistory ) {

                # fill up latest sender time (as initial value)
                if ( !$LastSenderTime ) {
                    $LastSenderTime = $Row->{Created};
                }

                # do not use locked tickets for calculation
                #last if $Ticket{Lock} eq 'lock';

                # do not use /int/ article types for calculation
                next ROWSENDERHISTORY if $Row->{ArticleType} =~ /int/i;

                # only use 'agent' and 'customer' sender types for calculation
                next ROWSENDERHISTORY if $Row->{SenderType} !~ /^(agent|customer)$/;

                # last if latest was customer and the next was not customer
                # otherwise use also next, older customer article as latest
                # customer followup for starting escalation
                if ( $Row->{SenderType} eq 'agent' && $LastSenderType eq 'customer' ) {
                    last;
                }

                # start escalation on latest customer article
                if ( $Row->{SenderType} eq 'customer' ) {
                    $LastSenderType = 'customer';
                    $LastSenderTime = $Row->{Created};
                }

                # start escalation on latest agent article
                if ( $Row->{SenderType} eq 'agent' ) {
                    $LastSenderTime = $Row->{Created};
                    last;
                }
            }

            if ($LastSenderTime) {
                my $DestinationTime = $Self->TicketEscalationSuspendCalculate(
                    TicketID     => $Ticket{TicketID},
                    StartTime    => $LastSenderTime,
                    ResponseTime => $Escalation{UpdateTime},
                    Calendar     => $Escalation{Calendar},
                    Suspended    => $SuspendStateActive,
                );

                # update update time to $DestinationTime
                $Self->{DBObject}->Do(
                    SQL => 'UPDATE ticket SET escalation_update_time = ? WHERE id = ?',
                    Bind => [ \$DestinationTime, \$Ticket{TicketID}, ]
                );

                # remember escalation time
                if ( $EscalationTime == 0 || $DestinationTime < $EscalationTime ) {
                    $EscalationTime = $DestinationTime;
                }
            }

            # else, no not escalate, because latest sender was agent
            else {
                $Self->{DBObject}->Do(
                    SQL  => 'UPDATE ticket SET escalation_update_time = 0 WHERE id = ?',
                    Bind => [ \$Ticket{TicketID}, ]
                );
            }
        }

        # update solution
        if ( !$Escalation{SolutionTime} ) {
            $Self->{DBObject}->Do(
                SQL  => 'UPDATE ticket SET escalation_solution_time = 0 WHERE id = ?',
                Bind => [ \$Ticket{TicketID}, ]
            );
        }
        else {

            # find solution time / first close time
            my %SolutionDone = $Self->_TicketGetClosed(
                TicketID => $Ticket{TicketID},
                Ticket   => \%Ticket,
            );

            # update solution time to 0
            if (%SolutionDone) {
                $Self->{DBObject}->Do(
                    SQL  => 'UPDATE ticket SET escalation_solution_time = 0 WHERE id = ?',
                    Bind => [ \$Ticket{TicketID}, ]
                );
            }
            else {
                my $DestinationTime = $Self->TicketEscalationSuspendCalculate(
                    TicketID     => $Ticket{TicketID},
                    StartTime    => $Ticket{Created},
                    ResponseTime => $Escalation{SolutionTime},
                    Calendar     => $Escalation{Calendar},
                    Suspended    => $SuspendStateActive,
                );

                # update solution time to $DestinationTime
                $Self->{DBObject}->Do(
                    SQL => 'UPDATE ticket SET escalation_solution_time = ? WHERE id = ?',
                    Bind => [ \$DestinationTime, \$Ticket{TicketID}, ]
                );

                # remember escalation time
                if ( $EscalationTime == 0 || $DestinationTime < $EscalationTime ) {
                    $EscalationTime = $DestinationTime;
                }
            }
        }

        # update escalation time (< escalation time)
        if ( defined $EscalationTime ) {
            $Self->{DBObject}->Do(
                SQL => 'UPDATE ticket SET escalation_time = ? WHERE id = ?',
                Bind => [ \$EscalationTime, \$Ticket{TicketID}, ]
            );
        }

        # clear ticket cache
        delete $Self->{ 'Cache::GetTicket' . $Param{TicketID} };
        if ($Self->can('_TicketCacheClear')) {
            $Self->_TicketCacheClear( TicketID => $Param{TicketID} );
        }
        return 1;
    }

    sub Kernel::System::Ticket::TicketEscalationSuspendCalculate {
        my ( $Self, %Param ) = @_;

        # get states in which to suspend escalations
        my @SuspendStates = @{ $Self->{ConfigObject}->Get('EscalationSuspendStates') };

        # get stateid->state map
        my %StateList = $Self->{StateObject}->StateList(
            UserID => 1,
        );

        # check for suspend times
        my @StateHistory;
        $Self->{DBObject}->Prepare(
            SQL => 'SELECT th.state_id, th.create_time FROM '
                . 'ticket_history th, ticket_history_type tht '
                . 'WHERE th.history_type_id = tht.id '
                . 'AND tht.name IN (' . "'NewTicket', 'StateUpdate'" . ') '
                . 'AND th.ticket_id = ? '
                . 'ORDER BY th.create_time ASC',
            Bind => [ \$Param{TicketID} ],
        );
        while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
            push @StateHistory, {
                StateID     => $Row[0],
                Created     => $Row[1],
                CreatedUnix => $Self->{TimeObject}->TimeStamp2SystemTime(
                    String => $Row[1],
                ),
                State => $StateList{ $Row[0] },
            };
        }

        # get update difftime in seconds
        my $UpdateDiffTime = $Param{ResponseTime} * 60;

        # add 4 minutes (time between cron runs) if we are in suspend state to prevent escalation
        if ( $Param{Suspended} ) {
            $UpdateDiffTime += 4 * 60;
        }

        # start time in unix format
        my $DestinationTime = $Self->{TimeObject}->TimeStamp2SystemTime(
            String => $Param{StartTime},
        );

        # loop through state changes
        my $SuspendState = 0;

        ROW:
        for my $Row (@StateHistory) {
            if ( $Row->{CreatedUnix} <= $DestinationTime ) {

                # old state change, remember if suspend state
                $SuspendState = 0;
                for my $State (@SuspendStates) {
                    if ( $Row->{State} eq $State ) {
                        $SuspendState = 1;
                    }
                }
                next ROW;
            }

            if ($SuspendState) {

                # move destination time forward if suspend state
                $DestinationTime = $Row->{CreatedUnix};
            }
            else {

                # calculate working time if no suspend state
                my $WorkingTime = $Self->{TimeObject}->WorkingTime(
                    StartTime => $DestinationTime,
                    StopTime  => $Row->{CreatedUnix},
                    Calendar  => $Param{Calendar},
                );
                if ( $WorkingTime < $UpdateDiffTime ) {

                    # move destination time, substract diff time
                    $DestinationTime = $Row->{CreatedUnix};
                    $UpdateDiffTime -= $WorkingTime;
                }
                else {

                    # target time reached, calculate exact time
                    while ($UpdateDiffTime) {
                        $WorkingTime = $Self->{TimeObject}->WorkingTime(
                            StartTime => $DestinationTime,
                            StopTime  => $DestinationTime + $UpdateDiffTime,
                            Calendar  => $Param{Calendar},
                        );
                        $DestinationTime += $UpdateDiffTime;
                        $UpdateDiffTime -= $WorkingTime;
                    }
                    last;
                }

            }

            # remember if suspend state
            $SuspendState = 0;
            for my $State (@SuspendStates) {
                if ( $Row->{State} eq $State ) {
                    $SuspendState = 1;
                }
            }
        }

        if ($UpdateDiffTime) {
            my $StartTime = $DestinationTime;
            if ($SuspendState) {

                # use current timestamp if we are suspended
                $StartTime = $Self->{TimeObject}->SystemTime();
            }

            # some time left? calculate remainder as usual
            $DestinationTime = $Self->{TimeObject}->DestinationTime(
                StartTime => $StartTime,
                Time      => $UpdateDiffTime,
                Calendar  => $Param{Calendar},
            );
        }

        # If there is no "UpdateDiffTime" left, the ticket is escalated.
        # calculate exact escalation time and also suspend escalation for escalated tickets!
        # This is a special customer wish and can be activated via config. By default this option is inactive.
        elsif ( !$UpdateDiffTime && $Self->{ConfigObject}->Get( 'SuspendEscalatedTickets' ) ) {

            # start time in unix format
            my $InterimDestinationTime = $Self->{TimeObject}->TimeStamp2SystemTime(
                String => $Param{StartTime},
            );

            # "ResponseTime" (can also be f.e. SolutionTime)
            my $ResponseTime += $Param{ResponseTime} * 60;

            # add cronjob run time
            $ResponseTime += 4 * 60;

            # count escalated time in seconds
            my $EscalatedTime = 0;

            # calculate escalated time
            for my $Row (@StateHistory) {

                # check if current state should be suspended
                $SuspendState = 0;
                for my $State (@SuspendStates) {
                    if ( $Row->{State} eq $State ) {
                        $SuspendState = 1;
                    }
                }

                if (!$SuspendState) {

                    # move destination time forward, if state is not a suspend state
                    $InterimDestinationTime = $Row->{CreatedUnix};
                }
                else {

                    # calculate working time if state is suspend state
                    my $WorkingTime = $Self->{TimeObject}->WorkingTime(
                        StartTime => $InterimDestinationTime,
                        StopTime  => $Row->{CreatedUnix},
                        Calendar  => $Param{Calendar},
                    );

                    # count time from unsuspended status
                    $EscalatedTime += $WorkingTime;
                }
            }
            my $StartTime;
            if ($Param{Suspended}) {
                # use current timestamp, because current state should be suspended
                $StartTime = $Self->{TimeObject}->SystemTime();
            }
            else {
                # use time of last non-suspend state
                $StartTime = $InterimDestinationTime;
            }
            $DestinationTime = $StartTime + $ResponseTime - $EscalatedTime;
        }
        return $DestinationTime;
    }

    sub Kernel::System::Ticket::TicketWorkingTimeSuspendCalculate {
        my ( $Self, %Param ) = @_;

        # get states in which to suspend escalations
        my @SuspendStates = @{ $Self->{ConfigObject}->Get('EscalationSuspendStates') };

        # get stateid->state map
        my %StateList = $Self->{StateObject}->StateList(
            UserID => 1,
        );

        # check for suspend times
        my @StateHistory;
        $Self->{DBObject}->Prepare(
            SQL => 'SELECT th.state_id, th.create_time FROM '
                . 'ticket_history th, ticket_history_type tht '
                . 'WHERE th.history_type_id = tht.id '
                . 'AND tht.name IN (' . "'NewTicket', 'StateUpdate'" . ') '
                . 'AND th.ticket_id = ? '
                . 'ORDER BY th.create_time ASC',
            Bind => [ \$Param{TicketID} ],
        );
        while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
            push @StateHistory, {
                StateID     => $Row[0],
                Created     => $Row[1],
                CreatedUnix => $Self->{TimeObject}->TimeStamp2SystemTime(
                    String => $Row[1],
                ),
                State => $StateList{ $Row[0] },
            };
        }

        # start time in unix format
        my $DestinationTime = $Self->{TimeObject}->TimeStamp2SystemTime(
            String => $Param{StartTime},
        );

        # loop through state changes
        my $SuspendState           = 0;
        my $WorkingTimeUnsuspended = 0;
        ROW:
        for my $Row (@StateHistory) {

            if ( $Row->{CreatedUnix} <= $DestinationTime ) {

                # old state change, remember if suspend state
                $SuspendState = 0;
                for my $State (@SuspendStates) {
                    if ( $Row->{State} eq $State ) {
                        $SuspendState = 1;
                    }
                }
                next ROW;
            }

            if ( !$SuspendState ) {

                # calculate working time if no suspend state
                my $WorkingTime = $Self->{TimeObject}->WorkingTime(
                    StartTime => $DestinationTime,
                    StopTime  => $Row->{CreatedUnix},
                    Calendar  => $Param{Calendar},
                );

                $WorkingTimeUnsuspended += $WorkingTime;
            }

            # move destination time forward if suspend state
            $DestinationTime = $Row->{CreatedUnix};

            # remember if suspend state
            $SuspendState = 0;
            for my $State (@SuspendStates) {
                if ( $Row->{State} eq $State ) {
                    $SuspendState = 1;
                }
            }
        }

        return $WorkingTimeUnsuspended;
    }


    sub Kernel::System::Ticket::_TicketGetClosed {
        my ( $Self, %Param ) = @_;

        # check needed stuff
        for my $Needed (qw(TicketID Ticket)) {
            if ( !defined $Param{$Needed} ) {
                $Self->{LogObject}->Log( Priority => 'error', Message => "Need $Needed!" );
                return;
            }
        }

        # get close state types
        my @List = $Self->{StateObject}->StateGetStatesByType(
            StateType => ['closed'],
            Result    => 'ID',
        );
        return if !@List;

        # Get id for history types
        my @HistoryTypeIDs;
        for my $HistoryType (qw(StateUpdate NewTicket)) {
            push @HistoryTypeIDs, $Self->HistoryTypeLookup( Type => $HistoryType );
        }

        return if !$Self->{DBObject}->Prepare(
            SQL => "
                SELECT MAX(create_time)
                FROM ticket_history
                WHERE ticket_id = ?
                   AND state_id IN (${\(join ', ', sort @List)})
                   AND history_type_id IN  (${\(join ', ', sort @HistoryTypeIDs)})
                ",
            Bind => [ \$Param{TicketID} ],
        );

        my %Data;
        ROW:
        while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
            last ROW if !defined $Row[0];
            $Data{Closed} = $Row[0];

            # cleanup time stamps (some databases are using e. g. 2008-02-25 22:03:00.000000
            # and 0000-00-00 00:00:00 time stamps)
            $Data{Closed} =~ s/^(\d\d\d\d-\d\d-\d\d\s\d\d:\d\d:\d\d)\..+?$/$1/;
        }

        return if !$Data{Closed};

        # for compat. wording reasons
        $Data{SolutionTime} = $Data{Closed};

        # get escalation properties
        my %Escalation = $Self->TicketEscalationPreferences(
            Ticket => $Param{Ticket},
            UserID => $Param{UserID} || 1,
        );

        if ( $Escalation{SolutionTime} ) {

            # get unix time stamps
            my $CreateTime = $Self->{TimeObject}->TimeStamp2SystemTime(
                String => $Param{Ticket}->{Created},
            );
            my $SolutionTime = $Self->{TimeObject}->TimeStamp2SystemTime(
                String => $Data{Closed},
            );

            # get time between creation and solution
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#             my $WorkingTime = $Self->{TimeObject}->WorkingTime(
#                 StartTime => $CreateTime,
#                 StopTime  => $SolutionTime,
#                 Calendar  => $Escalation{Calendar},
#             );
            my $WorkingTime = $Self->TicketWorkingTimeSuspendCalculate(
                TicketID  => $Param{Ticket}->{TicketID},
                StartTime => $Param{Ticket}->{Created},
                Calendar  => $Escalation{Calendar},
            );
# ---

            $Data{SolutionInMin} = int( $WorkingTime / 60 );

            my $EscalationSolutionTime = $Escalation{SolutionTime} * 60;
            $Data{SolutionDiffInMin} = int( ( $EscalationSolutionTime - $WorkingTime ) / 60 );
        }

        return %Data;
    }

    # reset all warnings
}

1;

