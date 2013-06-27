<?php
/* ****************************************************************************
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

/**
 * Contents of the <tt>mm_job</tt> page
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'mm_job';
	return require("index.php");
}

?><p class="text-main">Assign your machines to roles. Roles may have minimal and maximal count of machines, and no machine can be in two different roles.</p>

<form action="index.php?go=mm_job" method="post" name="predefinedjobs">

<?php

#$vars_preserve=array('a_machines','filename','mailto');
$vars_preserve=array('a_machines', 'mailto');
print '<input type="hidden" name="filename" value="'.$filename.'"/>'."\n";
preserve_request($vars_preserve);

# form data prepared in inc/mm_job.php
print $formdata; 

?>

</form>
<?php

function preserve_request($vars)
{
	foreach( $_REQUEST as $key=>$val )
	{
		if( !in_array( $key, $vars ) )
			continue;
		if( is_array($val) )
		{
			foreach( $val as $v )
				print '<input type="hidden" name="'.$key.'[]" value="'.$v.'"/>'."\n";
		}
		else
			print '<input type="hidden" name="'.$key.'" value="'.$val.'"/>'."\n";
		
	}
}
?>
