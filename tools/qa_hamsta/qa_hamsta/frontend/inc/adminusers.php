<?php

if (!defined('HAMSTA_FRONTEND')) {
  $go = 'about';
  return require("index.php");
 }

$html_title = "Users, roles and privileges administration";

if (User::isLogged ())
  {
    $user = User::getById (User::getIdent (), $config);
  }

if (! isset ($user) )
  {
    Notificator::setErrorMessage ('You have to be logged in and registered to have access to user administration.');
    header ('Location: index.php');
    exit ();
  }
else if ( ! $user->isAllowed ('user_administration') )
  {
    Notificator::setErrorMessage ('You do not have privilege for user administration.');
    header ('Location: index.php');
    exit ();
  }

?>