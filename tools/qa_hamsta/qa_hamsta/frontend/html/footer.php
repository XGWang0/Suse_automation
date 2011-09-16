	</div>
	<div id="footer" class="text-main">
		<span class="text-white text-small" id="copyright">
			&copy; Novell, Inc. - For assistance, please email qa-automation@suse.de
		</span>

		<span class="text-main navibar">
<?php
	foreach ($naviarr as $key=>$value){
		echo createLink($value, $key);
	}
?>
		</span>
	</div>
</body>
</html>
