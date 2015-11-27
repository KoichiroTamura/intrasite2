/*-----------------------------------------------------------------*
 *-----------------------------------------------------------------*
 【ファイル概要】メニュー操作
 【目的役割】メニュー操作に関するロジックを定義する。
 *-----------------------------------------------------------------*
 *-----------------------------------------------------------------*/

menuClassFlg = new Array(12);		/* 開閉フラグ 12個（予備3個） */
var		arraySize;					/* 配列要素数 */
var		cookieName;					/* 取得するクッキー・データ名 */
var		i;

arraySize = menuClassFlg.length;
cookieName = "menuClassFlg=";

/* 「開：1」にて初期化 */
for (i = 0; menuClassFlg.length > i; i++) {
	menuClassFlg[i] = 1 * 1;
}

/* クッキーの取得 */
getMenuCookie(cookieName);


/*-----------------------------------------------------------------*
 【機能概要】メニュー開閉再描画処理
 【入力引数】メニュークラス番号
 【戻り値】無し
 【目的役割】メニュークラス配下のメニューの再描画を行う。
 *-----------------------------------------------------------------*/
function reDisp()
{
	/* 表示更新 */
	for (i = 0; arraySize > i; i++) {
		if (1 == menuClassFlg[i]) {
			menuOpen(i);
		}
		else{
			menuClose(i);
		}
	}
}

/*-----------------------------------------------------------------*
 【機能概要】メニュー開閉制御処理
 【入力引数】メニュークラス番号
 【戻り値】無し
 【目的役割】メニュークラス配下のメニューの開閉制御を行う。
 *-----------------------------------------------------------------*/
function menuOperation(x)
{
	/* 表示更新 */
	if (0 == menuClassFlg[x]) {
		menuOpen(x);
	}
	else{
		menuClose(x);
	}
	
	/* クッキー更新 */
	setMenuCookie(cookieName);
}

/*-----------------------------------------------------------------*
 【機能概要】メニュー開処理
 【入力引数】メニュークラス番号
 【戻り値】正常：true　例外：false
 【目的役割】メニュークラス配下のメニューを開く処理を行う。
 *-----------------------------------------------------------------*/
function menuOpen(x)
{
	var		obj;
	var		img_obj;
	var		str_img;
	
	obj = document.getElementById("menuClassNo" + x);
	img_obj = document.getElementById("cate_num" + x);
	
	if ((null != obj) && (null != img_obj)) {
		obj.style.display = "block";
		obj.style.visibility = "visible";
		
		str_img = '#ffffff url("/images/MenuOpen' + (x + 1) + '.gif") no-repeat';
		img_obj.style.background = str_img;
	}
	else{
		return false;
	}
	
	menuClassFlg[x] = 1;	/* 開 */
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】メニュー閉処理
 【入力引数】メニュークラス番号
 【戻り値】正常：true　例外：false
 【目的役割】メニュークラス配下のメニューを閉じる処理を行う。
 *-----------------------------------------------------------------*/
function menuClose(x)
{
	var		obj;
	var		img_obj;
	var		str_img;
	
	obj = document.getElementById("menuClassNo" + x);
	img_obj = document.getElementById("cate_num" + x);
	
	if(null != obj){
		obj.style.display = "none";
		obj.style.visibility = "hidden";
		
		str_img = '#ffffff url("/images/MenuClose' + (x + 1) + '.gif") no-repeat';
		img_obj.style.background = str_img;
	}
	else{
		return false;
	}
	
	menuClassFlg[x] = 0;	/* 閉 */
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】クッキーの取得
 【入力引数】クッキー・データ名
 【戻り値】正常：true　例外：false
 【目的役割】クッキーから、
             メニュークラス配下のメニューの開閉値を取得する。
 *-----------------------------------------------------------------*/
function getMenuCookie(dataName)
{
	var		menuCookie;				/* クッキー・データ保存用 */
	var		dataPoint = 0;			/* データ開始位置 */
	
	/* 読み込み（末尾に「;」を追加） */
	menuCookie = document.cookie + ";";
	dataPoint = menuCookie.indexOf(dataName, 0);
	
	/* データが存在する */
	if (-1 != dataPoint) {
		var		elemPoint = 0;		/* 要素開始位置 */
		var		dataLength;			/* データ文字列長 */
		var		data;
		
		/* データ抽出 */
		dataLength = menuCookie.length;
		menuCookie = menuCookie.substring(dataPoint, dataLength);
		
		/* 要素抽出 */
		elemPoint = menuCookie.indexOf("=", 0);
		elemPoint += 1;
		dataLength = menuCookie.length;
		menuCookie = menuCookie.substring(elemPoint, dataLength);
		
		/* 要素を切り分け，開閉フラグ変数に格納する． */
		for (i = 0; menuClassFlg.length > i; i++) {
			/* フラグ値として正しければ格納 */
			data = menuCookie.substr(0, 1) * 1;
			if (1 == data || 0 == data) {
				menuClassFlg[i] = data;
			}
			else{
				return false;
			}
			
			/* 残りの要素のみを抽出 */
			elemPoint = menuCookie.indexOf(",", 0);
			if (0 > elemPoint) {
				return false;
			}
			elemPoint += 1;
			dataLength = menuCookie.length;
			menuCookie = menuCookie.substring(elemPoint, dataLength);
		}
	}
	/* データが存在しない */
	else{
		return false;
	}
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】クッキーの保存
 【入力引数】クッキー・データ名
 【戻り値】正常：true　例外：false
 【目的役割】クッキーに、
             メニュークラス配下のメニューの開閉値を保存する。
 *-----------------------------------------------------------------*/
function setMenuCookie(dataName)
{
	xDay = new Date;			/* 日付 */
	var		menuCookie;			/* クッキー・データ保存用 */
	var		i;
	
	/* 保存データ文字列の生成 */
	menuCookie = dataName;
	for (i = 0; arraySize > i; i++) {
		menuCookie += escape(menuClassFlg[i]);
		
		if (i != (arraySize - 1)) {
			menuCookie += ",";
		}
	}
	menuCookie += ";";
	
	/* 保存期間１年に設定 */
	xDay.setFullYear(xDay.getFullYear() + 1);
	xDay = xDay.toGMTString();
	
	menuCookie += ("path=/;");
	menuCookie += ("expires=" + xDay + ";");
	
	/* 書き込み */
	document.cookie = menuCookie;
	
	return true;
}
