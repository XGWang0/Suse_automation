<?php
/**
 * Contents of the <tt>mm_job</tt> page
 */
if (!defined('HAMSTA_FRONTEND')) {
	$go = 'send_job';
	return require("index.php");
}

?><p class="text-main">Assign your machines to roles. Roles may have minimal and maximal count of machines, and no machine can be in two different roles.</p>

<form action="index.php?go=mm_job" method="post" name="predefinedjobs">

<?php

$vars_preserve=array('a_machines','filename','mailto');
preserve_request($vars_preserve);

# form data prepared in inc/mm_job.php
print $formdata; 

?>
<br/><br/>
<input type="submit" name="submit" value="Start multi-machine job"/>
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
