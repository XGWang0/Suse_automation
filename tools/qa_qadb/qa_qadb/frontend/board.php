<?php
require_once('qadb.php');
common_header(array('title'=>'Board'));

$boardID  =http('boardID');
$action   =http('action');
$submit   =http('submit');
$wtoken   =http('wtoken');
$topic_got=http('topic');

# updates
if(token_read($wtoken))
{
	if( $submit=='delete_board' && $boardID )
	{
		transaction();
		update_result( board_delete($boardID) );
		commit();
		$boardID=0;
	}
	else if( $submit=='update_board' )
	{
		transaction();
		if( $boardID )
			update_result( board_update( $boardID, $topic_got ) );
		else
			update_result( board_insert( $topic_got ), true );
		commit();
		$boardID=0;
	}
}

board_update_last();

# input form
$text='';
if( $boardID )
	$text=board_get_topic($boardID);

$what=array(
	array('topic','',$text,TEXT_AREA,$boardID ? "Editing":"New post"),
	array('wtoken','',token_generate(),HIDDEN),
	array('submit','','update_board',HIDDEN),
);
if( $boardID )
	$what[] = array('boardID','',$boardID,HIDDEN);
print html_search_form('board.php',$what,array('submit'=>($boardID ? 'Modify':'New post')));

# list board data
$data=board_list(1,array(100));
table_translate($data,array(
	'enums'=>array('created_by'=>'testers','updated_by'=>'testers'),
	'ctrls'=>array(
		'edit'=>'board.php?view=edit&boardID=',
		'delete'=>'confirm.php?confirm=b&boardID='
	)
));

# convert newlines
for( $i=0; $i<count($data); $i++ )
	$data[$i]['topic'] = nl2br($data[$i]['topic']);
print html_table($data,array('id'=>'board_list','sort'=>'issss','class'=>'tbl controls'));

# quit
print html_footer();
?>
