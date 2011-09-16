<?php

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
