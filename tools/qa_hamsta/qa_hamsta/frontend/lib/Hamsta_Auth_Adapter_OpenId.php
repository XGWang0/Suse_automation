<?php

/**
 * @see Zend_Auth_Adapter_Interface
 */
require_once 'Zend/Auth/Adapter/Interface.php';
require_once 'Zend/OpenId/Exception.php';

require_once 'Hamsta_Zend_Auth_Result.php';

require_once 'Auth/OpenID.php';
require_once 'Auth/OpenID/FileStore.php';
require_once 'Auth/OpenID/Consumer.php';
require_once "Auth/OpenID/SReg.php";
require_once "Auth/OpenID/PAPE.php";

/**
 * OpenID adapter for Hamsta.
 *
 * Class provides OpenID authentication implementing the
 * Zend_Auth_Adapter_Interface.
 *
 * @package User
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
class Hamsta_Auth_Adapter_OpenId implements Zend_Auth_Adapter_Interface
{
    /**
     * The identity value being authenticated
     *
     * @var string
     */
    private $_id = null;

    /**
     * Reference to an implementation of a storage object
     *
     * @var Zend_OpenId_Consumer_Storage
     */
    private $_storage = null;

    /**
     * The URL to redirect response from server to
     *
     * @var string
     */
    private $_returnTo = null;

    /**
     * The HTTP URL to identify consumer on server
     *
     * @var string
     */
    private $_root = null;

    /**
     * Extension object or array of extensions objects
     *
     * @var string
     */
    private $_extensions = null;

    /**
     * The response object to perform HTTP or HTML form redirection
     *
     * @var Zend_Controller_Response_Abstract
     */
    private $_response = null;

    /**
     * Enables or disables interaction with user during authentication on
     * OpenID provider.
     *
     * @var bool
     */
    private $_check_immediate = false;

    /**
     * HTTP client to make HTTP requests
     *
     * @var Zend_Http_Client $_httpClient
     */
    private $_httpClient = null;

    /**
     * For holding the session values.
     */
    private $_session = null;

    /**
     * Constructor
     *
     * @param string $id the identity value
     * @param Zend_OpenId_Consumer_Storage $storage an optional implementation
     *        of a storage object
     * @param string $returnTo HTTP URL to redirect response from server to
     * @param string $root HTTP URL to identify consumer on server
     * @param mixed $extensions extension object or array of extensions objects
     * @param Zend_Controller_Response_Abstract $response an optional response
     *        object to perform HTTP or HTML form redirection
     * @return void
     */
    public function __construct($id = null,
                                Auth_OpenID_OpenIDStore $storage = null,
                                $returnTo = null,
                                $root = null,
                                $extensions = null,
                                Zend_Controller_Response_Abstract $response = null) {
        $this->_id         = $id;
	// Set storage
	if (isset ($storage)) {
		$this->_storage    = $storage;
	} else {
		$this->_storage = $this->_getDefaultStorage ();
	}

	// Set return address
	if (isset ($returnTo)) {
		$this->setReturnTo ($returnTo);
	} else {
		$this->setReturnTo ($this->_getReturnTo ());
	}

	// Set trust root
	if (isset ($root)) {
		$this->setRoot ($root);
	} else {
		$this->setRoot ($this->_getTrustRoot ());
	}

        $this->_extensions = $extensions;
        $this->_response   = $response;
    }

    private function _getDefaultStorage () {
	    $store_path = sys_get_temp_dir() . DIRECTORY_SEPARATOR
		    . 'php_openid_lib_data';
	    return new Auth_OpenID_FileStore($store_path);
    }

    /**
     * Sets the value to be used as the identity
     *
     * @param  string $id the identity value
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setIdentity($id)
    {
        $this->_id = $id;
        return $this;
    }

    /**
     * Sets the storage implementation which will be use by OpenId
     *
     * @param  Zend_OpenId_Consumer_Storage $storage
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setStorage(Auth_OpenID_FileStore $storage)
    {
        $this->_storage = $storage;
        return $this;
    }

    private function getStorage () {
	    return $this->_storage;
    }

    /**
     * Sets the HTTP URL to redirect response from server to
     *
     * @param  string $returnTo
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setReturnTo($returnTo)
    {
        $this->_returnTo = $returnTo;
        return $this;
    }

    public function getReturnTo () {
	    return $this->_returnTo;
    }

    /**
     * Sets HTTP URL to identify consumer on server
     *
     * @param  string $root
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setRoot($root)
    {
        $this->_root = $root;
        return $this;
    }

    public function getRoot () {
	    return $this->_root;
    }

    /**
     * Sets OpenID extension(s)
     *
     * @param  mixed $extensions
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setExtensions($extensions)
    {
        $this->_extensions = $extensions;
        return $this;
    }

    /**
     * Sets an optional response object to perform HTTP or HTML form redirection
     *
     * @param  string $root
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setResponse($response)
    {
        $this->_response = $response;
        return $this;
    }

    /**
     * Enables or disables interaction with user during authentication on
     * OpenID provider.
     *
     * @param  bool $check_immediate
     * @return Zend_Auth_Adapter_OpenId Provides a fluent interface
     */
    public function setCheckImmediate($check_immediate)
    {
        $this->_check_immediate = $check_immediate;
        return $this;
    }

    /**
     * Sets HTTP client object to make HTTP requests
     *
     * @param Zend_Http_Client $client HTTP client object to be used
     */
    public function setHttpClient($client) {
        $this->_httpClient = $client;
    }

    private function _getScheme() {
	    $scheme = 'http';
	    if (isset($_SERVER['HTTPS']) and $_SERVER['HTTPS'] == 'on') {
		    $scheme .= 's';
	    }
	    return $scheme;
    }


    private function _getTrustRoot() {
	    return sprintf("%s://%s:%s%s/",
			   $this->_getScheme(), $_SERVER['SERVER_NAME'],
			   $_SERVER['SERVER_PORT'],
			   dirname($_SERVER['PHP_SELF']));
    }

    private function _getReturnTo() {
	    return sprintf("%s://%s:%s%s/",
			   $this->_getScheme(), $_SERVER['SERVER_NAME'],
			   $_SERVER['SERVER_PORT'],
			   dirname($_SERVER['PHP_SELF']));
    }

    public function setSession (Zend_Session_Namespace $session) {
	    $this->_session = $session;
    }

    public function getSession () {
	    return $this->_session;
    }

    private function _getConsumer () {
	    /* Start the session if needed. */
	    require_once "Zend/Session/Namespace.php";
	    $this->setSession (new Zend_Session_Namespace ('openid_consumer'));
	    return new Auth_OpenID_Consumer($this->getStorage ());
    }

    private function _escapeHTML ($string) {
	    return htmlspecialchars ($string);
    }

    /**
     * Authenticates the given OpenId identity.
     * Defined by Zend_Auth_Adapter_Interface.
     *
     * @throws Zend_Auth_Adapter_Exception If answering the authentication query is impossible
     * @return Zend_Auth_Result
     */
    public function authenticate() {
	    $id = $this->_id;
	    $consumer = $this->_getConsumer ();
	    $return_to = $this->getReturnTo ();
	    $trust_root = $this->getRoot ();

	    if (empty ($_REQUEST['openid_mode'])) {
		    /* Start the authentication by redirecting to the
		     * provider. */
		    $auth_request = $consumer->begin($id);

		    /* No auth request means we can't begin OpenID. */
		    if (! $auth_request) {
			    return new Zend_Auth_Result(
				    Zend_Auth_Result::FAILURE,
				    $id,
				    array ('Authentication failed',
					   'Error creating the OpenID request.',
					   'Not a valid OpenID identifier'));
		    }

		    $sreg_request = Auth_OpenID_SRegRequest::build(
			    // Required
			    array('nickname'),
			    // Optional
			    array('fullname', 'email'));

		    $policy_uris = null;
		    if (isset($_GET['policies'])) {
			    $policy_uris = $_GET['policies'];
		    }

		    $pape_request = new Auth_OpenID_PAPE_Request($policy_uris);
		    if ($pape_request) {
			    $auth_request->addExtension($pape_request);
		    }

		    /* Redirect the user to the OpenID server for
		     * authentication.
		     *
		     * Store the token for this authentication so we can
		     * verify the response. */

		    /* For OpenID 1, send a redirect.  For OpenID 2, use a
		     * Javascript form to send a POST request to the
		     * server. */
		    if ($auth_request->shouldSendRedirect()) {
			    $redirect_url = $auth_request->redirectURL($trust_root,
								       $return_to);
			    /* If the redirect URL can't be built,
			     * display an error message. */
			    if (Auth_OpenID::isFailure($redirect_url)) {
				    return new Zend_Auth_Result(
					    Zend_Auth_Result::FAILURE,
					    $id,
					    array ('Authentication failed',
						   'Could not redirect to server: '
						   . $redirect_url->message));
			    } else {
				    /* Send redirect. */
				    header('Location: ' . $redirect_url);
				    exit ();
			    }
		    } else {
			    /* Generate redirect form markup and render it. */
			    $form_id = 'openid_message';
			    $form_html = $auth_request->htmlMarkup($trust_root,
								   $return_to,
								   false,
								   array('id' => $form_id));

			    if (Auth_OpenID::isFailure($form_html)) {
				    return new Zend_Auth_Result(
					    Zend_Auth_Result::FAILURE,
					    $id,
					    array('Authentication failed',
						  'Error redirecting to the provider.',
						  $form_html->message));
			    } else {
				    print ($form_html);
				    exit ();
			    }
		    }
	    } else {
		    /* Complete the authentication process using the
		     * server's response. */
		    $response = $consumer->complete($return_to);
		    $msg = array ();
		    /* Check the response status. */
		    if ($response->status == Auth_OpenID_CANCEL) {
			    /* This means the authentication was cancelled. */
			    $msg[] = 'Verification cancelled.';
		    } else if ($response->status == Auth_OpenID_FAILURE) {
			    /* Authentication failed; display the error message. */
			    $msg[] = "OpenID authentication failed: " . $response->message;
		    } else if ($response->status == Auth_OpenID_SUCCESS) {
			    /* This means the authentication
			     * succeeded; extract the identity URL and
			     * Simple Registration data (if it was
			     * returned). */
			    $identity = $response->getDisplayIdentifier();
			    $esc_identity = $this->_escapeHTML ($identity);

			    $result = new Hamsta_Zend_Auth_Result (
				    Zend_Auth_Result::SUCCESS,
				    $identity,
				    $msg);

			    if ($response->endpoint->canonicalID) {
				    $escaped_canonicalID = $this->_escapeHTML ($response->endpoint->canonicalID);
			    }

			    $sreg_resp = Auth_OpenID_SRegResponse::fromSuccessResponse($response);

			    $sreg = $sreg_resp->contents();
			    foreach ($sreg as $key=>$val) {
				    $result->addMessage ($this->_escapeHTML($val),
							 $key);
			    }
			    return $result;
		    }

	    }

	    return new Zend_Auth_Result(
		    Zend_Auth_Result::FAILURE,
		    $id,
		    $msg);

    }

}

?>
