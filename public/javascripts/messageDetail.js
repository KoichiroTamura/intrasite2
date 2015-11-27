/*-----------------------------------------------------------------*
 *-----------------------------------------------------------------*
 【ファイル概要】メッセージ詳細表示
 【目的役割】メッセージ詳細表示に関するロジックを定義する。
 *-----------------------------------------------------------------*
 *-----------------------------------------------------------------*/

/*-----------------------------------------------------------------*
 【機能概要】高さ算出
 【入力引数】オブジェクト名
 【戻り値】高さ（ピクセル）
 【目的役割】引数にて受け取る［オブジェクト名_○］のオブジェクトの
             高さを全て加算し、呼出元へ返す。
 *-----------------------------------------------------------------*/
function calHeight(id)
{
	var		height;
	var		obj;
	var		count;
	
	height = 0;
	count = 1;
	obj = document.getElementById(id + "_" + count);
	
	while (null != obj) {
		height += obj.offsetHeight;
		
		count++;
		obj = document.getElementById(id + "_" + count);	// 次のチェックボックス
		
		if (count > 10000) {								// 無限ループプロテクト：１万ループ
			break;
		}
	}
	
	return height;
}

/*-----------------------------------------------------------------*
 【機能概要】幅算出
 【入力引数】オブジェクト名
 【戻り値】幅（ピクセル）
 【目的役割】引数にて受け取る［オブジェクト名_○］のオブジェクトの
             幅を全て加算し、呼出元へ返す。
 *-----------------------------------------------------------------*/
function calWidth(id)
{
	var		width;
	var		obj;
	var		count;
	
	width = 0;
	count = 1;
	obj = document.getElementById(id + "_" + count);
	
	while (null != obj) {
		width += obj.offsetWidth;
		
		count++;
		obj = document.getElementById(id + "_" + count);	// 次のチェックボックス
		
		if (count > 10000) {								// 無限ループプロテクト：１万ループ
			break;
		}
	}
	
	return width;
}

/*-----------------------------------------------------------------*
 【機能概要】ボックス高さ操作
 【入力引数】高さ基準／調整ボックス
 【戻り値】正常：true　例外：false
 【目的役割】調整ボックスの高さを、高さ基準に合わせる。
             ボックスの絶対配置等により、ＣＳＳのみでは、
             基準となるボックスの高さに合わせることが出来ない時のみ使用する。
 *-----------------------------------------------------------------*/
function heightAdjust(height, edit_id)
{
	var		edit_obj;
	
	edit_obj = document.getElementById(edit_id);
	
	if (null != edit_obj) {
		edit_obj.style.height = (height + "px");
	}
	else{
		return false;
	}
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】ボックス幅操作
 【入力引数】幅基準／現在の幅／調整ボックス
 【戻り値】正常：true　例外：false
 【目的役割】調整ボックスの現在の幅が幅基準値未満ならば、
             幅基準に調整ボックスの幅を合わせる。
 *-----------------------------------------------------------------*/
function widthJdgAdjust(jdg_width, width, edit_id)
{
	var		edit_obj;
	
	if (jdg_width > width) {
		edit_obj = document.getElementById(edit_id);
		
		if (null != edit_obj) {
			edit_obj.style.width = (jdg_width + "px");
		}
		else{
			return false;
		}
	}
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】ボックス位置操作
 【入力引数】位置基準／調整ボックス
 【戻り値】正常：true　例外：false
 【目的役割】調整ボックスの位置を、位置基準に合わせる。
             ボックスの高さ可変等により、ＣＳＳのみでは、
             基準となる位置に合わせることが出来ない時のみ使用する。
 *-----------------------------------------------------------------*/
function positionAdjust(height, edit_id)
{
	var		edit_obj;
	
	edit_obj = document.getElementById(edit_id);
	
	if (null != edit_obj) {
		edit_obj.style.top = (height + "px");
	}
	else{
		return false;
	}
	
	return true;
}
