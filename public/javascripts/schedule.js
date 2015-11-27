/* 予定表・カレンダーに関係する処理をまとめたファイル
 *
 * 変更履歴
 *	r1102 | 木下  | 2009-09-25	新規作成
 *	r1293 | 並松  | 2009-11-08	全面改訂
 *	r1293 | 並松  | 2009-11-20	デザイン改訂によるバグフィック
 *	r1363 | 並松  | 2009-11-23	処理の見直しによるソースの品質向上
 *	r1367 | 並松  | 2009-11-24	{week/month}_calendar.html.erbのコードを整理
 *	r1684 | 並松  | 2010-01-15	コードの整理
 */
////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * 検索バナーの操作スクリプト集
 * 
 * @constructor
 * @param {String} y 日付(年)のID
 * @param {String} m 日付(月)のID
 * @param {String} d 日付(日)のID
 * @param {String} p 前(月|週)ボタンのID
 * @param {String} n 次へボタンのID
 *
 * 初期処理では、与えられたIDから日付値を取得する。
 *
 */
var SchedulerSearchForm = function(y,m,d,p,n)
{
	this.year_field_name = y;
	this.month_field_name = m;
	this.day_field_name = d;
	this.prev_button_name = p;
	this.next_button_name = n; 

	this.start_year = $(this.year_field_name)[$(this.year_field_name).selectedIndex].value;
	this.start_month=$(this.month_field_name)[$(this.month_field_name).selectedIndex].value;
	this.start_day=$(this.day_field_name)[$(this.day_field_name).selectedIndex].value;
	this.now = new Date(this.start_year,this.start_month-1,this.start_day);
	this.prev_buttton_decoration();
	this.next_buttton_decoration();
}

/* 
* 先週を表示するようにフォーム値を変更する。実質、prev_button_action("w")のAlias 
*/
SchedulerSearchForm.prototype.prev_week = function(){
	this.prev_button_action("w");
};

/* 
* 次週を表示するようにフォーム値を変更する。実質、next_button_action("w")のAlias 
*/
SchedulerSearchForm.prototype.next_week = function()
{
	this.next_button_action("w");
};

/* 
* 先月を表示するようにフォーム値を変更する。実質、prev_button_action("m");のAlias 
*/
SchedulerSearchForm.prototype.prev_month = function(){
	this.prev_button_action("m");
};

/* 
* 次月を表示するようにフォーム値を変更する。実質、prev_button_action("m");のAlias 
*/
SchedulerSearchForm.prototype.next_month = function(){
	this.next_button_action("m");
};

/* 
* 前(月|週)ボタンの装飾をする。buttton_decorationのAlias
*/
SchedulerSearchForm.prototype.prev_buttton_decoration = function(){	
	this.buttton_decoration($(this.prev_button_name));
};

/* 
* 次前(月|週)ボタンの装飾をする。buttton_decorationのAlias
*/
SchedulerSearchForm.prototype.next_buttton_decoration=function(){	
	this.buttton_decoration($(this.next_button_name));
};

/* 
* ボタンの装飾をする。
*
* @param {HTMLElement} obj 装飾対象
*/
SchedulerSearchForm.prototype.buttton_decoration = function (obj) { 
	obj.style.color="blue";
	obj.style.textDecoration="underline";
	obj.style.cursor="pointer";
}

