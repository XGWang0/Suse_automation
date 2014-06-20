<?php

require_once ('Zend/Config.php');

/**
 * This is a factory class for creation of different types of
 * configuration.
 *
 * @package Configuration
 * @author Pavel Kačer <pkacer@suse.com>
 * @version 1.0.0
 *
 * @copyright
 * Copyright (c) 2013 Unpublished Work of SUSE. All Rights Reserved.<br />
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
class ConfigFactory {

	private static $configuration = null;

	private static $defaultConfig = array (
		'database' => array (
			'adapter' => 'Pdo_Mysql',
			'params' => array (
				'host' => 'localhost',
				'username' => 'hwdb',
				'password' => '',
				'dbname' => 'hamsta_db',
				'charset' => 'UTF8'
				)
			),
		'cmdline' => array (
			'host' => 'localhost',
			'port' => '18431'
			),
		'authentication' => array (
			'use' => true,
			'method' => 'password'
			),
		'timezone' => array (
			'default' => 'Europe/Prague'
			)
		);

	/* This class should not be instantiated. */
	private function __construct () {}

	/* Creates requested type of configuration. It either reads it from
	 * the file or uses array of data to initialize.
	 *
	 * <p>If you want to use the Zend_Config, leave the `type' value empty
	 * or null. The value of data parameter is then used. Othewise the
	 * data parameter is ignored.</p>
	 *
	 * <p>If you need to access the configuration object, you have to
	 * first initialize it by calling this method with parameters. All
	 * subsequent calls to of this metho can be without parameters. The
	 * configufation created during the first call is returned.</p>
	 * 
	 * @param string $type Type of the configuration. Includes types
	 * available in Zend framework and can include also other
	 * types. Supported values are 'Ini', 'Json', 'Xml', 'Yaml'. If the
	 * value is empty or null, the type Zend_Config is used.
	 *
	 * @param string $file Name of the file with configuration.
	 *
	 * @param mixed $section Name of the section of the configuration to use.
	 *
	 * @param boolean|array $options Dependant of the configuration type
	 * used. See the Zend documentation.
	 *
	 * @param array $data Configuration values used with
	 * Zend_Config. See above for explanation.
	 *
	 * @return \Zend_Config The instance of requested configuration.
	 *
	 * @throws \Exception An exception when the requested type is not known.
	 */
	public static function build ($type = "", $file = null, $section = null,
				      $options = null, $data = null) {
		if (isset (self::$configuration) && empty ($type)) {
			return self::$configuration;
		}

		/* Get default configuration specified by this class. */
		self::$configuration = new Zend_Config (self::$defaultConfig, TRUE);
		/* Variable to hold the custom configuration. */
		$customConfig = null;

		$class = 'Zend_Config' . (empty ($type)
					  ? ""
					  : "_" . $type);

		if (! empty ($type)) {
			require_once ("Zend/Config/$type.php");	
		}

		if (! class_exists ($class)) {
			throw new Exception ('The requested class does not exist: ' . $class);
		}

		switch ($type) {
		case "Ini":
		case "Json":
		case "Xml":
		case "Yaml":
			/* This creates any of the types above. */
			$customConfig = new $class ($file, $section, $options);
		break;
		default:
			/* This is the default Zend_Config class. */
			$customConfig = new $class ($data, $options);
		}

		/* Merge defaults with customized values. */
		self::$configuration = self::$configuration->merge ($customConfig);
		return self::$configuration;
	}

}

?>
