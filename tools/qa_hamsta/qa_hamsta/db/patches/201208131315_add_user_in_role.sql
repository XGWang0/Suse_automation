/*
****************************************************************************
  Copyright (c) 2012 Unpublished Work of SUSE. All Rights Reserved.

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

/* Alter the table `user`, changing to InnoDB engine which supports
   foreing keys. */
ALTER TABLE `user` ENGINE = InnoDB;

/* Need to create index on referenced attribute or the next create fails. */
ALTER TABLE `user` ADD PRIMARY KEY (`id`);

/* Now the connecting table can be created. */
CREATE TABLE user_in_role (
       user_id            varchar(255) NOT NULL,
       role_id            int      NOT NULL,
       KEY `fk_user_in_role_user_id`(`user_id`),
       KEY `fk_user_in_role_role_id`(`role_id`),
       CONSTRAINT fk_user_in_role_user_id FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE RESTRICT,
       CONSTRAINT fk_user_in_role_role_id FOREIGN KEY (`role_id`) REFERENCES  `user_role` (`id`) ON DELETE RESTRICT,
       PRIMARY KEY (`user_id`, `role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin;