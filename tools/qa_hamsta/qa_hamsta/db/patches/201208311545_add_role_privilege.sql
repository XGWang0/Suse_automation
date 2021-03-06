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

CREATE TABLE role_privilege (
       role_id       INTEGER NOT NULL COMMENT 'Reference to role.',
       privilege_id  INTEGER NOT NULL COMMENT 'Reference to privilege',
       valid_since   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Set at creation.',
       valid_until   DATETIME DEFAULT NULL COMMENT 'End of validation. If null, the privilege has unlimited validity.',
       KEY `fk_role_privilege_role_id`(`role_id`),
       KEY `fk_role_privilege_privilege_id`(`privilege_id`),
       CONSTRAINT fk_role_privilege_role_id FOREIGN KEY (`role_id`) REFERENCES `user_role` (`role_id`) ON DELETE RESTRICT,
       CONSTRAINT fk_role_privilege_privilege_id FOREIGN KEY (`privilege_id`) REFERENCES  `privilege` (`privilege_id`) ON DELETE RESTRICT,
       PRIMARY KEY (`role_id`, `privilege_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT 'Holds list of available user privileges.';
