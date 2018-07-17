<?php
# PHPlot Example: Point chart with error bars
require_once($_SERVER['DOCUMENT_ROOT'].'/hrf/phplot/phplot.php');

$data = array(
  array('', 1,  23.5, 5, 5), array('', 2,  20.1, 3, 3),
  array('', 3,  19.1, 2, 2), array('', 4,  16.8, 3, 3),
  array('', 5,  18.4, 4, 6), array('', 6,  20.5, 3, 2),
  array('', 7,  23.2, 4, 4), array('', 8,  23.1, 5, 2),
  array('', 9,  24.5, 2, 2), array('', 10, 28.1, 2, 2, 32, 0, 0),
);


$data2 = array(        # Data array for bottom plot: Exports
  array('1981', 595),  array('1982', 815),  array('1983', 739),
  array('1984', 722),  array('1985', 781),  array('1986', 785),
  array('1987', 764),  array('1988', 815),  array('1989', 859),
  array('1990', 857),  array('1991', 1001), array('1992', 950),
  array('1993', 1003), array('1994', 942),  array('1995', 949),
  array('1996', 981),  array('1997', 1003), array('1998', 945),
  array('1999', 940),  array('2000', 1040),
);

$plot = new PHPlot(800,600);
$plot->SetImageBorderType('plain');

# Disable auto-output:
$plot->SetPrintImage(0);

# There is only one title: it is outside both plot areas.
$plot->SetTitle('US Petroleum Import/Export');

# Set up area for first plot:
$plot->SetPlotAreaPixels(80, 40, 740, 270);

# Do the first plot:
#$plot->SetXTickLabelPos('none');
#$plot->SetXTickPos('none');
$plot->SetYTitle("Error graph");


$plot->SetPlotType('points');
$plot->SetDataType('data-data-error');
$plot->SetDataValues($data);
#$plot->SetPlotAreaWorld(NULL, 0, NULL, 13000);
$plot->SetPlotAreaWorld(0, 0, 11, 40);

$plot->SetXTickIncrement(1);
$plot->SetYTickIncrement(5);
$plot->SetDrawXGrid(True);
$plot->SetDrawYGrid(True);  # Is default
$plot->SetErrorBarShape('tee');  # Is default
$plot->SetErrorBarSize(10);
$plot->SetErrorBarLineWidth(2);
$plot->SetDataColors('blue');
$plot->SetErrorBarColors('brown');
$plot->SetPointSizes(10);

error_reporting(85);

$plot->DrawGraph();

# Set up area for second plot:
$plot->SetPlotAreaPixels(80, 320, 740, 550);
#$plot->SetPlotAreaPixels(80, 40, 740, 270);


# Do the second plot:
$plot->SetDataType('text-data');
$plot->SetDataValues($data2);
$plot->SetPlotAreaWorld(NULL, 0, NULL, 1300);
$plot->SetDataColors(array('green'));
$plot->SetXTickLabelPos('none');
$plot->SetXTickPos('none');
$plot->SetYTickIncrement(200);
$plot->SetYTitle("EXPORTS\n1000 barrels/day");

$plot->SetPlotType('bars');
$plot->DrawGraph();

# Output the image now:
$plot->PrintImage();


/*

$plot->SetPlotType('points');
$plot->SetDataType('data-data-error');
$plot->SetDataValues($data);
$plot->SetPlotAreaWorld(0, 0, 11, 40);
$plot->SetXTickIncrement(1);
$plot->SetYTickIncrement(5);

# Draw both grids:
$plot->SetDrawXGrid(True);
$plot->SetDrawYGrid(True);  # Is default

# Set some options for error bars:
$plot->SetErrorBarShape('tee');  # Is default
$plot->SetErrorBarSize(10);
$plot->SetErrorBarLineWidth(2);

# Use a darker color for the plot:
$plot->SetDataColors('brown');
$plot->SetErrorBarColors('brown');

# Make the points bigger so we can see them:
$plot->SetPointSizes(10);

error_reporting(85);
*/
?>