/* 
* 次(月|週|日)ボタンの動作を定義
* @param {String} calendar_type : "day", "week" or "month"
*
* パラメータがwの場合、初期値で与えられた値から7日、mなら1ヶ月前を計算
* 検索窓にその値を投入する。
*
* このプログラムは変更のみ。自分でAjaxは呼ばないので注意
*/
SchedulerSearchForm.prototype.prev_button_action=function(calendar_type){
	if (calendar_type == "day"){
		this.now.setDate(this.now.getDate() - 1);
	} else if (calendar_type == "week") {
		this.now.setDate(this.now.getDate() - 7);
	} else {
		this.now.setMonth(this.now.getMonth() - 1);
	}
	
	if ( this.now.getFullYear() - $(this.year_field_name)[0].value*1 < 0 )
	{
		elem = document.createElement('option');
		$(this.year_field_name).appendChild(elem);
		for ( c = $(this.year_field_name).length-1; c > 0 ; c-- )
		{
			$(this.year_field_name)[c].text = $(this.year_field_name)[c-1].text;
			$(this.year_field_name)[c].value = $(this.year_field_name)[c-1].value;
			$(this.year_field_name)[c].innerHTML = $(this.year_field_name)[c-1].text;
		}
		$(this.year_field_name)[0].text=this.now.getFullYear();
		$(this.year_field_name)[0].value=this.now.getFullYear();
		$(this.year_field_name)[0].innerHTML=this.now.getFullYear();
	}
	$(this.year_field_name).selectedIndex=this.now.getFullYear() - $(this.year_field_name)[0].value*1;
	$(this.month_field_name).selectedIndex=this.now.getMonth();
	$(this.day_field_name).selectedIndex=this.now.getDate() - 1;
};


/* 
* 次(月|週|日)ボタンの動作を定義
* @param {String} calendar_type : "day", "week" or "month"
*
* 検索窓にその値を投入する。
*
* このプログラムは変更のみ。自分でAjaxは呼ばないので注意
*/
SchedulerSearchForm.prototype.next_button_action=function(calendar_type){
	if (calendar_type == "day") {
		this.now.setDate(this.now.getDate()+1);
	} else if (calendar_type == "week") {
		this.now.setDate(this.now.getDate()+7);
	} else{
		this.now.setMonth(this.now.getMonth() + 1);
	}
	
		if ( this.now.getFullYear() - $(this.year_field_name)[0].value*1 > $(this.year_field_name).length-1 )
		{
			elem = document.createElement('option');
			elem.text=this.now.getFullYear();
			elem.value=this.now.getFullYear();
			elem.innerHTML=this.now.getFullYear();
			$(this.year_field_name).appendChild(elem);
		}
		$(this.year_field_name).selectedIndex=this.now.getFullYear() - $(this.year_field_name)[0].value*1;
		$(this.month_field_name).selectedIndex=this.now.getMonth();
		$(this.day_field_name).selectedIndex=this.now.getDate() - 1;
};

/* バナー用のクラスを定義。
 * 
 * バナーの開始日と終了日、タイトル、リンク先の記事を格納するもの
 * @constructor
 */
var Banner = function (){
	this.start_date=new Date();
	this.end_date=new Date();
	this.name=new String();
	this.run_id=new String();
};

Banner.prototype.start_date_s = function()
{
	year = this.start_date.getFullYear();
	month = this.start_date.getMonth() * 1 + 1;
	date = this.start_date.getDate();
	return year + "-" + month + "-" + date
};

Banner.prototype.end_date_s = function()
{
	year = this.end_date.getFullYear();
	month = this.end_date.getMonth() * 1 + 1;
	date = this.end_date.getDate();
	return year + "-" + month + "-" + date
};

/* スケジュールコーナで利用する機能を集合させたもの。
 * 
 * ここはおもに表示テーブルの部分を中心にしている。
 *
 * @constructor
 * @param {HTMLTableElement} obj スケジューラーのテーブル名(ID)
 * @parma {Calender} cal_obj スケジューラがどこからどこまで表示されているかを示したもの
 * @param {String} cellClassObjs スケジューラの日毎に区切ったセルのクラス名(CLASS)
 * @param {String} baseName スケジューラを表示する親のコンテナID
 * @param {String} CellClassNameInCell スケジューラの日毎に区切ったセル内コンテナのクラス名
 *
 * スケジューラのセルには、必ず1つのコンテナが存在することを想定しています。
 * また、このコンストラクタてを呼び出すとwindow.onresizeのオーバライドがされます。
 * オーバライドの内容は、スケジューラの親コンテナの大きさが変わったかを検査し、
 * 変わった場合は、スケジューラの大きさをリサイズする処置をしています。
 */
