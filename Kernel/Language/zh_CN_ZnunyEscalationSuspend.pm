# --
# Copyright (C) 2012 Znuny GmbH, https://znuny.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::zh_CN_ZnunyEscalationSuspend;

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
