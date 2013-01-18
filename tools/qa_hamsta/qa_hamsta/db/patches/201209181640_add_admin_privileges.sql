/*
****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.

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

INSERT INTO privilege (privilege, descr) VALUES ('machine_powerswitch_reserved', 'Use powerswitch of machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_delete_reserved', 'Delete a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_reinstall_reserved', 'Reinstall a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_edit_reserved', 'Edit a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_free_reserved', 'Free a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_send_job_reserved', 'Send job to a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_vnc_reserved', 'Open VNC terminal to a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_terminal_reserved', 'Open terminal to a machine reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_merge_reserved', 'Merge a machines reserved by other user');
INSERT INTO privilege (privilege, descr) VALUES ('machine_add_to_group_reserved', 'Add a machines reserved by other user into a group');
INSERT INTO privilege (privilege, descr) VALUES ('machine_remove_from_group_reserved', 'Remove a machines reserved by other user from a group');
