# --
# Kernel/Language/zh_CN_Znuny4OTRSEscalationSuspend.pm - the Chinese translation of the texts of Znuny4OTRSEscalationSuspend
# Copyright (C) 2001-2015 OTRS AG, http://otrs.com/
# Copyright (C) 2015 Znuny GmbH, http://znuny.com/
# --

package Kernel::Language::zh_CN_Znuny4OTRSEscalationSuspend;

use strict;
use warnings;

use utf8;

sub Data {
    my $Self = shift;

    $Self->{Translation}->{'List of states for which escalations should be suspended.'} = '列出的状态将会被暂停升级.';
    $Self->{Translation}->{'Escalation view - Without Suspend State'}                   = '非处于暂停状态的升级视图';
    $Self->{Translation}->{'Overview Escalated Tickets Without Suspend State'}          = '非处于暂停状态的工单升级视图一览';
    $Self->{Translation}->{'Suspend already escalated tickets.'}                        = '暂停已经升级的工单.';
    $Self->{Translation}->{'Ticket Escalation View Without Suspend State'}              = '非处于暂停状态的工单升级视图';

    return 1;
}

1;
