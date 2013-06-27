<?php
/* ****************************************************************************
  Copyright (c) 2011 Unpublished Work of SUSE. All Rights Reserved.
  
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
 * This file contains some function to access the parameters passed to the
 * script via the $_REQUEST array. These functions should be used in favor of
 * directly accessing the $_REQUEST array or the other superglobals like $_POST
 * and $_GET.
 *
 * Their main advantage is that 
 * 1) they check if the parameter exists
 * 2) they make sure the parameter is of the expected data type
 */

    /**
     * request_str 
     * 
     * @param string $varname Name of the request parameter to get
     * @access public
     * @return string The requested parameter as string or an empty
     *      string if the parameter is not present.
     */
    function request_str($varname) {
        if (!empty($_REQUEST[$varname])) {
            return (string) $_REQUEST[$varname];
        } else {
            return "";
        }
    }

    /**
     * request_int
     * 
     * @param string $varname Name of the request parameter to get
     * @access public
     * @return int The requested parameter as integer or 0 if the 
     *      parameter is not present.
     */
    function request_int($varname) {
        if (!empty($_REQUEST[$varname])) {
            return (int) $_REQUEST[$varname];
        } else {
            return 0;
        }
    }

    /**
     * request_array
     * 
     * @param string $varname Name of the request parameter to get
     * @access public
     * @return array The requested parameter as array or an empty array
     *      if the parameter is not present. Note that if there is a single
     *      parameter identified by $varname, an array containing this
     *      parameter as the only element will be returned. (This is how a
     *      PHP typecast to array works)
     * @todo Check for the expected structure provided by an extra parameter
     */
    function request_array($varname) {
        if (!empty($_REQUEST[$varname])) {
            return (array) $_REQUEST[$varname];
        } else {
            return array();
        }
    }

    /**
     * request_is_array 
     * 
     * @param string $varname Name of the request parameter to check
     * @access public
     * @return boolean true if the request parameter is set and is an array,
     *      false otherwise
     */
    function request_is_array($varname) {
        return empty($_REQUEST[$varname])
            ? false
            : is_array($_REQUEST[$varname]);
    }
    
    /**
     * request_operator
     *
     * Returns a filter operator ('=' or 'LIKE') specified
     * by a request parameter. Valid operator names are 'equals' and 'like'.
     *  
     * @param string $varname Name of the request parameter to get
     * @access public
     * @return int A constant whose name matches the parameter,
     * or null if no matching constant is found.
     */
    function request_operator($varname) {
        if (!empty($_REQUEST[$varname])) {
            switch($_REQUEST[$varname]) {
                case "equals": return '=';
                case "like":   return 'LIKE';
                default:       return null;
            }
        } else {
            return null;
        }
    }
?>
