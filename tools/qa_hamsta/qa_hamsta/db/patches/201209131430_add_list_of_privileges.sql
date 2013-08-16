/*
****************************************************************************
  Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.

  THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
  CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
  RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
  THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
  THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
  TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
  PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
  PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
  AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
  LIABILITY.

  SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
  WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
  AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
  LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
  OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
  WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
  ****************************************************************************
 */

INSERT INTO privilege (privilege, descr) values ('machine_powerswitch', 'Start or restart or poweroff machine');
INSERT INTO privilege (privilege, descr) values ('machine_delete', 'Delete machine');
INSERT INTO privilege (privilege, descr) values ('machine_reinstall', 'Reinstall machine');
INSERT INTO privilege (privilege, descr) values ('machine_edit_reserve', 'Reserve machine');
INSERT INTO privilege (privilege, descr) values ('machine_free', 'Free machine');
INSERT INTO privilege (privilege, descr) values ('machine_sed_job', 'Send job to machine');
INSERT INTO privilege (privilege, descr) values ('machine_vnc', 'Open VNC viewer to machine');
INSERT INTO privilege (privilege, descr) values ('machine_terminal', 'Open terminal to machine');
INSERT INTO privilege (privilege, descr) values ('machine_merge', 'Merge machines');
INSERT INTO privilege (privilege, descr) values ('machine_add_to_group', 'Add machine to group');
INSERT INTO privilege (privilege, descr) values ('machine_remove_from_group', 'Remove machine from group');
INSERT INTO privilege (privilege, descr) values ('group_create', 'Create group');
INSERT INTO privilege (privilege, descr) values ('group_edit', 'Edit group');
INSERT INTO privilege (privilege, descr) values ('group_delete', 'Delete group');
INSERT INTO privilege (privilege, descr) values ('group_list_machines', 'List machines in group');
INSERT INTO privilege (privilege, descr) values ('validation_start', 'Start validation test');
INSERT INTO privilege (privilege, descr) values ('autopxe_start', 'Install machine with AutoPXE');
