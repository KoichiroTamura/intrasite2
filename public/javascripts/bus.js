/*-----------------------------------------------------------------*
 *-----------------------------------------------------------------*
 【ファイル概要】時刻表表示操作
 【目的役割】時刻表の表示に関するロジックを定義する。
 *-----------------------------------------------------------------*
 *-----------------------------------------------------------------*/

/*-----------------------------------------------------------------*
 【機能概要】時刻表背景表示
 【入力引数】メッセージ番号
 【戻り値】正常：true　例外：false
 【目的役割】時刻表の背景画像を表示する。
 *-----------------------------------------------------------------*/
function reTimetableBgDisp(x)
{
	var		obj;
	var		str_img;
	var		num;
	
	obj = document.getElementById("timetableBgDisp" + x);
	
	if ((null != obj)) {
		if (1 == (x % 2)) {			// 奇数列
			num = 1;
		}
		else{						// 偶数列
			num = 2;
		}
		
		str_img = 'transparent url("/images/t_TimetableInfoFrame0' + num + '.gif") repeat-x scroll center center;'
		obj.style.background = str_img;
	}
	else{
		return false;
	}
	
	return true;
}

/*-----------------------------------------------------------------*
 【機能概要】文字列分割
 【入力引数】分割する文字列／置き換える対象文字／置き換える文字
 【戻り値】分割した文字列
 【目的役割】時刻表の背景画像を表示する。
 *-----------------------------------------------------------------*/
function timeReplace(str, target, text)
{
	var		original_str;						// 置き換える前の文字列
	var		rep_str;							// 置き換えた後の文字列
	var		count;
	
	original_str = str;
	rep_str = original_str.replace(target, text);
	
	count = 1;
	while (original_str != rep_str) {			// 全て置き換えるまでループ
		original_str = rep_str;
		rep_str = original_str.replace(target, text);
		
		count++;
		if (count > 10000) {					// 無限ループプロテクト：１万ループ
			break;
		}
	}
	
	return rep_str;
}