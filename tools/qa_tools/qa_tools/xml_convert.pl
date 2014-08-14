#!/usr/bin/perl -w
#****************************************************************************
# Copyright (c) 2014 Unpublished Work of SUSE. All Rights Reserved.
#
# THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
# CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
# RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
# THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
# THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
# TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
# PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
# PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
# AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND   CIVIL
# LIABILITY.
#
# SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
# AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
# LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
# WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
# ****************************************************************************
# This tools is created to convert original xml into new format
# to adapt new multi-machine job .

use strict;
use Clone qw(clone);
use XML::Simple;
use Data::Dumper;

# By default, add one part.
sub add_parts($) {
    my $root = shift;

    if (!$root->{'parts'}) {
        $root->{'parts'} = [{
                                'part' => {  'name' => 'default',
                                             'id' => 1
                                }
        }];
    }
}

# By default
# Single machine job, add one role,move commands under role.
# Multi-machine job, re-organize role tag content.
sub add_roles($) {
    my $root = shift;

    if (&is_mm_xml($root)) {
        my $roles = $root->{'roles'}->[0]->{'role'};
        foreach my $role (keys(%$roles)) {
            my $role_id = $roles->{$role}->{'id'};
            my $worker = clone($root->{'commands'}->[0]->{'worker'});
            my @command = grep { $_->{'role_id'} eq $role_id } @{$worker->[0]->{'command'}};
            map { delete $_->{'role_id'} } @command;
            $worker->[0]->{'command'} = \@command;
            $roles->{$role}->{'commands'} = {
                                    'part_id' => '1',
                                    'worker' => $worker
            };
            delete $roles->{$role}->{'id'};
            foreach (keys(%{$root->{'commands'}->[0]})) {
                $roles->{$role}->{'commands'}->{$_} = $root->{'commands'}->[0]->{$_} if $_ ne 'worker';
            }
        }
        $root->{'roles'} = [ $root->{'roles'}->[0]->{'role'} ];
        # avoid attributes as elements
        $root->{'parameters'} = [ $root->{'parameters'}->[0]->{'parameter'} ] if $root->{'parameters'};
    } else {
        $root->{'roles'} = [{
                            'role' => {
                                    'name' =>'default',
                                    'commands' => {
                                            'part_id' => '1',
                                    }
                            }
        }];
        foreach (keys(%{$root->{'commands'}->[0]})) {
            $root->{'roles'}->[0]->{'role'}->{'commands'}->{$_} = $root->{'commands'}->[0]->{$_};
        }
    }
    delete $root->{'commands'};
}

# Move tags
# Tasks:
#     move <job_id> and <useinfo> into <motd>
#     move <reboot> as attribute of <command>
sub mv_tags($) {
    my $root = shift;
    my $conf = $root->{'config'}->[0];

    #modify motd
    if ($conf->{'job_id'} || $conf->{'useinfo'}) {
        $conf->{'motd'}->[0] = $conf->{'job_id'}->[0].":".
                                $conf->{'useinfo'}->[0]." ".
                                $conf->{'motd'}->[0];
    }
    #move <reboot> into <command> as an attribute.
    if ($conf->{'reboot'}) {
        my $roles = $root->{'roles'}->[0];
        foreach (keys(%$roles)) {
            my $cmd = $roles->{$_}->{'commands'}->{'worker'}->[0]->{'command'};
            $cmd->[0]->{'reboot'} = $conf->{'reboot'}->[0] if $cmd;
        }
    }    
    #fix <mail> tag issue, when content is blank.
    $conf->{'mail'}->[0]->{'content'} = '' if !$conf->{'mail'}->[0]->{'content'};
}

# Remove useless tags which are under <config/>
# such as:
# <distributable/>, <parallel/>, <logdir/>, <update/>
# <job_id/>, <useinfo/>, <reboot/>
# Remove mail attribute from <worker><notify> tag.
sub rm_tags($) {
    my $root = shift;
    my @list = (
                'distributable',
                'parallel',
                'logdir',
                'update',
                'job_id',
                'useinfo',
                'reboot'
    );

    map { delete $root->{'config'}->[0]->{$_} } @list;
    
    # remove mail attribute from <worker><notify> tag.
    my $roles = $root->{'roles'}->[0];
    foreach (keys(%$roles)) {
        my $wk = $roles->{$_}->{'commands'}->{'worker'}->[0];
        if ($wk->{'notify'}->[0]) {
            my $notify = $wk->{'notify'}->[0];
            map { $_ eq 'mail' && delete $notify->{$_} } keys(%{$notify});
        }
    }
}

# Convert MM(Multi-Machine) job to new format.
sub convert_xml($) {
    my $root = shift;
    add_parts($root);
    add_roles($root);
    mv_tags($root);
    rm_tags($root);
}

# Check if old xml is for multi-machine job.
sub is_mm_xml($) {
    my $root = shift;
    if ($root->{'roles'}) {
        return 1;
    } else {
        return 0;
    }
}
# Parse XML as hash
sub parse_xml($) {
    my $xmlfile = shift;

    die "Souce XML $xmlfile does not exist!" if !(-e $xmlfile);
    my $xs = XML::Simple->new();
    my $ref = $xs->XMLin($xmlfile, ForceArray=>1, SuppressEmpty => undef);

    return $ref;
}

# Write result to new xml file
sub save_xml($$) {
    my $out_file = shift;
    my $root = shift;

    XMLout(
        $root,
        XmlDecl => '<?xml version="1.0"?>',
        RootName => 'job',
        NoEscape => 1,
        GroupTags => {
                      parts => 'part',
                      roles => 'role',
                      parameters => 'parameter'
                     },
        OutputFile => $out_file
    );
}

sub usage {
    print "Usage $0 <OLD_XML> <NEW_XML>\n";
}

sub main {

    if ($#ARGV != 1) {
        usage();
        exit 1;
    }

    my $old_xml = $ARGV[0];
    my $new_xml = $ARGV[1];

    my $root = parse_xml($old_xml);
    convert_xml($root);
    save_xml($new_xml,$root);
}

&main();
