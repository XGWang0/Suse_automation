<?php

require_once ('Zend/Session.php');

/**
 * Class is a wrapper for setting messages displayed on the screen.
 *
 * <b>WARNING: This class uses a function from TBLib in a GLOBAL
 * namespace. You have to include it <b>after</b> TBLib
 * inclusion. This needs to be fixed some day.</b>
 *
 * @package Util
 * @author Pavel Kacer <pkacer@suse.com>
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
class Notificator
{

  /** @var string Namespace to save message data to. */
  const MESSAGE_SESSION_NAMESPACE = 'notification';

  /** @var string Constant of the success message type. */
  const MESSAGE_TYPE_SUCCESS = 'success';

  /** @var string Constant of the warning message type. NOT IMPLEMENTED. */
  const MESSAGE_TYPE_WARNING = 'warning';

  /** @var string Constant of the error message type. */
  const MESSAGE_TYPE_ERROR = 'error';

  /**
   * This class uses Zend_Session as a place to store
   * messages. Therefore there is no need to create instances. All
   * methods should be static.
   */
  private function __construct ()
  {
    /* No instance creation allowed. */
  }

  private static function getNamepace ($ns)
  {
    return new Zend_Session_Namespace ($ns);
  }

  /**
   * Set message to $message and type to $type.
   *
   * @param string $message Message to set.
   * @param string $type Type of message to set.
   */
  public static function setMessage ($message, $type)
  {
    $ns = self::getNamepace (self::MESSAGE_SESSION_NAMESPACE);
    $ns->message = $message;
    $ns->messType = $type;
  }

  /**
   * Set failure message to $message.
   *
   * @param string $message Message to set.
   */
  public static function setErrorMessage ($message)
  {
    self::setMessage ($message, self::MESSAGE_TYPE_ERROR);
  }

  /**
   * Set successful message to $message.
   * 
   * @param string $message Message to set.
   */
  public static function setSuccessMessage ($message)
  {
    self::setMessage ($message, self::MESSAGE_TYPE_SUCCESS);
  }

  /**
   * Checks if message and type are set.
   *
   * @return boolean True if message and type are both set, false otherwise.
   */
  public static function hasMessage ()
  {
    $ns = self::getNamepace (self::MESSAGE_SESSION_NAMESPACE);
    return ( isset ($ns->message) && isset ($ns->messType) );
  }

  /**
   * Returns message or null if not set.
   * 
   * @return string If some message is set it is returned. Otherwise
   * null is returned.
   */
  public static function getMessage ()
  {
    $ns = self::getNamepace (self::MESSAGE_SESSION_NAMESPACE);
    return $ns->message;
  }

  /**
   * Returns type of the message.
   *
   * You can check against some of the constants provided by this class.
   */
  public static function getMessageType ()
  {
    $ns = self::getNamepace (self::MESSAGE_SESSION_NAMESPACE);
    return $ns->messType;
  }

  /**
   * Prints message stored in the session.
   */
  public static function printMessage ()
  {
    $msg = self::getMessage ();
    $type = self::getMessageType ();
    /* A unique identifier for the message (so that there can
     * potentially be more than one on a page). */
    $id = mt_rand(100000, 999999);
    /** This was stolen directly from the TBLib. It is total mess and
     * should be cleaned up and made more generic (maybe create some
     * container for a notifications). */
    /* The main dialog box */
    echo ('<div class="message ' . $type . '" id="message-' . $id . '">' . "\n");
    /* The close button */
    echo ('  <img src="/tblib/icons/close.png" class="close"'
          . ' id="message-close-' . $id
          . '" alt="Close this Message" title="Close this Message" />' . "\n");
    /* The message itself */
    echo ('  <div class="text-main">' . htmlspecialchars($msg) . '</div>'
          . "\n</div>\n");
    /* Jquery effect */
    echo ('<script type="text/javascript">
  $("#message-close-' . $id . '").click(
  function()
  {
    $("#message-' . $id . '").fadeTo("slow", 0,
    function()
    {
      $(this).slideUp("slow")
    });
  });
</script>' . "\n");
  }

  /**
   * Unset all variables in the message session namespace.
   */
  public static function delete ()
  {
    $ns = self::getNamepace (self::MESSAGE_SESSION_NAMESPACE);
    $ns->unsetAll ();
  }

  /**
   * Prints message and unsets the message session namespace.
   */
  public static function printAndUnset ()
  {
    self::printMessage ();
    self::delete ();
  }

}

?>