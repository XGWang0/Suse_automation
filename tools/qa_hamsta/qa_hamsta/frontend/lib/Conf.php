<?php

require_once ('Zend/Config/Ini.php');

class Conf
{
  public static function getIniConfig($filename, $section, $options = false) {
    return new Zend_Config_Ini($filename, $section, $options);
  }
}

?>