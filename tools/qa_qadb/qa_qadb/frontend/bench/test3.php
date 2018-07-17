<?php

#$glbl = 1;

#function test()
#{
#       global $glbl;
#       $array = array( 1, 2, 3, 4, 5 );
#       $xmid = 3;
#       $filtered = array_filter( $array, create_function('$a','return ($a<$xmid);') );
#       print_r( $filtered );
#       unset($glbl);
#}

#test();

#print "$glbl\n";

#$array = array( 1, 2, 3, 4, 5 );
#printf( "%d %d\n", $array[-2], $array[-1] );
#printf( "%d %d\n", $array[2], $array[1] );

$a='processes=16';
print preg_replace('/\=?\d+/','',$a)."\n";

#printf( "%.3f\n", M_PI );

?>
