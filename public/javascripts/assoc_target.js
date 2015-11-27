/* assoc target handling */

function recount_assoc_target_counters(base_div_id, single){
	var counter_class = "." + base_div_id + "_counter";
	var counter_sibling = counter_class + "_sibling";
	var adding_div_id   = base_div_id + "_adding"
    var count = 0;
    $$(counter_class).each(function(counter){
      count ++; 
      counter.value = count;
	  counter.adjacent(counter_sibling).each(function(sibling){
	  	sibling.value = count;
      });
	})
	if ($(adding_div_id)) {
		if (single == 'yes' && count >= 1) {
			$(adding_div_id).hide(); 
		}
		else {
			$(adding_div_id).show();
		}
	}
	return count
};
