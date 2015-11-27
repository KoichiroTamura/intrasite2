var OrgDependency = new Object();
	
OrgDependency.init = function(form_div,action_url){
	this.tmp = document.createElement('form');
	this.tmp2 = document.createElement('input');
	this.tmp2.type = "hidden";
	this.tmp2.name = "fullname";
	this.tmp.appendChild(this.tmp2);
	this.tmp3 = document.createElement('input');
	this.tmp3.type = "hidden";
	this.tmp3.name = "limited";
	this.tmp3.value = "1";
	this.tmp.appendChild(this.tmp3);
	this.tmp.method = "post";
	this.tmp.action = action_url;
	this.tmp.id = "call_for_dependencies";
	$(form_div).appendChild(this.tmp);
};

OrgDependency.onclick_push = function(form_name,field_name){
	var select_obj_name = "status";
	var fields = $(form_name)[field_name];
	if (field_name==select_obj_name) {select_obj_name="affiliation";}
	for (i = 0; i < fields.length; i++) {
		fields[i].field_instance = this.tmp2;
		fields[i].onclick = function(){
			this.field_instance.value = this.value;
			$('call_for_dependencies').request({
				onComplete: function(e){
					OrgDependency.position_select(e.responseText.evalJSON(),form_name,select_obj_name);
					tree_reset(select_obj_name);
				}
			});
		};
		fields[i].onchange = fields[i].onclick;
	}
};

OrgDependency.onclick_recall = function(form_name, field_name){
	var select_obj_name = "status";
	var fields = $(form_name)[field_name];
	if (field_name==select_obj_name) {select_obj_name="affiliation";}
	for (i = 0; i < fields.length; i++) {
		if(fields[i].checked){
			this.tmp2.value = fields[i].value;
			$('call_for_dependencies').request({
				onComplete: function(e){
					OrgDependency.position_select(e.responseText.evalJSON(),form_name,select_obj_name);	}
			});
		}
	}
};

OrgDependency.tree_reset = function(field_name){
	uls = $('div_'+field_name).getElementsByTagName('ul');
	for (i=0;i<uls.length;i++){
		if ( uls[i].id != "" ) { uls[i].style.display='none'; }
	}
};

OrgDependency.position_select = function(ary,form_name,field_name){
	var fields = $(form_name)[field_name];
	arry = ary["simple"]
	run = ary["hash"]
	for (i = 0; i < fields.length; i++) {
		s = fields[i].id.replace(field_name+"_","");
		if (arry.indexOf(s) > -1) {
//			fields[i].disabled=false;
//			try {
//				$('parent_'+ run[s]).style.display="block";
//			} catch(e) {
//			}
			$('li_'+s).show();
		}else {
//			fields[i].disabled=true;
			$('li_'+s).hide();
		}
	}	
};
