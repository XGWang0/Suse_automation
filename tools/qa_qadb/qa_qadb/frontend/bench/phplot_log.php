<?php

/*
 * PHPlot fix / extension by Vilem Marsik (vmarsik at suse dot cz)
 */

require_once($_SERVER['DOCUMENT_ROOT'].'/phplot/phplot_data.php');

class PHPlot_log extends PHPlot_Data
{
	function PHPlot_Data($which_width=600, $which_height=400, $which_output_file=NULL, $which_input_file=NULL)
	{
		return $this->PHPlot($which_width,$which_height,$which_output_file,$which_input_file);
	}

	function SetXTicks( $coordinates )
	{
		if( $coordinates )
			$this->x_ticks = $coordinates;
		else
			unset( $this->x_ticks );
	}

	function SetYTicks( $coordinates )
	{
		if( $coordinates )
			$this->y_ticks = $coordinates;
		else
			unset( $this->y_ticks );
	}
	
	function DrawXTicks()
	{
		if( !isset( $this->x_ticks ) )
			return parent::DrawXTicks();

		// Sets the line style for IMG_COLOR_STYLED lines (grid)
		if ($this->dashed_grid) {
			$this->SetDashedStyle($this->ndx_light_grid_color);
			$style = IMG_COLOR_STYLED;
		} else {
			$style = $this->ndx_light_grid_color;
		}

		list($x_start, $x_end, $delta_x) = $this->CalcTicks('x');

		// TODO: test the range
		foreach( $this->x_ticks as $x_tmp )
		{
			if( $x_tmp<$x_start || $x_tmp>$x_end )
				continue;

			$xlab = $this->FormatLabel('x', $x_tmp);
			$x_pixels = $this->xtr($x_tmp);
			// Vertical grid lines
			if ($this->draw_x_grid) {
				ImageLine($this->img, $x_pixels, $this->plot_area[1], $x_pixels, $this->plot_area[3], $style);
			}

			// Draw tick mark(s)
			$this->DrawXTick($xlab, $x_pixels);

		}


	}

	function DrawYTicks()
	{
		if( !isset( $this->y_ticks ) )
			return parent::DrawYTicks();

		// Sets the line style for IMG_COLOR_STYLED lines (grid)
		if ($this->dashed_grid) {
			$this->SetDashedStyle($this->ndx_light_grid_color);
			$style = IMG_COLOR_STYLED;
		} else {
			$style = $this->ndx_light_grid_color;
		}

		list($y_start, $y_end, $delta_y) = $this->CalcTicks('y');

		foreach( $this->y_ticks as $y_tmp )
		{
			if( $y_tmp<$y_start || $y_tmp>$y_end )
				continue;

			$ylab = $this->FormatLabel('y', $y_tmp);
			$y_pixels = $this->ytr($y_tmp);

			// Horizontal grid line
			if ($this->draw_y_grid) {
				ImageLine($this->img, $this->plot_area[0]+1, $y_pixels, $this->plot_area[2]-1, $y_pixels, $style);
			}

			// Draw tick mark(s)
			$this->DrawYTick($ylab, $y_pixels);
		}
		return TRUE;
	} // function DrawYTicks

}
?>
