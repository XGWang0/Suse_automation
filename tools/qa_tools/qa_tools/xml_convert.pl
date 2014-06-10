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
use Getopt::Std;
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
			my $command = $worker->[0]->{'command'};
			for (my $i=0; $i<=$#$command; $i++) {
				if ($command->[$i]->{'role_id'} ne $role_id) {
					if($i != $#$command) {
						my $temp = $command->[$i];
						$command->[$i] = $command->[$#$command];
						$command->[$#$command] = $temp;
					}
					pop @$command;
				} else {
					delete $command->[$i]->{'role_id'};
				}
			}
			$roles->{$role}->{'commands'} = {
									'part_id' => '1',
									'worker' => $worker
			};
		}
		$root->{'roles'} = [ $root->{'roles'}->[0]->{'role'} ];
	} else {
		$root->{'roles'} = [{
							'role' => {
									'name' =>'default',
									'num_min' => '1',
									'num_max' => '1',
									'id' => '1',
									'commands' => {
											'part_id' => '1',
											'worker' => $root->{'commands'}->[0]->{'worker'}
									}
							}
		}];
	}
	delete $root->{'commands'};
}

# Move rpm tag from per job to per role.
sub move_rpms($) {
	my $root = shift;
	if ($root->{'config'}->[0]->{'rpm'}) {
		$root->{'roles'}->[0]->{'role'}->{'rpm'} = $root->{'config'}->[0]->{'rpm'};
		delete $root->{'config'}->[0]->{'rpm'};
	}
}

# Convert MM(Multi-Machine) job to new format.
sub convert_xml($) {
	my $root = shift;
	add_parts($root);
	add_roles($root);
	move_rpms($root);
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

	my $xml = XMLout(
			$root,
			XmlDecl => '<?xml version="1.0"?>',
			RootName => 'job',
			GroupTags => {parts => 'part', roles => 'role', 'config' => 'mail'},
			OutputFile => $out_file
	);
	print(Dumper($xml));
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
	print(Dumper($root));
	convert_xml($root);
	save_xml($new_xml,$root);
}

&main();