var Scheduler = function(obj,cal_obj,cellClassObjs,baseName,CellClassNameInCell){
	this.table=obj;
	this.week_banner_count=new Hash();
	this.cal=cal_obj;
	this.cell_class=cellClassObjs;
	this.base=baseName;
	this.cell_in_cell_name = CellClassNameInCell;
	this.banners=new Hash();
	window.instance = this;
	window.onresize = function () {
	     this.instance.hide();
	     if (this.instance.resize_check()){
		 	this.instance.view();
		} else { 
			this.instance.show();
		}
	};
};

/**
 * 
 */

Scheduler.prototype.create_new_banner = function(name,value){
	if ( Object.isUndefined(name) ){ name="Banner" + Math.random(); }
	if ( Object.isUndefined(value) ){ value=new Banner(); }
	this.banners.set(name,value);
	return this.banners.get(name);
};

Scheduler.prototype.create_new_banner_with_day = function(start)
{
	b = this.create_new_banner();
	b.start_date = new Date(start);
	b.end_date = new Date(start);
	b.end_date.setDate(b.end_date.getDate()+1);
	b.end_date.setMinutes(-1);
	this.banner_create_sub(b,this);
}

/* スケジューラの表示に関する部分。
 *
 * 残留しているゴミコンテナの収集、セルの大きさ調整、バナーの作成、他のバナーとの重なり調整、表示を行います。
 *
 * スケジューラのテーブルは一度非表示にしています。これは、表示したまま処理をすると、ブラウザの描画負荷が大きくなり、動作が遅くなるためです。
 *
 */

Scheduler.prototype.view = function() {
    try { 
		this.hide();
	}catch(e){ 
		;
	}
	
    try { 
	this.week_banner_count=new Hash();
	}catch(e){ 
		;
	}

    try { 
		this.reload_preset();
	}catch(e){ 
		;
	}

	try { 
    this.Resize();
    this.CellInit();
    this.banner_create();
    this.BannerFix();
    this.input_today();
	} catch(e) {
//		alert(e);
	}
	this.show();
};

/* スケジューラのテーブルを表示する。
 *
 * viewメソッドに記入したが、テーブルを表示したままのセル変更、バナー描画はブラウザの速度を遅くし、負荷が大きくなるたる、初期状態では非表示にしています。
 * しかし、そのままでは、ユーザが見れないので、このメソッドをよび、テーブルをブラウザに表示します。
 */
Scheduler.prototype.show = function () {
	$(this.table).show();
try {
	$(this.table+"_loading").hide();
} catch(e) {}
};

Scheduler.prototype.hide = function () {
	$(this.table).hide();
try {
	$(this.table + "_loading").hide();
	$(this.table + "_loading").style.width = this.get_table_width() + "px";
	$(this.table + "_loading").style.height = this.get_table_height() + "px";
	$(this.table + "_loading").show();
} catch(e) {}
};

/*
 * セルの大きさ調整
 * 
 * これをしないと、セルの大きさが自由設定になって、バナーの表示がおかしくなる。
 */
Scheduler.prototype.CellInit = function () {
	a=$$('.'+this.cell_class);
	for ( i = 0; i < a.size() ; i++)
	{
		a[i].style.width = this.cell_width + 'px';
		if (Scheduler.type == "month") {
		a[i].style.height = this.cell_height + "px";
	}
	}
};

/*
 * 親コンテナの大きさを得る。
 * 
 * @return {Numeric} 横幅(px)
 */
Scheduler.base_padding_left=40;
Scheduler.prototype.get_table_width = function () {
	return $(this.base).getWidth() - Scheduler.base_padding_left;
};

/*
 * 親コンテナの大きさを得る。
 * 
 * @return {Numeric} 縦幅(px)
 */
Scheduler.prototype.get_table_height = function () {
	return $(this.base).getHeight() - 150;
};

/*
 * 親コンテナの大きさが変わったかを確かめる。
 * 
 * @return {Boolean} 
 * 現在、このインスタンスで持っている分と現在取得した分で違う場合は、
 * true
 */
Scheduler.prototype.resize_check = function () {
	if ( $(this.table).style.width != this.get_table_width() + "px" ) {
		return true;
	}
	if ( $(this.table).style.height != this.get_table_height() + "px" ) {
		return true;
	}
	return false;
};

