/*
 ****************************************************************************
  Copyright © 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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

--
-- we can not delete machine from frontend without this fix
--
-- Created from revision 698 of opsqa svn
--
-- To make it possible to call such things in scripts, I named all foreign keys!
-- Lukas Lipavsky <llipavsky@suse.cz>

ALTER TABLE config DROP FOREIGN KEY config_ibfk_1;                
ALTER TABLE config_module DROP FOREIGN KEY config_module_ibfk_1;  
ALTER TABLE config_module DROP FOREIGN KEY config_module_ibfk_2;  
ALTER TABLE group_machine DROP FOREIGN KEY group_machine_ibfk_1;  
ALTER TABLE group_machine DROP FOREIGN KEY group_machine_ibfk_2;  
ALTER TABLE job DROP FOREIGN KEY job_ibfk_1;                      
ALTER TABLE job_on_machine DROP FOREIGN KEY job_on_machine_ibfk_3;
ALTER TABLE job_on_machine DROP FOREIGN KEY job_on_machine_ibfk_1;
ALTER TABLE job_on_machine DROP FOREIGN KEY job_on_machine_ibfk_4;
ALTER TABLE job_on_machine DROP FOREIGN KEY job_on_machine_ibfk_2;
ALTER TABLE machine DROP FOREIGN KEY machine_ibfk_2;              
ALTER TABLE machine DROP FOREIGN KEY machine_ibfk_1;              
ALTER TABLE machine DROP FOREIGN KEY machine_ibfk_3;              
ALTER TABLE machine DROP FOREIGN KEY machine_ibfk_4;              
ALTER TABLE machine DROP FOREIGN KEY machine_ibfk_5;              
ALTER TABLE module DROP FOREIGN KEY module_ibfk_1;                
ALTER TABLE module_part DROP FOREIGN KEY module_part_ibfk_1;      

ALTER TABLE config ADD CONSTRAINT fk_config_machine_id_machine_machine_id FOREIGN KEY (`machine_id`) REFERENCES `machine` (`machine_id`) ON DELETE CASCADE;
ALTER TABLE config_module ADD CONSTRAINT fk_config_module_config_id_config_config_id FOREIGN KEY (`config_id`) REFERENCES `config` (`config_id`) ON DELETE CASCADE;
ALTER TABLE config_module ADD CONSTRAINT fk_config_module_module_id_module_module_id FOREIGN KEY (`module_id`) REFERENCES `module` (`module_id`) ON DELETE CASCADE;
ALTER TABLE group_machine ADD CONSTRAINT fk_group_machine_group_id_group_group_id FOREIGN KEY (`group_id`) REFERENCES `group` (`group_id`) ON DELETE CASCADE;
ALTER TABLE group_machine ADD CONSTRAINT fk_group_machine_machine_id_machine_machine_id FOREIGN KEY (`machine_id`) REFERENCES `machine` (`machine_id`) ON DELETE CASCADE;
ALTER TABLE job ADD CONSTRAINT fk_job_job_status_id_job_status_job_status_id FOREIGN KEY (`job_status_id`) REFERENCES `job_status` (`job_status_id`);
ALTER TABLE job_on_machine ADD CONSTRAINT fk_job_on_machine_job_id_job_job_id FOREIGN KEY (`job_id`) REFERENCES `job` (`job_id`) ON DELETE CASCADE;
ALTER TABLE job_on_machine ADD CONSTRAINT fk_job_on_machine_machine_id_machine_machine_id FOREIGN KEY (`machine_id`) REFERENCES `machine` (`machine_id`) ON DELETE CASCADE;
ALTER TABLE job_on_machine ADD CONSTRAINT fk_job_on_machine_config_id_config_config_id FOREIGN KEY (`config_id`) REFERENCES `config` (`config_id`) ON DELETE CASCADE;
ALTER TABLE job_on_machine ADD CONSTRAINT fk_job_on_machine_job_status_id_job_status_job_status_id FOREIGN KEY (`job_status_id`) REFERENCES `job_status` (`job_status_id`);
ALTER TABLE machine ADD CONSTRAINT fk_machine_machine_status_id_machine_status_machine_status_id FOREIGN KEY (`machine_status_id`) REFERENCES `machine_status` (`machine_status_id`);
ALTER TABLE machine ADD CONSTRAINT fk_machine_arch_id_arch_arch_id FOREIGN KEY (`arch_id`) REFERENCES `arch` (`arch_id`);
ALTER TABLE machine ADD CONSTRAINT fk_machine_product_arch_id_arch_arch_id FOREIGN KEY (`product_arch_id`) REFERENCES `arch` (`arch_id`);
ALTER TABLE machine ADD CONSTRAINT fk_machine_product_id_product_product_id FOREIGN KEY (`product_id`) REFERENCES `product` (`product_id`);
ALTER TABLE machine ADD CONSTRAINT fk_machine_release_id_release_release_id FOREIGN KEY (`release_id`) REFERENCES `release` (`release_id`);
ALTER TABLE module ADD CONSTRAINT fk_module_module_name_id_module_name_module_name_id FOREIGN KEY (`module_name_id`) REFERENCES `module_name` (`module_name_id`);
ALTER TABLE module_part ADD CONSTRAINT fk_module_part_module_id_module_module_id FOREIGN KEY (`module_id`) REFERENCES `module` (`module_id`) ON DELETE CASCADE;


