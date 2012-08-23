<?php
/* ****************************************************************************
  Copyright (c) 2012 Unpublished Work of SUSE. All Rights Reserved.
  
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
 * User
 *
 * Representation of an authenticated user.
 *
 * @author David Mulder <dmulder@suse.com>
 */
class User {

	/**
	 * fields
	 *
	 * @var array Associative array containing the values of all database
	 * 	of this user
	 */
	private $fields;

	/**
	 * __construct
	 *
	 * Creates a new instance of User.
	 *
	 * @param array $fields Values of all database fields
	 */
	function __construct($fields) {
		$this->fields = $fields;
	}

	/**
	 * add_user
	 *
	 * Adds a user to the database.
	 *
	 * @param string openid url
	 * @param string name User's name
	 * @param string email User's email address
	 */
	static function add_user($openid, $name, $email) {
		$stmt = get_pdo()->prepare('INSERT INTO user (id, name, email) VALUES(:user_login, :name, :email)');
		$stmt->bindParam(':user_login', $openid);
		$stmt->bindParam(':name', $name);
		$stmt->bindParam(':email', $email);
		$stmt->execute();
	}

	/**
	 * get_by_openid
	 *
	 * @param string openid url
	 * @access public
	 * @return User object with values fetched from database.
	 */
	static function get_by_openid($openid) {
		if (!($stmt = get_pdo()->prepare('SELECT * FROM user WHERE user_login = :openid'))) {
			return null;
		}
		$stmt->bindParam(':openid', $openid);

		$stmt->execute();
		$row = $stmt->fetch(PDO::FETCH_ASSOC);

		return $row ? new User($row) : null;
	}

	/**
	 * get_openid
	 *
	 * @return User openid url
	 */
	function get_openid() {
		if( isset($this->fields["user_login"]) )
			return $this->fields["user_login"];
		else
			return NULL;
	}

	/**
	 * get_name
	 *
	 * @return User name
	 */
	function get_name() {
		if( isset($this->fields["name"]) )
			return $this->fields["name"];
		else
			return NULL;
	}

	/**
	 * get_email
	 *
	 * @return User email address
	 */
	function get_email() {
		if( isset($this->fields["email"]) )
			return $this->fields["email"];
		else
			return NULL;
	}

	function set_email($email)  {
		$stmt = get_pdo()->prepare('UPDATE user SET email = :email WHERE user_login = :openid');
		$id = $this->get_openid();
		$stmt->bindParam(':openid', $id);
		$stmt->bindParam(':email', $email);
		$stmt->execute();
	}

	function set_username($name) {
		$stmt = get_pdo()->prepare('UPDATE user SET name = :name WHERE user_login = :openid');
		$id = $this->get_openid();
		$stmt->bindParam(':openid', $id);
		$stmt->bindParam(':name', $name);
		$stmt->execute();
	}
}

