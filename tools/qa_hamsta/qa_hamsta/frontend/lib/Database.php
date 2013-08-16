<?php

require_once ('Zend/Db.php');
require_once ('ConfigFactory.php');

class Database extends Zend_Db
{
	public static function build ($adapter = null, $config = array ())
	{
		if (isset ($adapter)) {
			parent::factory ($adapter, $config);
		} else {
			$config = ConfigFactory::build ();
			return parent::factory ($config->database);
		}
	}

	public static function buildSelect ($db, $table_name, $columns,
					    $andConds = null, $orConds = null)
	{
		$select = $db->select ();
		$select->from ($table_name);
		$select->columns ($columns);

		if (isset ($andConds)) {
			foreach ($andConds as $cond => $val) {
				$select->where ($cond, $val);
			}
		}

		if (isset ($orConds)) {
			foreach ($orConds as $cond => $val) {
				$select->orWhere ($cond, $val);
			}
		}
		return $select;
	}
}

?>
