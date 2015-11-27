/**
 * Article の サブメニュー操作用関数
 * 
 * 2010.04.11 レイアウト変更による修正
 */

var ArticleSubMenuExtend = new Object();

/*
 * @params (String) receive_mode_select 受信モードが書かれているHIDDEN_FIELD
 * @params (String) receive_mode_li     受信モードが書かれている左側のバー名
 */
ArticleSubMenuExtend.init = function (receive_mode_select,receive_mode_li) {
	this.select = $(receive_mode_select);
	this.receive_mode_li = $$("."+receive_mode_li);
//	this.submenu_init();
	this.set_onclick_li();
//	this.scroll_select();
//	this.set_li();
};

/* 
 * 内部関数
 * 
 * サブメニューの枠を初期化する
 */
ArticleSubMenuExtend.submenu_init = function(){
	this.receive_mode_li.each (function(e){
		e.id=null;
	});
}

/* 
 * 内部関数
 * 
 * サブメニューをクリックした時の動作を設定
 * 
 */
ArticleSubMenuExtend.set_onclick_li = function(){
	me = this;
	// メニューに定義する
	this.receive_mode_li.each (function(e){
		e.instance = me;
		if (e.innerHTML.indexOf("標準受信") > -1 ){
			e.name = "receive_mode_標準受信";
		}
		if (e.innerHTML.indexOf("拡大受信") > -1 ){
			e.name = "receive_mode_拡大受信";
		}
		if (e.innerHTML.indexOf("すべて") > -1 ){
			e.name = "receive_mode_すべて";
		}
		if (e.innerHTML.indexOf("送信済み") > -1 ){
			e.name = "receive_mode_送信済み";
		}
		e.onclick = function(){
			this.instance.submenu_init();
			this.id="current";
			if ( this.name.indexOf("receive_mode_") > -1 ){
				this.instance.scroll_select(this.name.replace("receive_mode_",""));
			}
		}
	});
}

/*
 * 現在の表示モードに従ってサブメニューの枠を変更する
 */
ArticleSubMenuExtend.set_li = function(){
	selected_menu = this.select.value;
	this.submenu_init();
	this.receive_mode_li.each (function(e){
		alert
		if ( e.name == ("receive_mode_"+selected_menu.value) ) {
			e.id="current";
		}
	});
}

/*
 * サブメニューにしたがって、表示モードのselectを変更する」。
 */
ArticleSubMenuExtend.scroll_select = function(value){
	this.select.value=value;
	this.submit();
};

