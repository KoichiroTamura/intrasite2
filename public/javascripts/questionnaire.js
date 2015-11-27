// アンケート関係

choice_option_selector = 'div.choice-option'

function addOption(id, prefix, question_type){
	var option_id = $(id).adjacent(choice_option_selector).length + 1
    var option_name = (question_type == "radio" ? prefix + "correct_ans" : "checkbox" + option_id)
	
    content  = "<div class='choice-option' >"  // choice option block
    content += "&nbsp;&nbsp;&nbsp;&nbsp;"
    content += "<input type='" + question_type + "' name='" + option_name + "' value='" + option_id + "' >"
    content += "<input type=text name='" + prefix + "option_text[]' value='ここに選択肢を記入' size='50'>" 
    content += "</div>"
    
    $(id).insert({before: content})
}

function deleteOption(id){
	var choice_option = $(id).previous(choice_option_selector)
	if (choice_option) {
		choice_option.remove();
	}
}