/*
 * スケジュールテーブルに残留コンテナを削除するガーベージコレクション
 * 
 * 本来は、テーブルを再描画で消えていると思っていたが、なぜか消えない。
 * よって自前で削除スクリプトを持った。
 * 
 * どちらかというとInternet Explorer 8.0用
 */
Scheduler.prototype.reload_preset = function () {
	a = $$('.Banner');
												// バナーを呼び出して
	for (i = 0; i < a.length; i++) {
		a[i].hide();							// 一度引っ込めて
		a[i].remove();							// 全部消す
	}
	
	a = $$('.BannerPadding');
	for (i = 0; i < a.length; i++) {
		a[i].hide();							// 一度引っ込めて
		a[i].remove();							// 全部消す
	}
												// 各セルを呼び出して、
	a = $$("."+this.cell_class);
	for (i = 0; i < Math.floor((this.cal.end.getTime() - this.cal.start.getTime()) / 86400000); i++) {
		try {
			a[i].className = this.cell_class;
		}
		catch(e)
		{
			
		}
	}
};

/* 
 * スケジューラのテーブルサイズを調整する。
 */
Scheduler.prototype.Resize = function()
{
	$(this.table).style.width = this.get_table_width() + "px";
	$(this.table).style.height = this.get_table_height() + "px";
	this.cell_width=Math.floor($(this.table).style.width.replace("px","")*1 / 7)*1;
	this.cell_height=Math.floor($(this.table).style.height.replace("px","")*1 /7);
};
/* 
 * 今日(show_time)のセルを染める。
 * sche_todayを適用する
 */
Scheduler.prototype.input_today = function(){
	try {
		b = $$("."+this.cell_class)[Math.floor((this.cal.makepoint.getTime() - this.cal.start.getTime()) / 86400000)];
														// 該当するセルを探す
		b.className = "schedule_cell sche_today";
	} 
	catch (e) {
		// ここにはshow_timeの該当セルがないので、パス
	}
};

/* 
 * 任意の日のセル染める
 * 
 * @param {String} date 日付 (YYYY/MM/DD HH:MM:SS)
 *
 * パラメータ(date)で指定された日に該当するセルを染める。
 * sche_todayを適用する
 *
 * パラメータdateがshow_timeと同じ場合
 * この処理は行われず、input_todayの結果を優先する。
 */
Scheduler.prototype.input_spec_today = function(date){
	d = new Date(date);
	try {
		b = $$("."+this.cell_class)[Math.floor((d.getTime() - this.cal.start.getTime()) / 86400000)];
		if (b.className != "schedule_cell sche_today") {
			b.className = "schedule_cell sche_today_special";
		}
	} 
	catch (e) {
		// ここにはshow_timeの該当セルがないので、パス
	}
};

/* バナーの素(moto)データを作成し、バナー作成メソッドを呼び出す。
 *
 * インスタンスが保有するbannersのハッシュをすべて展開し、バナーを配置するための素データを作成するのが主な役割。
 * バナーの描画、他の行事との重なり調整はここではなく、BannerCreateとCellPaddingを参照
 */
Scheduler.prototype.banner_create = function(){
	var banners = this.banners;
	me = this;												// この後、thisのさす場所がかわるので、ポインタを退避
	banners.each(function(pair){
		banner = pair.value;								// 取得したバナー情報を退避
		me.banner_create_sub(banner, me);
	});
};

/* バナーの素(moto)データを作成し、バナー作成メソッドを呼び出す。
 *
 * インスタンスが保有するbannersのハッシュをすべて展開し、バナーを配置するための素データを作成するのが主な役割。
 * バナーの描画、他の行事との重なり調整はここではなく、BannerCreateとCellPaddingを参照
 */
