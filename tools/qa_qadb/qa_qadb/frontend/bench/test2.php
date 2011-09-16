<?php
# PHPlot Example: Point chart with error bars
require_once($_SERVER['DOCUMENT_ROOT'].'/hrf/phplot/phplot.php');

$data = array();
$a = 0.5;
$d_theta = M_PI/48.0;
for ($theta = M_PI * 7; $theta >= 0; $theta -= $d_theta)
  $data[] = array('', $a * $theta * cos($theta), $a * $theta * sin($theta), -$a*$theta*sin($theta));

$plot = new PHPlot(800, 600);
$plot->SetImageBorderType('plain');

$plot->SetPlotType('points');
$plot->SetDataType('data-data');
$plot->SetDataValues($data);

# Main plot title:
$plot->SetTitle('Scatterplot (points plot)');

# Need to set area and ticks to get reasonable choices.
$plot->SetPlotAreaWorld(-12, -12, 12, 12);
$plot->SetXTickIncrement(2);
$plot->SetYTickIncrement(2);

# Move axes and ticks to 0,0, but turn off tick labels:
$plot->SetXAxisPosition(0); # Is default
$plot->SetYAxisPosition(0);
$plot->SetXTickPos('xaxis');
$plot->SetXTickLabelPos('none');
$plot->SetYTickPos('yaxis');
$plot->SetYTickLabelPos('none');

# Turn on 4 sided borders, now that axes are inside:
$plot->SetPlotBorderType('full');

# Draw both grids:
$plot->SetDrawXGrid(True);
$plot->SetDrawYGrid(True);  # Is default

$plot->DrawGraph();

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
