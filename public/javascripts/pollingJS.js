// アンケート関係
// 旧サイトのコードをそのままコピー

var Queries = new Array();
var Answers = new Array();

function addQuery(){
	qid = Queries.length;
	Queries[qid] = new Object();
	Queries[qid].correctAnswer = 0; // 正答の初期化
	Queries[qid].necessary = 'yes';
	Queries[qid].Options = new Array();
	Queries[qid].question = '問．'+ (1*qid+1);
	var count = Queries.length; // new length
	var queryS = '<table><tr><th class="dbtm_cell">質問' + count + '</th><td colspan="2" class="db_cell"><textarea rows=5 cols=50 onchange="setQuestion(this,' + qid + ');">' + Queries[qid].question + '</textarea><div class="ri"><input type="checkbox" onchange="setNecessary(this.checked,' + qid + ');" checked>「必ず記入」とする<br>配点：<input type="text" value="" size="3" onchange="setPoint(this,' + qid + ');"></div><div id="Q' + count + 'A0"> 回答方式は？<input type="radio" value="radio" onclick="setQtype(this' + ',' + qid + ');">単一選択<input type="radio" value="checkbox" onclick="setQtype(this' + ',' + qid + ');">複数選択<input type="radio" value="textarea" onclick="setQtype(this' + ',' + qid + ');">自由記入</div><div id="A1">&nbsp;</div></td></tr></table></div><div id="Query' + (1*count+1) + '">&nbsp;';
	var id = 'Query' + count;
	document.getElementById(id).innerHTML = queryS;
}

function deleteQuery(){
	var count = Queries.length;
	if (count > 0) {
		var id = 'Query' + count;
		document.getElementById(id).innerHTML = '&nbsp;';
		Queries.length --;
	} else alert('削減する項がありません．');
}

function setQuestion(elem, qid){
	Queries[qid].question = elem.value;
}

function setQtype(elem,qid){
	qtype = elem.value;
	Queries[qid].Qtype = qtype;
	var ansS = '';
	if (qtype=='textarea'){
		ansS += '<div class="ce"><textarea rows=5 cols=30>ここは自由記入の回答欄になります</textarea></div>';
	}
	else { // 最初の選択肢設定
	var pid = 0;
	Queries[qid].Options[0] = '選択肢１';
	ansS += (qtype=='radio') ? '&nbsp;&nbsp;&nbsp;&nbsp;（正答を設定する場合は，選択してください）<br>' : '';
	ansS += '&nbsp;&nbsp;&nbsp;&nbsp;<input type="' + qtype + '" id="QO' + (1*qid+1) + 'AO1" value="1" onclick="setCanswer(this,' + qid + ');"><input type="text" value="' + Queries[qid].Options[0] + '" size="50" onchange="setOption(this,' + qid + ',' + pid + ');"><br><div id="Q' + (1*qid+1) + 'A2">&nbsp</div>';
	ansS += '<div class="ce">&nbsp;選択肢：<a href="javascript:void(0);" onclick="addOption(' + qid + ')">追加</a>&nbsp;&nbsp;&nbsp;&nbsp;<a href="javascript:void(0);" onclick="deleteOption(' + qid + ')">削減</a></div>';// 選択肢の増減ボタン
   }

   document.getElementById('Q' + (1*qid+1) + 'A0').innerHTML = ansS;
}

function setPoint(elem, qid){
	Queries[qid].point = elem.value;
}

function setOption(elem,qid,pid){
	Queries[qid].Options[pid] = elem.value;
}

function deleteOption(qid){
	var plength = Queries[qid].Options.length;
	if (plength > 1) {
		var id = 'Q' + (1*qid+1) + 'A' + plength;
		document.getElementById(id).innerHTML = '&nbsp;';
		Queries[qid].Options.length --;
	} else alert('削減する項がありません．');
}

function setNecessary(checked, qid){
	Queries[qid].necessary = (checked) ? 'yes' : 'no';
}

function setCanswer(elem, qid){
	if (elem.type=='radio'){
		// Mozzillaのバグのため，dummy formのなかでのnameが働いてしまうため，疑似radioを作る
		var origin = Queries[qid].correctAnswer;
		var id = 'QO' + (1*qid+1) + 'AO' + origin;
		if (origin != 0) document.getElementById(id).checked = false;
		Queries[qid].correctAnswer = elem.value;
		elem.checked = true; //IEでは必要．
	}
}

function setQueryExp(query, j){ // query オブジェクトをアンケートの設問形式に変換する
	var exp = query.Qtype + '\/' + query.Options.length + '\/' + query.correctAnswer + '\/' + query.necessary + '\/' + query.point + '\/';
	exp += '\n' + query.question + '<br><br>';
	if (query.necessary == 'yes') exp += '<p><font color="red">※　必ず記入</font></p>'
	exp += '';
	if (query.Qtype == 'textarea') {
		exp += '<div class="ce"><textarea name="Q' + j + '"rows=5 cols=50></textarea></div>' ;
	}
	else {
		for (var i=0; i < query.Options.length; i++){
		exp += '&nbsp;&nbsp;&nbsp;&nbsp;<input type=\"' + query.Qtype + '\" name="Q' + j + '" value=\"' + (1*i+1) + '\">' + query.Options[i] + '<br>';
		}
	}
	return exp;
}

function setQueries(){
	var qid = Queries.length;
	if (qid > 0) {
		document.getElementById('NofQid').value = qid;
		var q = '';
		for (var i=0; i< qid;i++){
			var j = i+1;
			q += '{' + setQueryExp(Queries[i],j).replace(/}/g, escape('}')) + '}\n';
		}
		document.getElementById('questionsID').value = q;
	}
	return true;
}

function setAnswers(NofQ){
	for (var i=0; i<NofQ; i++) {
		Answers[i] = ' '; // Answersの初期化
	}
	var NofElements = document.answersForm.elements.length;
	for (var i=0; i<NofElements; i++){
		var elem = document.answersForm.elements[i];
		var q = elem.name.slice(0,1);
		if (q =='Q'){ // 問題の解答部分を拾う
			var qid = elem.name.slice(1) - 1;
			if (elem.type == 'textarea'){
				Answers[qid] += elem.value;
			}
			else {
				if (elem.checked) Answers[qid] += elem.value + ' ';
			}
		}
	}
}

function sendAnswers(NofQ){
	if (sent) return false;
	var ans = '';
	setAnswers(NofQ);
	var NotAnswered = new Array(); // 必記入にもかかわらず記入していない問
	for (var i=0; i<NofQ; i++){
		if ( QueriesNecessity[i] == 'yes' && Answers[i] == ' '){
			NotAnswered[NotAnswered.length] = 1*i + 1;
		}
		else ans += '{' + Answers[i].replace(/}}}/g, escape('}')) + '}\n';
		}
		if (NotAnswered.length > 0){
			var alertS = '次の問には回答がありませんが，必ず記入してください．\n';
			for (var i=0; i<NotAnswered.length; i++){
			alertS += '問 ' + NotAnswered[i] + '\n';
		}
		alert(alertS);
		sent = false;
		return false;
	}
	sent = true;
	document.getElementById('answersID').value = ans;
	document.new_res.submit();
	return true;
}