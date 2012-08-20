<?php
require_once('qadb.php');
common_header(array('title'=>'Board'));

$board_id  =http('board_id');
$action   =http('action');
$submit   =http('submit');
$wtoken   =http('wtoken');
$topic_got=http('topic');

# updates
if(token_read($wtoken))
{
	if( $submit=='delete_board' && $board_id )
	{
		transaction();
		update_result( board_delete($board_id) );
		commit();
		$board_id=0;
	}
	else if( $submit=='update_board' )
	{
		transaction();
		if( $board_id )
			update_result( board_update( $board_id, $topic_got ) );
		else
			update_result( board_insert( $topic_got ), true );
		commit();
		$board_id=0;
	}
}

board_update_last();

# input form
$text='';
if( $board_id )
	$text=board_get_topic($board_id);

$what=array(
	array('topic','',$text,TEXT_AREA,$board_id ? "Editing":"New post"),
	array('wtoken','',token_generate(),HIDDEN),
	array('submit','','update_board',HIDDEN),
);
if( $board_id )
	$what[] = array('board_id','',$board_id,HIDDEN);
print html_search_form('board.php',$what,array('submit'=>($board_id ? 'Modify':'New post')));

# list board data
$data=board_list(1,array(100));
table_translate($data,array(
	'enums'=>array('created_by'=>'tester','updated_by'=>'tester'),
	'ctrls'=>array(
		'edit'=>'board.php?view=edit&board_id=',
		'delete'=>'confirm.php?confirm=b&board_id='
	)
));

# convert newlines
for( $i=0; $i<count($data); $i++ )
	$data[$i]['topic'] = nl2br($data[$i]['topic']);
print html_table($data,array('id'=>'board_list','sort'=>'issss','class'=>'tbl controls'));

# quit
print html_footer();
?>
