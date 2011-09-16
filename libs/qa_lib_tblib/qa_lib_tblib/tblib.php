<?php

/**
  * Library functions that require both DB and HTML library.
  * @package TBLib
  * @filesource
  * @license http://opensource.org/licenses/gpl-2.0.php GNU General Public License
  **/

/** DB-related functions */
require_once('tblib_db.php');

/** HTML-related functions */
require_once('tblib_html.php');



/**
  * Processes a table, translates enums, makes links and controls.
  * @param array &$table 2D table
  * @param array $what array( 'links'=>$links, 'enums'=>$enums, 'ctrls'=>$ctrls )
  * @return the converted table
  * @see enum_translate_row(), make_links_row(), make_controls_row(), transform_url_row()
  **/
function &table_translate(&$table, $what=array())
{
	$links=hash_get($what,'links',null,false);
	$enums=hash_get($what,'enums',null,false);
	$ctrls=hash_get($what,'ctrls',null,false);
	$urls =hash_get($what,'urls', null,false);	
	$header=hash_get($what,'header',true,false);
	$ctrl_col=hash_get($what,'ctrl_col',null,false);
	if( $header && $enums )
		foreach(array_keys($enums) as $col)
			$table[0][$col]=preg_replace('/ID$/i','',$table[0][$col]);
	$cnt=count($table);
	for( $i=($header ? 1:0); $i<$cnt; $i++ )
	{
		$orig=$table[$i];
		if( $enums )
			enum_translate_row($table[$i],$enums);
		if( $links )
			make_links_row($table[$i],$orig,$links);
		if( $ctrls )
		{
			$vals=array_values($orig);
			$index_val = (is_null($ctrl_col) ? $vals[0]: $orig[$ctrl_col]);
			make_controls_row($table[$i],$index_val,$ctrls);
		}
		if( $urls )
			transform_url_row($table[$i],$urls);
	}
	if( $ctrls && $header )
		$table[0][]='controls';
	return $table;
}

/**
  * Like update_result(), but also closes transaction with commit (on success) or rollback (on failure).
  * @param int $n return value of the update operation
  * @param bool $is_insert true for insert - will consider $n as new ID
  **/
function update_result_commit($n,$is_insert=false,$msg=null)
{
	update_result($n,$is_insert,$msg);
	if( $n<0 )
		rollback();
	else
		commit();
}



?>
