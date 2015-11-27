
if(document.getElementById){
	document.writeln('<style type="text/css" media="all">');
	document.writeln('<!--');
	document.writeln('.sidehide{display:none}');
	document.writeln('-->');
	document.writeln('</style>');
       }
	   
function showHide(id){
	var disp = document.getElementById(id).style.display;
	if(disp == "block"){
		document.getElementById(id).style.display = "none";
	}
       else{
		document.getElementById(id).style.display = "block";
	}
	return false;
}

function hideShow(id){
	var disp = document.getElementById(id).style.display;
	if(disp == "none"){
		document.getElementById(id).style.display = "block";
	}
       else{
		document.getElementById(id).style.display = "none";
	}
	return false;
}


