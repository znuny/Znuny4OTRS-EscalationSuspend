# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# Copyright (C) 2012-2016 Znuny GmbH, http://znuny.com/
# --
# $origin: https://github.com/OTRS/otrs/blob/6114661c44c9ca9dec45364b54bfab036ce6e34e/Kernel/System/Ticket.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Ticket::Znuny4OTRSEscalationSuspend;

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

# disable redefine warnings in this scope
{
    no warnings 'redefine';

    # redefine TicketEscalationIndexBuild() of Kernel::System::Ticket
    sub Kernel::System::Ticket::TicketEscalationIndexBuild {
        my ( $Self, %Param ) = @_;

        # check needed stuff
        for my $Needed (qw(TicketID UserID)) {
            if ( !defined $Param{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }

        my %Ticket = $Self->TicketGet(
            TicketID      => $Param{TicketID},
            UserID        => $Param{UserID},
            DynamicFields => 0,
        );

# ---
# Znuny4OTRS-EscalationSuspend
# ---
        # get states in which to suspend escalations
        my @SuspendStates      = @{ $Kernel::OM->Get('Kernel::Config')->Get('EscalationSuspendStates') };
        my $SuspendStateActive = 0;
        STATE:
        for my $State (@SuspendStates) {
            next STATE if $Ticket{State} ne $State;
            $SuspendStateActive = 1;
            last STATE;
        }

# ---

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

# ---
# Znuny4OTRS-EscalationSuspend
# ---
#
        # cancel whole escalation
        my $EscalationSuspendCancelEscalation = $Kernel::OM->Get('Kernel::Config')->Get('EscalationSuspendCancelEscalation');

#        if ( $Ticket{StateType} =~ /^(merge|close|remove)/i ) {
        # do no escalations on (merge|close|remove) tickets
        if ( $Ticket{StateType} =~ /^(merge|close|remove)/i || ($EscalationSuspendCancelEscalation && $SuspendStateActive) ) {
# ---

            # update escalation times with 0
            my %EscalationTimes = (
                EscalationTime         => 'escalation_time',
                EscalationResponseTime => 'escalation_response_time',
                EscalationUpdateTime   => 'escalation_update_time',
                EscalationSolutionTime => 'escalation_solution_time',
            );

            TIME:
            for my $Key ( sort keys %EscalationTimes ) {

                # check if table update is needed
                next TIME if !$Ticket{$Key};

                # update ticket table
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        "UPDATE ticket SET $EscalationTimes{$Key} = 0, change_time = current_timestamp, "
#                        . " change_by = ? WHERE id = ?",
#                    Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ],
#                );
                my $SQL = "UPDATE ticket SET $EscalationTimes{$Key} = 0";
                my @Bind;
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                # update ticket table
                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---
            }

            # clear ticket cache
            $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

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
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#            $DBObject->Do(
#                SQL =>
#                    'UPDATE ticket SET escalation_response_time = 0, change_time = current_timestamp, '
#                    . ' change_by = ? WHERE id = ?',
#                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
#            );
            my $SQL = "UPDATE ticket SET escalation_response_time = 0";
            my @Bind;
            if ( !$Param{Suspend} || !$SuspendStateActive ) {
                $SQL .= ', change_time = current_timestamp, change_by = ?';
                push @Bind, \$Param{UserID};
            }
            $SQL .= " WHERE id = ?";
            push @Bind, \$Ticket{TicketID};

            $DBObject->Do(
                SQL  => $SQL,
                Bind => \@Bind,
            );
# ---

        }
        else {

            # check if first response is already done
            my %FirstResponseDone = $Self->_TicketGetFirstResponse(
                TicketID => $Ticket{TicketID},
                Ticket   => \%Ticket,
            );

            # update first response time to 0
            if (%FirstResponseDone) {
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        'UPDATE ticket SET escalation_response_time = 0, change_time = current_timestamp, '
#                        . ' change_by = ? WHERE id = ?',
#                    Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
#                );
                my $SQL = "UPDATE ticket SET escalation_response_time = 0";
                my @Bind;
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---
            }

            # update first response time to expected escalation destination time
            else {
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#
#                # get time object
#                my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
#
#                my $DestinationTime = $TimeObject->DestinationTime(
#                    StartTime => $TimeObject->TimeStamp2SystemTime(
#                        String => $Ticket{Created}
#                    ),
#                    Time     => $Escalation{FirstResponseTime} * 60,
#                    Calendar => $Escalation{Calendar},
#                );
                my $DestinationTime = $Self->TicketEscalationSuspendCalculate(
                    TicketID     => $Ticket{TicketID},
                    StartTime    => $Ticket{Created},
                    ResponseTime => $Escalation{FirstResponseTime},
                    Calendar     => $Escalation{Calendar},
                    Suspended    => $SuspendStateActive,
                );
# ---


                # update first response time to $DestinationTime
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        'UPDATE ticket SET escalation_response_time = ?, change_time = current_timestamp, '
#                        . ' change_by = ? WHERE id = ?',
#                    Bind => [ \$DestinationTime, \$Param{UserID}, \$Ticket{TicketID}, ]
#                );
                my $SQL  = "UPDATE ticket SET escalation_response_time = ?";
                my @Bind = ( \$DestinationTime );
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---

                # remember escalation time
                $EscalationTime = $DestinationTime;
            }
        }

        # update update && do not escalate in "pending auto" for escalation update time
        if ( !$Escalation{UpdateTime} || $Ticket{StateType} =~ /^(pending)/i ) {
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#            $DBObject->Do(
#                SQL => 'UPDATE ticket SET escalation_update_time = 0, change_time = current_timestamp, '
#                    . ' change_by = ? WHERE id = ?',
#                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
#            );
            my $SQL = "UPDATE ticket SET escalation_update_time = 0";
            my @Bind;
            if ( !$Param{Suspend} || !$SuspendStateActive ) {
                $SQL .= ', change_time = current_timestamp, change_by = ?';
                push @Bind, \$Param{UserID};
            }
            $SQL .= " WHERE id = ?";
            push @Bind, \$Ticket{TicketID};

            $DBObject->Do(
                SQL  => $SQL,
                Bind => \@Bind,
            );
# ---

        }
        else {

            # check if update escalation should be set
            my @SenderHistory;
            return if !$DBObject->Prepare(
                SQL => 'SELECT article_sender_type_id, article_type_id, create_time FROM '
                    . 'article WHERE ticket_id = ? ORDER BY create_time ASC',
                Bind => [ \$Param{TicketID} ],
            );
            while ( my @Row = $DBObject->FetchrowArray() ) {
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
            ROW:
            for my $Row ( reverse @SenderHistory ) {

                # fill up latest sender time (as initial value)
                if ( !$LastSenderTime ) {
                    $LastSenderTime = $Row->{Created};
                }

                # do not use locked tickets for calculation
                #last ROW if $Ticket{Lock} eq 'lock';

                # do not use internal article types for calculation
                next ROW if $Row->{ArticleType} =~ /-int/i;

                # only use 'agent' and 'customer' sender types for calculation
                next ROW if $Row->{SenderType} !~ /^(agent|customer)$/;

                # last ROW if latest was customer and the next was not customer
                # otherwise use also next, older customer article as latest
                # customer followup for starting escalation
                if ( $Row->{SenderType} eq 'agent' && $LastSenderType eq 'customer' ) {
                    last ROW;
                }

                # start escalation on latest customer article
                if ( $Row->{SenderType} eq 'customer' ) {
                    $LastSenderType = 'customer';
                    $LastSenderTime = $Row->{Created};
                }

                # start escalation on latest agent article
                if ( $Row->{SenderType} eq 'agent' ) {
                    $LastSenderTime = $Row->{Created};
                    last ROW;
                }
            }
            if ($LastSenderTime) {

# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                # get time object
#                my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
#
#                my $DestinationTime = $TimeObject->DestinationTime(
#                    StartTime => $TimeObject->TimeStamp2SystemTime(
#                        String => $LastSenderTime,
#                    ),
#                    Time     => $Escalation{UpdateTime} * 60,
#                    Calendar => $Escalation{Calendar},
#                );
                my $DestinationTime = $Self->TicketEscalationSuspendCalculate(
                    TicketID     => $Ticket{TicketID},
                    StartTime    => $LastSenderTime,
                    ResponseTime => $Escalation{UpdateTime},
                    Calendar     => $Escalation{Calendar},
                    Suspended    => $SuspendStateActive,
                );

# ---

                # update update time to $DestinationTime
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        'UPDATE ticket SET escalation_update_time = ?, change_time = current_timestamp, '
#                        . ' change_by = ? WHERE id = ?',
#                    Bind => [ \$DestinationTime, \$Param{UserID}, \$Ticket{TicketID}, ]
#                );
                my $SQL  = "UPDATE ticket SET escalation_update_time = ?";
                my @Bind = ( \$DestinationTime );
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---

                # remember escalation time
                if ( $EscalationTime == 0 || $DestinationTime < $EscalationTime ) {
                    $EscalationTime = $DestinationTime;
                }
            }

            # else, no not escalate, because latest sender was agent
            else {
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        'UPDATE ticket SET escalation_update_time = 0, change_time = current_timestamp, '
#                        . ' change_by = ? WHERE id = ?',
#                    Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ]
#                );
                my $SQL = "UPDATE ticket SET escalation_update_time = 0";
                my @Bind;
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---
            }
        }

        # update solution
        if ( !$Escalation{SolutionTime} ) {

# ---
# Znuny4OTRS-EscalationSuspend
# ---
#            $DBObject->Do(
#                SQL =>
#                    'UPDATE ticket SET escalation_solution_time = 0, change_time = current_timestamp, '
#                    . ' change_by = ? WHERE id = ?',
#                Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ],
#            );
            my $SQL = "UPDATE ticket SET escalation_solution_time = 0";
            my @Bind;
            if ( !$Param{Suspend} || !$SuspendStateActive ) {
                $SQL .= ', change_time = current_timestamp, change_by = ?';
                push @Bind, \$Param{UserID};
            }
            $SQL .= " WHERE id = ?";
            push @Bind, \$Ticket{TicketID};

            $DBObject->Do(
                SQL  => $SQL,
                Bind => \@Bind,
            );
# ---
        }
        else {

            # find solution time / first close time
            my %SolutionDone = $Self->_TicketGetClosed(
                TicketID => $Ticket{TicketID},
                Ticket   => \%Ticket,
            );

            # update solution time to 0
            if (%SolutionDone) {
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        'UPDATE ticket SET escalation_solution_time = 0, change_time = current_timestamp, '
#                        . ' change_by = ? WHERE id = ?',
#                    Bind => [ \$Param{UserID}, \$Ticket{TicketID}, ],
#                );
                my $SQL = "UPDATE ticket SET escalation_solution_time = 0";
                my @Bind;
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---

            }
            else {

                # get time object
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
#
#                my $DestinationTime = $TimeObject->DestinationTime(
#                    StartTime => $TimeObject->TimeStamp2SystemTime(
#                        String => $Ticket{Created}
#                    ),
#                    Time     => $Escalation{SolutionTime} * 60,
#                    Calendar => $Escalation{Calendar},
#                );
                my $DestinationTime = $Self->TicketEscalationSuspendCalculate(
                    TicketID     => $Ticket{TicketID},
                    StartTime    => $Ticket{Created},
                    ResponseTime => $Escalation{SolutionTime},
                    Calendar     => $Escalation{Calendar},
                    Suspended    => $SuspendStateActive,
                );
# ---

                # update solution time to $DestinationTime
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#                $DBObject->Do(
#                    SQL =>
#                        'UPDATE ticket SET escalation_solution_time = ?, change_time = current_timestamp, '
#                        . ' change_by = ? WHERE id = ?',
#                    Bind => [ \$DestinationTime, \$Param{UserID}, \$Ticket{TicketID}, ],
#                );
                my $SQL  = "UPDATE ticket SET escalation_solution_time = ?";
                my @Bind = ( \$DestinationTime );
                if ( !$Param{Suspend} || !$SuspendStateActive ) {
                    $SQL .= ', change_time = current_timestamp, change_by = ?';
                    push @Bind, \$Param{UserID};
                }
                $SQL .= " WHERE id = ?";
                push @Bind, \$Ticket{TicketID};

                $DBObject->Do(
                    SQL  => $SQL,
                    Bind => \@Bind,
                );
# ---

                # remember escalation time
                if ( $EscalationTime == 0 || $DestinationTime < $EscalationTime ) {
                    $EscalationTime = $DestinationTime;
                }
            }
        }

        # update escalation time (< escalation time)
        if ( defined $EscalationTime ) {
# ---
# Znuny4OTRS-EscalationSuspend
# ---
#            $DBObject->Do(
#                SQL => 'UPDATE ticket SET escalation_time = ?, change_time = current_timestamp, '
#                    . ' change_by = ? WHERE id = ?',
#                Bind => [ \$EscalationTime, \$Param{UserID}, \$Ticket{TicketID}, ],
#            );
            my $SQL  = "UPDATE ticket SET escalation_time = ?";
            my @Bind = ( \$EscalationTime );
            if ( !$Param{Suspend} || !$SuspendStateActive ) {
                $SQL .= ', change_time = current_timestamp, change_by = ?';
                push @Bind, \$Param{UserID};
            }
            $SQL .= " WHERE id = ?";
            push @Bind, \$Ticket{TicketID};

            $DBObject->Do(
                SQL  => $SQL,
                Bind => \@Bind,
            );
# ---
        }

        # clear ticket cache
        $Self->_TicketCacheClear( TicketID => $Param{TicketID} );

        return 1;
    }

    sub Kernel::System::Ticket::TicketEscalationSuspendCalculate {
        my ( $Self, %Param ) = @_;

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        # get states in which to suspend escalations
        my @SuspendStates = @{ $Kernel::OM->Get('Kernel::Config')->Get('EscalationSuspendStates') };

        # get stateid->state map
        my %StateList = $Kernel::OM->Get('Kernel::System::State')->StateList(
            UserID => 1,
        );

        # check for suspend times
        my @StateHistory;
        $DBObject->Prepare(
            SQL => 'SELECT th.state_id, th.create_time FROM '
                . 'ticket_history th, ticket_history_type tht '
                . 'WHERE th.history_type_id = tht.id '
                . 'AND tht.name IN (' . "'NewTicket', 'StateUpdate'" . ') '
                . 'AND th.ticket_id = ? '
                . 'ORDER BY th.create_time ASC',
            Bind => [ \$Param{TicketID} ],
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @StateHistory, {
                StateID     => $Row[0],
                Created     => $Row[1],
                CreatedUnix => $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
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
        my $DestinationTime = $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
            String => $Param{StartTime},
        );

        # loop through state changes
        my $SuspendState = 0;

        ROW:
        for my $Row (@StateHistory) {
            if ( $Row->{CreatedUnix} <= $DestinationTime ) {

                next ROW if !$Row->{State};

                # old state change, remember if suspend state
                $SuspendState = 0;
                STATE:
                for my $State (@SuspendStates) {

                    next STATE if $Row->{State} ne $State;

                    $SuspendState = 1;

                    last STATE;
                }
                next ROW;
            }

            if ($SuspendState) {

                # move destination time forward if suspend state
                $DestinationTime = $Row->{CreatedUnix};
            }
            else {

                # calculate working time if no suspend state
                my $WorkingTime = $Kernel::OM->Get('Kernel::System::Time')->WorkingTime(
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
                    my $Substract;
                    my $LoopProtection = 0;
                    UPDATETIME:
                    while ($UpdateDiffTime) {
                        $WorkingTime = $Kernel::OM->Get('Kernel::System::Time')->WorkingTime(
                            StartTime => $DestinationTime,
                            StopTime  => $DestinationTime + $UpdateDiffTime,
                            Calendar  => $Param{Calendar},
                        );

                        # if we got no working time we are come to an non-working our
                        # so we might want to move in bigger stepts of one hour (3600)
                        # if the steps a currently lower that that.
                        # if so we need to store the the current time so we can substract
                        # the difference between it and an full hour later so we come
                        # to the right number as if we would have moved with the smaller
                        # steps.
                        # otherwise it might happen/has happend that we move in steps of
                        # 1 second over a weekend (and vacation days) which causes nearly
                        # endless loops... oops :)
                        if ( !$WorkingTime && $UpdateDiffTime < 3600 ) {

                            # check if we already have stored a substract
                            # value and if not store the difference to
                            # the bigger steps so we can substract them
                            # later from the calculated destination time
                            if (!$Substract) {
                                $Substract = 3600 - $UpdateDiffTime;
                            }

                            # put on the bigger boots and move on faster
                            # in steps of one hour
                            $UpdateDiffTime = 3600;
                        }

                        $DestinationTime += $UpdateDiffTime;
                        $UpdateDiffTime -= $WorkingTime;

                        $LoopProtection++;

                        next UPDATETIME if $LoopProtection < 500;

                        $Kernel::OM->Get('Kernel::System::Log')->Log(
                            Priority => 'error',
                            Message  => "Error: 500 SuspendEscalatedTickets iterations for Ticket with TicketID '$Param{TicketID}', Calendar '$Param{Calendar}', UpdateDiffTime '$UpdateDiffTime', DestinationTime '$DestinationTime'.",
                        );
                        last UPDATETIME;
                    }

                    # check if we have stored a substract
                    # value to get to the real destination time
                    # other than the one hour step
                    last ROW if !$Substract;

                    $DestinationTime -= $Substract;

                    last ROW;
                }
            }

            next ROW if !$Row->{State};

            # remember if suspend state
            $SuspendState = 0;
            STATE:
            for my $State (@SuspendStates) {
                next STATE if $Row->{State} ne $State;

                $SuspendState = 1;

                last STATE;
            }
        }

        if ($UpdateDiffTime) {

            my $StartTime = $DestinationTime;

            # use current timestamp if we are suspended
            if ($SuspendState) {
                $StartTime = $Kernel::OM->Get('Kernel::System::Time')->SystemTime();
            }

            # some time left? calculate reminder as usual
            $DestinationTime = $Kernel::OM->Get('Kernel::System::Time')->DestinationTime(
                StartTime => $StartTime,
                Time      => $UpdateDiffTime,
                Calendar  => $Param{Calendar},
            );
        }

        # If there is no "UpdateDiffTime" left, the ticket is escalated.
        # calculate exact escalation time and also suspend escalation for escalated tickets!
        # This is a special customer wish and can be activated via config. By default this option is inactive.
        elsif ( !$UpdateDiffTime && $Kernel::OM->Get('Kernel::Config')->Get('SuspendEscalatedTickets') ) {

            # start time in unix format
            my $InterimDestinationTime = $Kernel::OM->Get('Kernel::System::Time')->TimeStamp2SystemTime(
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
                if ( $Row->{State} ) {
                    $SuspendState = 0;
                    STATE:
                    for my $State (@SuspendStates) {

                        next STATE if $Row->{State} ne $State;

                        $SuspendState = 1;

                        last STATE;
                    }
                }

                if ( !$SuspendState ) {

                    # move destination time forward, if state is not a suspend state
                    $InterimDestinationTime = $Row->{CreatedUnix};
                }
                else {

                    # calculate working time if state is suspend state
                    my $WorkingTime = $Kernel::OM->Get('Kernel::System::Time')->WorkingTime(
                        StartTime => $InterimDestinationTime,
                        StopTime  => $Row->{CreatedUnix},
                        Calendar  => $Param{Calendar},
                    );

                    # count time from unsuspended status
                    $EscalatedTime += $WorkingTime;
                }
            }
            my $StartTime;
            if ( $Param{Suspended} ) {

                # use current timestamp, because current state should be suspended
                $StartTime = $Kernel::OM->Get('Kernel::System::Time')->SystemTime();
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

        # get required objects
        my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
        my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');

        # get states in which to suspend escalations
        my @SuspendStates = @{ $Kernel::OM->Get('Kernel::Config')->Get('EscalationSuspendStates') };
        my @ClosedStates = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
            StateType => ['closed'],
            Result    => 'Name',
        );

        my @SuspendAndClosedStates = (@SuspendStates, @ClosedStates);

        # get stateid->state map
        my %StateList = $Kernel::OM->Get('Kernel::System::State')->StateList(
            UserID => 1,
        );

        # check for suspend times
        my @StateHistory;
        $DBObject->Prepare(
            SQL => 'SELECT th.state_id, th.create_time FROM '
                . 'ticket_history th, ticket_history_type tht '
                . 'WHERE th.history_type_id = tht.id '
                . 'AND tht.name IN (' . "'NewTicket', 'StateUpdate'" . ') '
                . 'AND th.ticket_id = ? '
                . 'ORDER BY th.create_time ASC',
            Bind => [ \$Param{TicketID} ],
        );
        while ( my @Row = $DBObject->FetchrowArray() ) {
            push @StateHistory, {
                StateID     => $Row[0],
                Created     => $Row[1],
                CreatedUnix => $TimeObject->TimeStamp2SystemTime(
                    String => $Row[1],
                ),
                State => $StateList{ $Row[0] },
            };
        }

        # start time in unix format
        my $DestinationTime = $TimeObject->TimeStamp2SystemTime(
            String => $Param{StartTime},
        );

        # loop through state changes
        my $SuspendState           = 0;
        my $WorkingTimeUnsuspended = 0;
        ROW:
        for my $Row (@StateHistory) {

            if ( $Row->{CreatedUnix} <= $DestinationTime ) {

                next ROW if !$Row->{State};

                # old state change, remember if suspend state
                $SuspendState = 0;
                STATE:
                for my $State (@SuspendAndClosedStates) {

                    next STATE if $Row->{State} ne $State;

                    $SuspendState = 1;

                    last STATE;
                }
                next ROW;
            }

            if ( !$SuspendState ) {

                # calculate working time if no suspend state
                my $WorkingTime = $TimeObject->WorkingTime(
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

            next ROW if !$Row->{State};

            STATE:
            for my $State (@SuspendAndClosedStates) {

                next STATE if $Row->{State} ne $State;

                $SuspendState = 1;

                last STATE;
            }
        }

        return $WorkingTimeUnsuspended;
    }

    sub Kernel::System::Ticket::RebuildEscallationIndex {
        my ( $Self, %Param ) = @_;

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
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'info',
                    Message  => "Rebuild Escalation Index: $Count of $#TicketIDs processed ($Percent% done)"
                );
            }
        }

    }

    sub Kernel::System::Ticket::_TicketGetClosed { ## no critic
        my ( $Self, %Param ) = @_;

        # check needed stuff
        for my $Needed (qw(TicketID Ticket)) {
            if ( !defined $Param{$Needed} ) {
                $Kernel::OM->Get('Kernel::System::Log')->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!"
                );
                return;
            }
        }

        # get close state types
        my @List = $Kernel::OM->Get('Kernel::System::State')->StateGetStatesByType(
            StateType => ['closed'],
            Result    => 'ID',
        );
        return if !@List;

        # Get id for history types
        my @HistoryTypeIDs;
        for my $HistoryType (qw(StateUpdate NewTicket)) {
            push @HistoryTypeIDs, $Self->HistoryTypeLookup( Type => $HistoryType );
        }

        # get database object
        my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

        return if !$DBObject->Prepare(
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
        while ( my @Row = $DBObject->FetchrowArray() ) {
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

# ---
# Znuny4OTRS-EscalationSuspend
# ---
#        # get time object
#        my $TimeObject = $Kernel::OM->Get('Kernel::System::Time');
#
#        # get unix time stamps
#        my $CreateTime = $TimeObject->TimeStamp2SystemTime(
#            String => $Param{Ticket}->{Created},
#        );
#        my $SolutionTime = $TimeObject->TimeStamp2SystemTime(
#            String => $Data{Closed},
#        );
#
#        # get time between creation and solution
#        my $WorkingTime = $TimeObject->WorkingTime(
#            StartTime => $CreateTime,
#            StopTime  => $SolutionTime,
#            Calendar  => $Escalation{Calendar},
#        );
        my $WorkingTime = $Self->TicketWorkingTimeSuspendCalculate(
            TicketID  => $Param{Ticket}->{TicketID},
            StartTime => $Param{Ticket}->{Created},
            Calendar  => $Escalation{Calendar},
        );
# ---

        $Data{SolutionInMin} = int( $WorkingTime / 60 );

        if ( $Escalation{SolutionTime} ) {
            my $EscalationSolutionTime = $Escalation{SolutionTime} * 60;
            $Data{SolutionDiffInMin} = int( ( $EscalationSolutionTime - $WorkingTime ) / 60 );
        }

        return %Data;
    }

    # reset all warnings
}

1;
