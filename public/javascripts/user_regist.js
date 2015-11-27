submit_check=0;
function NameUse(url){
	form = document.createElement('form');
	form.id = "user_name_scanner_form";
	form.name = form.id;
	form.action = url;
	form.method = "get"
	input = document.createElement('input');
	input.type = "hidden";
	input.name = "name";
	form.appendChild(input);
	$('user_name_scanner').appendChild(form);
	
	user_info_name = $('user_regist_form_div').getElementsByTagName('td')[1].getElementsByTagName('input')[0]
	
	user_info_name.onchange = function(){
		$('user_name_scanner_form')["name"].value = user_info_name.value;
		if ( $('user_name_scanner_form')["name"].value.length <= 0 ){
			return false;
		}
		if ($('user_name_scanner_form')["name"].value.indexOf('@') <= 0) {
			$('user_name_scanner_result').innerHTML = "そのログイン名は適切ではありません。";
			return false;
		}
		$('user_name_scanner_form').request({
			onSuccess: function(r){
				if (eval(r.responseText) > 0) {
					$('user_name_scanner_result').innerHTML = "そのログイン名はすでに使用済です";
					submit_check=0;
				}
				else {
						$('user_name_scanner_result').innerHTML = "使用可能です";
						submit_check=1;
				}
			}
		});
	};
	
	user_info_name.observe("change", user_info_name.onchange);
}