Scheduler.prototype.banner_create_sub = function(banner,me){							// ハッシュ展開
		offset = 0;											// 何段目を処理中か。ただし、値は-1する。
		for (offset = 0; offset * 7 <= (me.cal.end.getTime() - me.cal.start.getTime()) / (24 * 60 * 60 * 1000); offset = offset + 1) {
															// 週ごとにバナーを生成する
			if ( !(me.Target(banner,offset)) ) { continue; }	// この週にないバナーは生成しない
						
			start = (banner.start_date.getTime() - me.cal.start.getTime()) / (24 * 60 * 60 * 1000);
															// バナーの始点(何個目のセルか)を求める。
			end = Math.floor((banner.end_date.getTime() - me.cal.start.getTime()) / (24 * 60 * 60 * 1000));
															// バナーの終点(何個目のセルか)を求める。
			
				before_cut=0;
			if (start < offset * 7) {
				start = offset * 7;							// バナーが週の始点よりも前の場合は、週の始点にする。
				before_cut=1;
			}
			
				after_cut=0;
			if (end > offset * 7 + 6) {
				end = offset * 7 + 6;						// バナーが週の終点よりも後の場合は、週の終点とする。
				after_cut=1;
			}
			
			me.BannerCreate(banner.run_id, Math.floor(start / 7), start - offset * 7, end - start + 1, banner.name,before_cut,after_cut,banner);
															// バナー生成本体をコール			
			me.CellPadding(start,end);
															// 他の行事と重ならないように配置を調整
			
		}
		
};

/* 
 * バナーを生成すべきかを判定する。
 * 
 * banner_createが呼び出す。
 * @param  {Banner} banner 判定対象のバナー
 * @param  {Numeric} offset 現在判定対象の行数 (第(offset+1)週目)
 * @return {Boolean} 生成の必要がない場合は、false、生成の必要がある場合は、true返す。
 */
Scheduler.prototype.Target = function(banner,offset){

	if ((banner.start_date.getTime() - this.cal.start.getTime()) / (24 * 60 * 60 * 1000) > offset * 7 + 6) {
		return false;					// バナーの始点が週の終点よりも後の場合は、生成しない
	}
	
	if (Math.floor((banner.end_date.getTime() - this.cal.start.getTime()) / (24 * 60 * 60 * 1000)) < offset * 7) {
		return false;					// バナーの終点が週の始点よりも前にある場合は、生成しない
	}
	return true;
};

/* 
 * バナーが他の行事と重ならないのように、空間を空ける処理ための素データを作成する。
 * 実際に空ける処理をしているのは BannerFix
 * 
 * @param {Numeric} start 空白を開ける必要があるセル(開始日) ((start+1)個目)
 * @param {Numeric} end 空白を開ける必要があるセル(終了日) ((end+1)個目)
 */
Scheduler.prototype.CellPadding = function(start,end){
	h = 0;									// 作業バッファー
	cells = $$('.'+this.cell_in_cell_name); 					//セルを取得する。 ここは'.content_elem'
	
	for (i = start; i <= end; i++) {		// 各セルにあるバナー数を確認
		try {
			if (this.week_banner_count.get("c_" + i) == undefined) {
				this.week_banner_count.set("c_" + i, 0);
			}
		}
		catch(e)
		{
			this.week_banner_count.set("c_" + i, 0);
		}
		if (h < this.week_banner_count.get("c_" + i) * 1 + 1) {
			h = this.week_banner_count.get("c_" + i) * 1 + 1;
		}
	}
											// もっとも大きい値でパディングする。なお、本当のパディングはBannerFix
	for (i = start; i <= end; i++) {
		this.week_banner_count.set("c_" + i, h);
	}
};

/* 
 * バナーをスケジュールテーブル上に描画する。
 * 
 * バナーID、議事記事情報、座標、長さを与える
 *
 * @param {String} id バナー名
 * @param {Numeric} row 縦に(n+1)個目
 * @param {Numeric} col 横に(n+1)個目
 * @param {Numeric} width 長さ
 * @param {String} article 記事情報
 * @param {Boolean} before_cut 開始日にすでに達している記事なら true
 * @param {Boolean} after_cut  終了日に達していない記事なら true
 *
 * バナーはクリックされると、グローバルのbanner_onclickをコールします。
 * 別途banner_onclickを定義してください。
 * 引数は(BannerObject, HTMLDivElemnt)でわたってきます。
 */
