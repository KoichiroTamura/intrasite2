/** 
* ファイルアップロード用操作クラス
* @constructs 
*
* @param form_action {String} url_forで生成した文字列を入力 (action=>create)
* @param interval_url {String} url_forで生成した文字列を入力 (action=>progress)
* @param load_url {String} url_forで生成した文字列を入力 (action=>show)
* @param working_div {HTMLDivElement} 作業台を指定 実際の作業領域は指定した要素の子要素で作成
* @param dummy_field_div {HTMLDivElement} ファイル指定フィールド(偽)のあるDIV要素
* @param auth_key {String} フォーム送信用の認証キー (CSRF)
*
* @example
* <form id="article_form" method="post" action=""><div id="attached_files"></div></form>
* .....
* <div id="attached_working"></div>
* 
* <script>File1=new Uploader($('attached_working'),
*							 $('article_form'),
*							 '<%= form_authenticity_token %>');
*/
Uploader = function(id_name, interval_url, show_url, working_div, dummy_field_div){
	/** このオブジェクトのID */
	this.id = id_name;
	this.checksum = null;
	this.parcent = 0;
	this.filename = null;
	this.load_url=show_url;
	this.intervalID = null; 
	this.intervalURL = interval_url;
	this.interval_count = 0;
	this.working_div=working_div;
	
	$("File-Dummy-"+this.id).obj = this;
	$("File-Dummy-"+this.id).onchange = function(){
		this.obj.pre_submit();
	};
	$("File-Dummy-"+this.id).onclick = function(){
		this.click;
	};
	this.dummy_field_div=$('attacheed-display-'+this.id);
};
/** 
* ファイル送信フォームにデータを転記して送信メソッドをコール
*/
Uploader.prototype.pre_submit = function (){
	try{ $('File-'+this.id).remove(); } catch(e) {  }
	var field = $('File-Dummy-'+this.id);
	field.type="file";
	field.id='File-'+this.id;
	field.name="file";
	this.working_div.appendChild(field);
	this.dummy_field_div.innerHTML+="<br>";
	this.form_submit();
};

/** 
* ファイルを送信すると同時に、進捗状況取得メソッドも発動
*/
Uploader.prototype.form_submit = function(){
	var form_field = $('File-'+this.id);
	window.setTimeout("$('Form-"+this.id+"').submit();",1);
	this.dummy_field_div.innerHTML = "Uploading."
	this.intervalID=window.setInterval("$('"+form_field.id+"').obj.progress()",200);
};

/** 
* 進捗状況の取得とアップロードファイルの取得
*
* 進捗状況はファイル選択フィールド(偽)に表示される。
* 完了するとダウンロード用のリンクが作成される。
* 
* 同時に<input type="hidden" name="afc_codes[]" value="[checksum]">を生成する
*/
Uploader.prototype.progress = function(){
	var form = $('Form-'+this.id);
	var intervalID = this.intervalID;
	var intervalURL = this.intervalURL;
	var obj=this;
		new Ajax.Request(intervalURL, {
			parameters: form.serialize(),
			asynchronous: false,
			onSuccess: function(a){
				if (a.responseText != "") {
					obj.dummy_field_div.innerHTML = a.responseText + ":" + form.serialize();
					res = a.responseText.evalJSON();
					if (res["err"] != "true") {
						obj.parcent = eval(res["fullsize"]) / eval(res["size"]) * 100;
						obj.checksum = res["checksum"];
						obj.filename = res["original_name"];
						obj.dummy_field_div.innerHTML = "Uploading...."+obj.checksum+"%";
						if (eval(res["fullsize"]) == eval(res["size"])) {
							obj.dummy_field_div.innerHTML="";
							window.clearInterval(intervalID);
							a = document.createElement('input');
							a.name = "afc_codes[]";
							a.value = obj.checksum;
							a.type = "hidden";
							obj.dummy_field_div.appendChild(a);
							a = document.createElement('a');
							a.href=obj.load_url + "/" + obj.checksum;
							a.innerHTML=obj.filename;
							obj.dummy_field_div.appendChild(a);
							a = document.createElement('span');
							a.innerHTML="　";
							obj.dummy_field_div.appendChild(a);
						}
					}
					else
					{
						obj.dummy_field_div.innerHTML = "Uploading.....";
					}
				}
			},
			onFalse: function(a)
			{
				obj.dummy_field_div.innerHTML = "通信エラーが発生しました。再度アップロードしてください。";
				window.clearInterval(intervalID);
			}
		});		
	};
