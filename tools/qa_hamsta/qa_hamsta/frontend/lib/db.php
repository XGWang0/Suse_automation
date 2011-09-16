<?php

/**
 * get_pdo 
 *
 * Returns the PDO for the database connection. If no connection is 
 * established yet, get_pdo will start a new one.
 * 
 * @access public
 * @return PDO
 */
function get_pdo() {
    static $pdo = null;

    if ($pdo == null) {
        try {
            $pdo = new PDO(PDO_DATABASE, PDO_USER, PDO_PASSWORD);
            $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch (PDOException $e) {
            die("Could not connect to database.");
        }
    }

    return $pdo;
}

?>