Scheduler.prototype.BannerCreate = function(id,row,col,width,article,before_cut,after_cut,banner){
	a = document.createElement('div');					// バナーの生成開始
	a.id=id+"_"+row;									// IDを生成 、 run_id + _ + 行 で生成する。
	a.name=id;											// でも、名前はそのまま
	a.className="Banner Banner_"+id+"";					// schedule.css の .Banner参照
	c=row*7+col;										// cはセルを意味する。セルはrow*7 + colで算出できる
	if (before_cut) { a.className += " BannerBeforeCut";}
	if (after_cut) { a.className += " BannerAfterCut";}
	try {
		if (this.week_banner_count.get("c_" + c) == undefined) // 最初の段階では、パディングハッシュが未知数なので初期化
		{
			this.week_banner_count.set("c_" + c, 0);
		}
	}
	catch(e)
	{
			this.week_banner_count.set("c_" + c, 0);
	}

	a.style.top=Scheduler.top_margin + (this.cell_height+3) * row*1 + Scheduler.line_margin  * this.week_banner_count.get("c_"+c) + "px";
														// 上からの位置
	a.style.left=Scheduler.left_margin + (this.cell_width+4)*col+"px";
														// 左からの位置
	a.style.width=(this.cell_width+2.0)*width+"px";
														// 長さ
	a.style.position = "absolute";
														// 自由配置
	a.innerHTML=article;
														// 内容を書いて
	a.obj = a;
		
	a.banner = banner; 
	
	a.onclick = function() { try { if ( this.banner.run_id == "") { new_banner_onclick(this,this.obj,this.banner);} else { banner_onclick(this,this.obj,this.banner); } } catch(e){  ; } };
														// OnClick対

	// IEはraduis未対応なので、画像で強制的に再現する。IEが対応したら、このロジックは消してください。
	this.BannerDecorationForIE(a,before_cut,after_cut);

	// テーブルに追加
	$(this.table).appendChild(a);

	try {
		new Draggable(id+"_"+row);
	} catch(e){alert(e);}

};

/* 
 * バナーの丸角 (IE用)
 */
Scheduler.prototype.BannerDecorationForIE = function (a,before_cut,after_cut)
{
	if(Prototype.Browser.IE){
		b = document.createElement('div');
		b.style.position = "absolute";
		b.style.left = -1 + 'px';
		b.style.top = -7 + 'px';
		if (before_cut==0 || (before_cut+after_cut==0)) {
			b.innerHTML = "<img src='images/blt.gif'>";
			
			d = document.createElement('div');
			d.innerHTML = "<img src='images/blb.gif'>";
			d.style.position = "absolute";
			d.style.left = 0 + 'px';
			d.style.top = 1.25 + 'em';
			b.appendChild(d);
		}

		if (after_cut==0 || (before_cut + after_cut == 0)) {
			c = document.createElement('div');
			c.innerHTML = "<img src='images/brt.gif'>";
			c.style.position = "absolute";
			c.style.left = a.style.width.replace('px', '') * 1 - 3 + 'px';
			c.style.top = 0 + 'px';
			b.appendChild(c);
			
			
			e = document.createElement('div');
			e.innerHTML = "<img src='images/brb.gif'>";
			e.style.position = "absolute";
			e.style.left = a.style.width.replace('px', '') * 1 - 3 + 'px';
			e.style.top = 1.25 + 'em';
			b.appendChild(e);
		}
		a.appendChild(b);
	}
};

/* バナーの場所調整をする本体
 * 
 * CellPadingが実行されていることを前提とする。
 * パディングはスタイルシートではなくて、記事セルに<div>を書き加えている。
 */
Scheduler.prototype.BannerFix = function () {
	me = this;
	this.week_banner_count.each ( function(par){
		i = par.key.replace('c_', '') * 1;
		//'.schedule_cell'
		for (c = 0; c < par.value; c++)  // パディングし忘れていました。 2009/11/20
		{
			$$("."+me.cell_class)[i].getElementsByTagName('td')[0].innerHTML = "<div class='BannerPadding'>　</div>" +
			$$("."+me.cell_class)[i].getElementsByTagName('td')[0].innerHTML;
		}
	}
	);
};

