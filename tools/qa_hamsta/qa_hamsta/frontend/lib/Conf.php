<?php
require_once ('Zend/Config/Ini.php');

/**
 * Class serves as wrapper around Zend_Config class.
 *
 * Provides methods for using configuration.
 *
 * @package Configuration
 * @author Pavel Kačer <pkacer@suse.com>
 * @version 1.0.0
 *
 * @copyright
 * Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.<br />
 * <br />
 * THIS IS AN UNPUBLISHED WORK OF SUSE.  IT CONTAINS SUSE'S
 * CONFIDENTIAL, PROPRIETARY, AND TRADE SECRET INFORMATION.  SUSE
 * RESTRICTS THIS WORK TO SUSE EMPLOYEES WHO NEED THE WORK TO PERFORM
 * THEIR ASSIGNMENTS AND TO THIRD PARTIES AUTHORIZED BY SUSE IN WRITING.
 * THIS WORK IS SUBJECT TO U.S. AND INTERNATIONAL COPYRIGHT LAWS AND
 * TREATIES. IT MAY NOT BE USED, COPIED, DISTRIBUTED, DISCLOSED, ADAPTED,
 * PERFORMED, DISPLAYED, COLLECTED, COMPILED, OR LINKED WITHOUT SUSE'S
 * PRIOR WRITTEN CONSENT. USE OR EXPLOITATION OF THIS WORK WITHOUT
 * AUTHORIZATION COULD SUBJECT THE PERPETRATOR TO CRIMINAL AND  CIVIL
 * LIABILITY.<br />
 * <br />
 * SUSE PROVIDES THE WORK 'AS IS,' WITHOUT ANY EXPRESS OR IMPLIED
 * WARRANTY, INCLUDING WITHOUT THE IMPLIED WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT. SUSE, THE
 * AUTHORS OF THE WORK, AND THE OWNERS OF COPYRIGHT IN THE WORK ARE NOT
 * LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION
 * WITH THE WORK OR THE USE OR OTHER DEALINGS IN THE WORK.
 */
class Conf extends Zend_Config
{

  /**
   * Returns a configuration class instance.
   *
   * See Zend_Config for more information.
   * 
   * @param string $filename Name of the file containing configuration.
   * @param mixed $section Name of the section in the configuration to use.
   * @param boolean|array $options Additional options to the configuration.
   *
   * @return Zend_Config_Ini An instance of that class.
   */
  public static function getIniConfig($filename, $section, $options = false) {
    return new Zend_Config_Ini($filename, $section, $options);
  }

  /**
   * Gets values from config.php.
   *
   * This should be temporary solution until all configuration is
   * replaced by ini file. Now the crazy array just copies the
   * hamsta.ini file.
   */
  function __construct ($array, $allowModifications)
  {
    if (! isset ($array))
      {
        $use_auth = (USE_AUTH == 'true') ? true : false;
        $array = array ('database' =>
                        array('adapter' => 'Pdo_Mysql',
                              'params' =>
                              array (
                                     'host' => 'localhost',
                                     'dbname' => 'hamsta_db',
                                     'username' => PDO_USER,
                                     'password' => PDO_PASSWORD
                                     )
                              ),
                        'authentication' =>
                        array ('use' => $use_auth,
                               'method' => AUTHENTICATION_METHOD,
                               'openid' => 
                               array ('url' => OPENID_URL)
                               )
                        );
      }
    parent::__construct ($array, $allowModifications);
  }

}


?>
