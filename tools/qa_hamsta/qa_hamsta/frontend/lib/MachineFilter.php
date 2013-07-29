<?php

class MachineFilter
{

	private $machine_list = array ();
	private $search_fields = array ();
	private $match_fields= array ();
	private $search_text = "";

	private function _is_machine_exist($machine, $machine_list)
	{
		$ret = false;
		
		if ( !is_array($machine_list))
			return false;
		foreach($machine_list as $m)
		{
			if ($machine->get_id() != $m->get_id())
				continue;
			else
				$ret = true;
		}
		return $ret;
	}

	public function __construct ($machines, $text, $search_fields = array ())
	{
		$this->machine_list = $machines;
		$this->search_fields = $search_fields;
		$this->search_text = $text;
	}

	public function setSearchFields ($fields_array)
	{
		$this->search_fields = $fields_array;
	}

	public function getSearchFields ()
	{
		return array_unique($this->search_fields);
	}
	
	public function setMachines($machines)
	{
		$this->machine_list= $machines;
	}

	public function getMachines()
	{
		return $this->machine_list;
	}

	public function filter()
	{
		$tmp_machine_list = array();

		if (!isset($this->machine_list) || !is_array($this->machine_list))
			return;
		if (!isset($this->search_fields) || !is_array($this->search_fields))
			return;

		//foreach (array_keys($this->search_fields) as $field)
		foreach ($this->search_fields as $field)
		{
			$fname = "get_" . $field;	
			foreach ($this->machine_list as $machine)
			{
				if (! method_exists($machine, $fname))
					continue;
				$value = $machine->$fname();
				//if (preg_match($this->search_text, $value) == 1)
				if ($value && strstr($value, $this->search_text))
				{
					if (!in_array($field, $this->match_fields))
						$this->match_fields[] = $field;
					
					if (count($tmp_machine_list) == 0)
						$tmp_machine_list[] = $machine;
					else 
					{
						if (!$this->_is_machine_exist($machine, $tmp_machine_list))
							$tmp_machine_list[] = $machine;
					}
				}
			}
		}
		return $tmp_machine_list;
	}

	public function getMatchFields ()
	{
		return $this->match_fields;
	}
	

}
