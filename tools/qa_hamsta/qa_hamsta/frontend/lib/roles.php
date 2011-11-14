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
  * Reads XML using SimpleXML.
  * @param string $path the path to the XML
  * @return SimpleXMLElement the parsed XML
  * NOTE: SimpleXML sucks a lot.
  **/
function xml_read( $path )	{
	return simplexml_load_file($path,'SimpleXMLElement', LIBXML_NONET);	
}

/**
  * Reads roles info.
  * @param SimpleXMLElement $xml the job XML
  * @return array of roles - array( $id => array( 'name'=>$name, 'id'=>$id, 'num_min'=>$num_min, 'num_max'=>$num_max ), ... )
  **/
function roles_read( $xml )
{
	$ret=array();
	foreach( $xml->roles->role as $role )
	{
		$r=array();
		$id=(integer)$role['id'];
		
		if( !isset($id) )
			continue;

		foreach( $role->attributes() as $key=>$val )
			$r[(string)$key]=(string)$val;

		$ret[0+$id]=$r;
	}
	return $ret;
}


/**
  * Assigns machines to roles.
  * @param SimpleXMLElement $xml
  * @param array $roles role/machine assignment, array( 'role_id' => array( array('name'=>$hostname1, 'ip'=>$IP_address1 ), array('name'=>$hostname2, 'ip'=>$IP_address2), ...), ... )
  **/
function roles_assign( &$xml, $roles )
{
	$cnt=count($xml->roles->children());
	foreach( $xml->roles->role as $role )
	{
		$id = (integer)$role['id'];
		
		if( !$roles[$id] )
			continue;
		
		foreach( $roles[$id] as $machine )
		{
			$m = $role->addChild('machine');
			foreach( $machine as $key=>$val )
				$m[$key]=$val;
		}
		
	}
}

?>