////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
 * ここからは、コーナーのカレンダー部分　と　スケジュールコーナ　の　共用部分
 */

/* カレンダー情報
 * 
 * 現在地と始点、終点、show_timeを保存する。
 * なお、始点と終点は
 * 始点　･･･　現在地の月で初日からもっとも近い月曜日
 * 終点　･･･　現在地の月で最終日からもっとも近い土曜日
 * を自動で計算する。
 *
 * @param {String} makepoints カレンダー作成時の基準点
 * @param {String} show_time 今日とする日 (show_time)
 */
var Calender = function (makepoints,show_time){
	this.makepoint = new Date(makepoints);
	this.start = new Date(makepoints);
	this.end = new Date(makepoints);
	
	this.today = new Date(show_time);
	
	this.start.setDate( 1 );
	this.start.setDate( 1 - this.start.getDay());
	
	this.end.setDate( 1 );
	this.end.setMonth(this.end.getMonth()+1);
	this.end.setDate( 0 );
	this.end.setDate( this.end.getDate() + (6-this.end.getDay()) );	
};

/* 
 * 今日(show_time)のセルを染める。
 * sche_todayを適用する
 */
Calender.prototype.input_today = function(a){
	try {
		b = a.getElementsByTagName('td')[Math.floor((this.today.getTime() - this.start.getTime()) / 86400000)];
		// 該当するセルを探す
		b.className = "cal_today";
	} 
	catch (e) {
		// ここにはshow_timeの該当セルがないので、パス
	}
};

/* 前月を返す 
* @return {Date}
*
*/
Calender.prototype.getProvMonthDate = function(){
	a = new Date(this.makepoint);
	a.setMonth(a.getMonth()-1);
	return a;
};

/* 次月を返す 
* @return {Date}
*/
Calender.prototype.getNextMonthDate = function(){
	a = new Date(this.makepoint);
	a.setMonth(a.getMonth()+1);
	return a;
};

/* 現在表示している年を返す 
* @return {String}
*/
Calender.prototype.getYear = function(){
	return this.makepoint.getFullYear();
};

/* 現在表示している月を返す 
* @return {String}
*/
Calender.prototype.getMonth = function() {
	return this.makepoint.getMonth()+1;
};

/* カレンダを生成する。
*
* @return {HTMLTBodyElement} カレンダテーブル (TBODY部)
*
* 戻り値をappendChildなどで、他のタグの子要素にし、表示する。 
*/
Calender.prototype.put_out_calendar = function (){
	block = document.createElement('tbody');				// TBODY要素を生成
	for ( tmp = new Date(this.start);						// カレンダーを日毎生成
			tmp.getTime() <= this.end.getTime();
			tmp.setDate(tmp.getDate()+1)) {

		if ( tmp.getDay() == 0) { 
			p = document.createElement('tr');				// 日曜日だったら、列を変える
		}
		c = document.createElement('td');					// セルの生成
		c.style.textAlign="right";							// 右によせたほうが見やすいよね。
		c.innerHTML = tmp.getDate();						// 日付を表示
		p.appendChild(c);									// 列に追加

		if ( tmp.getDay() == 6) { 							// 土曜日に達したら、列を閉じる
			block.appendChild(p);
		}
	}

	return block;
};

	function cal_view(obj,name,show_div,year_div){
		a=obj.put_out_calendar();
		a.id=name;
		$(show_div).appendChild(a);
		$(year_div).innerHTML = obj.getYear() + "年" + obj.getMonth() + "月";

		$('prov').getElementsByTagName('a')[0].onclick = function()
		{
			$(a.id).remove();
			cal_view(
				new Calender(
					obj.getProvMonthDate(),
					obj.today
					),name,show_div,year_div
				);
		};
		$('next').getElementsByTagName('a')[0].onclick = function()
		{
			$(a.id).remove();
			cal_view(
				new Calender(
					obj.getNextMonthDate(),
					obj.today
					),name,show_div,year_div
				);
		};

		obj.input_today(a);
	}
