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

INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_powerswitch_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_delete_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_reinstall_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_edit_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_free_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_send_job_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_vnc_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_terminal_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_merge_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_add_to_group_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
INSERT INTO role_privilege (privilege_id, role_id) VALUES ((SELECT privilege_id FROM privilege WHERE privilege = 'machine_remove_from_group_reserved'), (SELECT role_id FROM user_role WHERE role = 'admin'));
